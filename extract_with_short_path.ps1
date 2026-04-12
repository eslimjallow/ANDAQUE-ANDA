# Find file using direct file system access
$folder = "C:\Users\eslim\ANDA QUE ANDA"
$allFiles = [System.IO.Directory]::GetFiles($folder, "*.docx")
$docxPath = $allFiles | Where-Object {$_ -match "libreria" -or $_ -match "Libreria" -or $_ -match "librer"} | Select-Object -First 1

if (-not $docxPath) {
    # Try to get the first file that's not TeHospiCan
    $docxPath = $allFiles | Where-Object {$_ -notmatch "TeHospiCan"} | Select-Object -First 1
}

if ($docxPath -and [System.IO.File]::Exists($docxPath)) {
    Write-Host "Found: $docxPath"
} else {
    Write-Host "File not found"
    exit 1
}

# Copy file first to avoid lock issues
$tempPath = "C:\Users\eslim\ANDA QUE ANDA\libreria_temp.docx"
try {
    [System.IO.File]::Copy($docxPath, $tempPath, $true)
    Write-Host "Copied to temp file"
    $docxPath = $tempPath
} catch {
    Write-Host "Could not copy file (may be locked): $_"
    Write-Host "Please close the document and try again, or I'll try to read it directly"
}

if (Test-Path $docxPath) {
    Write-Host "Found file, extracting..."
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($docxPath)
        
        # Get document.xml
        $docEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
        if ($docEntry) {
            $docStream = $docEntry.Open()
            $docReader = New-Object System.IO.StreamReader($docStream, [System.Text.Encoding]::UTF8)
            $docXml = $docReader.ReadToEnd()
            $docReader.Close()
            $docStream.Close()
            
            # Get relationships
            $relsEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/_rels/document.xml.rels' }
            if ($relsEntry) {
                $relsStream = $relsEntry.Open()
                $relsReader = New-Object System.IO.StreamReader($relsStream, [System.Text.Encoding]::UTF8)
                $relsXml = $relsReader.ReadToEnd()
                $relsReader.Close()
                $relsStream.Close()
                
                # Parse XML
                $xmlDoc = New-Object System.Xml.XmlDocument
                $xmlDoc.LoadXml($docXml)
                
                $relsDoc = New-Object System.Xml.XmlDocument
                $relsDoc.LoadXml($relsXml)
                
                # Create image mapping
                $imageMap = @{}
                $nsMgr = New-Object System.Xml.XmlNamespaceManager($relsDoc.NameTable)
                $nsMgr.AddNamespace("r", "http://schemas.openxmlformats.org/package/2006/relationships")
                
                $rels = $relsDoc.SelectNodes("//r:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image']", $nsMgr)
                foreach ($rel in $rels) {
                    $rId = $rel.GetAttribute("Id")
                    $target = $rel.GetAttribute("Target")
                    $filename = [System.IO.Path]::GetFileName($target)
                    $imageMap[$rId] = $filename
                }
                
                # Parse document in EXACT order
                $nsW = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
                $nsW.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
                $nsW.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
                $nsW.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
                $nsW.AddNamespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")
                
                $content = @()
                $body = $xmlDoc.SelectSingleNode("//w:body", $nsW)
                
                # First, find all image references - try different methods
                $allEmbeds = $xmlDoc.SelectNodes("//r:embed", $nsW)
                Write-Host "Found $($allEmbeds.Count) r:embed elements"
                
                # Try without namespace
                $allEmbeds2 = $xmlDoc.SelectNodes("//*[local-name()='embed']")
                Write-Host "Found $($allEmbeds2.Count) embed elements (no namespace)"
                
                # Try looking for any r: relationship references
                $allRels = $xmlDoc.SelectNodes("//*[starts-with(local-name(), 'r:')]")
                Write-Host "Found $($allRels.Count) r:* elements"
                
                # Try looking for drawing elements
                $allDrawings = $xmlDoc.SelectNodes("//*[local-name()='drawing']")
                Write-Host "Found $($allDrawings.Count) drawing elements"
                
                # Search for relationship IDs in the XML as attributes
                # Images are referenced by rId6, rId7, etc. in the imageMap
                # Let's search for these IDs in any attribute
                foreach ($rId in $imageMap.Keys) {
                    $nodesWithRId = $xmlDoc.SelectNodes("//*[@*[contains(., '$rId')]]")
                    if ($nodesWithRId.Count -gt 0) {
                        Write-Host "Found $rId referenced in $($nodesWithRId.Count) nodes"
                        # Get the first one to see structure
                        $firstNode = $nodesWithRId[0]
                        Write-Host "  Node: $($firstNode.LocalName), XML: $($firstNode.OuterXml.Substring(0, [Math]::Min(300, $firstNode.OuterXml.Length)))"
                        break
                    }
                }
                
                foreach ($node in $body.ChildNodes) {
                    if ($node.LocalName -eq "p") {
                        $para = $node
                        
                        # Check if this paragraph contains an image
                        # Look for a:blip elements with r:embed attribute
                        $blips = $para.SelectNodes(".//a:blip", $nsW)
                        foreach ($blip in $blips) {
                            # Get r:embed attribute - need to use the full namespace URI
                            $rId = $blip.GetAttribute("embed", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
                            if (-not $rId) {
                                # Try without namespace
                                $rId = $blip.GetAttribute("r:embed")
                            }
                            if (-not $rId) {
                                # Try as local name
                                $rIdAttr = $blip.Attributes | Where-Object {$_.LocalName -eq "embed" -or $_.Name -like "*embed*"}
                                if ($rIdAttr) {
                                    $rId = $rIdAttr.Value
                                }
                            }
                            
                            if ($rId -and $imageMap.ContainsKey($rId)) {
                                $content += @{Type="IMAGE"; Value=$imageMap[$rId]}
                            }
                        }
                        
                        # Get text (only if no image or if there's also text)
                        $textNodes = $para.SelectNodes(".//w:t", $nsW)
                        $text = ""
                        foreach ($t in $textNodes) {
                            $text += $t.InnerText
                        }
                        
                        if ($text.Trim() -ne "") {
                            $content += @{Type="TEXT"; Value=$text.Trim()}
                        }
                    }
                }
                
                # Output EXACT order
                $outputPath = "C:\Users\eslim\ANDA QUE ANDA\libreria_EXACT_order_final.txt"
                $output = ""
                $index = 1
                foreach ($item in $content) {
                    if ($item.Type -eq "IMAGE") {
                        $output += "[$index] IMAGE: $($item.Value)`n`n"
                    } else {
                        $output += "[$index] TEXT: $($item.Value)`n`n"
                    }
                    $index++
                }
                
                $output | Out-File $outputPath -Encoding UTF8
                Write-Host "SUCCESS: Extracted $($content.Count) items"
                Write-Host "Images: $(($content | Where-Object {$_.Type -eq 'IMAGE'}).Count)"
                Write-Host "Text blocks: $(($content | Where-Object {$_.Type -eq 'TEXT'}).Count)"
                Write-Host "Output saved to: $outputPath"
                
                # Also output image map for debugging
                Write-Host "`nImage map has $($imageMap.Count) entries:"
                $imageMap.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key) -> $($_.Value)" }
            }
        }
        
        $zip.Dispose()
        
        # Clean up temp file
        if ($tempPath -and (Test-Path $tempPath)) {
            Remove-Item $tempPath -Force
        }
    } catch {
        Write-Host "Error: $_"
        Write-Host $_.Exception.Message
        # Clean up temp file
        if ($tempPath -and (Test-Path $tempPath)) {
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
        exit 1
    }
} else {
    Write-Host "File not found: $docxPath"
    exit 1
}
