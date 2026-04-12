# Extract content from Proyecto TEtera.docx
$basePath = "C:\Users\eslim\ANDA QUE ANDA"
$docxPath = Join-Path $basePath "Proyecto TEtera.docx"
$tempPath = Join-Path $basePath "tetera_temp.docx"
$outputPath = Join-Path $basePath "tetera_content_order.txt"

# Check if file exists
if (-not (Test-Path $docxPath)) {
    Write-Host "File not found: $docxPath"
    exit 1
}

# Copy to temp to avoid locking issues
Copy-Item $docxPath $tempPath -Force

try {
    # Open as ZIP
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $tempPath).Path)
    
    # Get document.xml and relationships
    $docEntry = $zip.Entries | Where-Object { $_.FullName -eq "word/document.xml" }
    $relsEntry = $zip.Entries | Where-Object { $_.FullName -eq "word/_rels/document.xml.rels" }
    
    if (-not $docEntry -or -not $relsEntry) {
        Write-Host "Could not find document.xml or relationships"
        $zip.Dispose()
        exit 1
    }
    
    $docStream = $docEntry.Open()
    $reader = New-Object System.IO.StreamReader($docStream)
    $docXml = $reader.ReadToEnd()
    $reader.Close()
    $docStream.Close()
    
    $relsStream = $relsEntry.Open()
    $reader = New-Object System.IO.StreamReader($relsStream)
    $relsXml = $reader.ReadToEnd()
    $reader.Close()
    $relsStream.Close()
    
    # Extract images from word/media folder
    $assetsPath = Join-Path $basePath "anda-que-anda-static\assets\projects\tetera"
    if (-not (Test-Path $assetsPath)) {
        New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null
    }
    
    $imageEntries = $zip.Entries | Where-Object { $_.FullName -like "word/media/*" }
    $extractedImages = @{}
    foreach ($imgEntry in $imageEntries) {
        $imgName = [System.IO.Path]::GetFileName($imgEntry.FullName)
        $imgPath = Join-Path $assetsPath $imgName
        $imgStream = $imgEntry.Open()
        $fileStream = [System.IO.File]::Create($imgPath)
        $imgStream.CopyTo($fileStream)
        $fileStream.Close()
        $imgStream.Close()
        $extractedImages[$imgName] = $imgPath
        Write-Host "Extracted image: $imgName"
    }
    
    $zip.Dispose()
    
    # Parse XML
    $xmlDoc = New-Object System.Xml.XmlDocument
    $xmlDoc.LoadXml($docXml)
    $relsDoc = New-Object System.Xml.XmlDocument
    $relsDoc.LoadXml($relsXml)
    
    # Map image relationships
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
    
    # Extract content in order
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
            
            # Get all images in this paragraph
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
            
            # Get inline drawings (alternative way images might be embedded)
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
    
    # Output to file
    $output = @()
    foreach ($item in $content) {
        if ($item.Type -eq "IMAGE") {
            $output += "IMAGE: $($item.Value)"
        } else {
            $output += "TEXT: $($item.Value)"
        }
    }
    
    $output | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Host "Extracted $($content.Count) items (images and text blocks)"
    Write-Host "Output saved to: $outputPath"
    Write-Host "Extracted $($extractedImages.Count) image files to: $assetsPath"
    
} finally {
    if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
    }
}
