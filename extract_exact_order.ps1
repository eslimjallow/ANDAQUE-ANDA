# Extract EXACT order from Word document
$folder = "C:\Users\eslim\ANDA QUE ANDA"
$files = Get-ChildItem $folder -File -Filter "*.docx"
$docxFile = $files | Where-Object {$_.Name -like '*libreria*' -or $_.Name -like '*Libreria*'} | Select-Object -First 1

if (-not $docxFile) {
    Write-Error "Document not found"
    exit 1
}

$docxPath = $docxFile.FullName
Write-Host "Found document: $docxPath"

Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($docxPath)

# Get document.xml
$docEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
$docStream = $docEntry.Open()
$docReader = New-Object System.IO.StreamReader($docStream, [System.Text.Encoding]::UTF8)
$docXml = $docReader.ReadToEnd()
$docReader.Close()
$docStream.Close()

# Get relationships
$relsEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/_rels/document.xml.rels' }
$relsStream = $relsEntry.Open()
$relsReader = New-Object System.IO.StreamReader($relsStream, [System.Text.Encoding]::UTF8)
$relsXml = $relsReader.ReadToEnd()
$relsReader.Close()
$relsStream.Close()

$zip.Dispose()

# Parse XML
$xmlDoc = [xml]$docXml
$relsDoc = [xml]$relsXml

# Create image mapping
$imageMap = @{}
$ns = New-Object System.Xml.XmlNamespaceManager($relsDoc.NameTable)
$ns.AddNamespace("r", "http://schemas.openxmlformats.org/package/2006/relationships")
$rels = $relsDoc.SelectNodes("//r:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image']", $ns)
foreach ($rel in $rels) {
    $rId = $rel.Id
    $target = $rel.Target
    $filename = Split-Path $target -Leaf
    $imageMap[$rId] = $filename
}

# Parse document in EXACT order
$nsW = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
$nsW.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$nsW.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
$nsW.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
$nsW.AddNamespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")
$nsW.AddNamespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")

$content = @()
$body = $xmlDoc.SelectSingleNode("//w:body", $nsW)

foreach ($node in $body.ChildNodes) {
    if ($node.LocalName -eq "p") {
        # Paragraph - check for images and text
        $para = $node
        
        # Get all drawings/inline images
        $drawings = $para.SelectNodes(".//a:blip", $nsW)
        $inlineDrawings = $para.SelectNodes(".//wp:inline", $nsW)
        
        # Process images first (they appear before text in XML)
        foreach ($drawing in $drawings) {
            $embed = $drawing.SelectSingleNode("./r:embed", $nsW)
            if ($embed) {
                $rId = $embed.GetAttribute("r:embed")
                if ($imageMap.ContainsKey($rId)) {
                    $content += @{Type="Image"; Value=$imageMap[$rId]}
                }
            }
        }
        
        foreach ($inline in $inlineDrawings) {
            $blip = $inline.SelectSingleNode(".//a:blip", $nsW)
            if ($blip) {
                $embed = $blip.SelectSingleNode("./r:embed", $nsW)
                if ($embed) {
                    $rId = $embed.GetAttribute("r:embed")
                    if ($imageMap.ContainsKey($rId)) {
                        $content += @{Type="Image"; Value=$imageMap[$rId]}
                    }
                }
            }
        }
        
        # Get text
        $text = ""
        $textNodes = $para.SelectNodes(".//w:t", $nsW)
        foreach ($t in $textNodes) {
            $text += $t.InnerText
        }
        
        if ($text.Trim() -ne "") {
            $content += @{Type="Text"; Value=$text.Trim()}
        }
    }
}

# Output EXACT order
$output = ""
$index = 1
foreach ($item in $content) {
    if ($item.Type -eq "Image") {
        $output += "[$index] IMAGE: $($item.Value)`n`n"
    } else {
        $output += "[$index] TEXT: $($item.Value)`n`n"
    }
    $index++
}

$output | Out-File "libreria_EXACT_order.txt" -Encoding UTF8
Write-Output "Extracted $($content.Count) items"
Write-Output "Images: $(($content | Where-Object {$_.Type -eq 'Image'}).Count)"
Write-Output "Text blocks: $(($content | Where-Object {$_.Type -eq 'Text'}).Count)"
