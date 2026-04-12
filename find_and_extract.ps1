# Find and extract document
$folder = "C:\Users\eslim\ANDA QUE ANDA"
$allFiles = [System.IO.Directory]::GetFiles($folder, "*.docx")
$docxPath = $allFiles | Where-Object {$_ -match "libreria" -or $_ -match "Libreria"} | Select-Object -First 1

if ($docxPath -and (Test-Path $docxPath)) {
    Write-Host "Found: $docxPath"
    
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
                
                foreach ($node in $body.ChildNodes) {
                    if ($node.LocalName -eq "p") {
                        $para = $node
                        
                        # Get all images in this paragraph (check both blip and inline)
                        $drawings = $para.SelectNodes(".//a:blip", $nsW)
                        foreach ($drawing in $drawings) {
                            $embed = $drawing.SelectSingleNode("./r:embed", $nsW)
                            if ($embed) {
                                $rId = $embed.GetAttribute("r:embed")
                                if ($imageMap.ContainsKey($rId)) {
                                    $content += @{Type="IMAGE"; Value=$imageMap[$rId]}
                                }
                            }
                        }
                        
                        # Get inline drawings
                        $inlines = $para.SelectNodes(".//wp:inline", $nsW)
                        foreach ($inline in $inlines) {
                            $blip = $inline.SelectSingleNode(".//a:blip", $nsW)
                            if ($blip) {
                                $embed = $blip.SelectSingleNode("./r:embed", $nsW)
                                if ($embed) {
                                    $rId = $embed.GetAttribute("r:embed")
                                    if ($imageMap.ContainsKey($rId)) {
                                        $content += @{Type="IMAGE"; Value=$imageMap[$rId]}
                                    }
                                }
                            }
                        }
                        
                        # Get text
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
                
                $output | Out-File "libreria_EXACT_order_final.txt" -Encoding UTF8
                Write-Host "SUCCESS: Extracted $($content.Count) items"
                Write-Host "Images: $(($content | Where-Object {$_.Type -eq 'IMAGE'}).Count)"
                Write-Host "Text blocks: $(($content | Where-Object {$_.Type -eq 'TEXT'}).Count)"
            }
        }
        
        $zip.Dispose()
    } catch {
        Write-Host "Error: $_"
        Write-Host $_.Exception.Message
        exit 1
    }
} else {
    Write-Host "Document not found"
    exit 1
}
