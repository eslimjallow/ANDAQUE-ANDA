# Extract full content order from DOCX including images - EXACT ORDER
$docxPath = "C:\Users\eslim\ANDA QUE ANDA\Nuevo dossier La librería de las almas.docx"

if (-not (Test-Path $docxPath)) {
    Write-Error "Document not found at: $docxPath"
    exit 1
}

Write-Host "Extracting from: $docxPath"

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Open the docx file (it's a zip)
$zip = [System.IO.Compression.ZipFile]::OpenRead($docxPath)

# Get document.xml
$docEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
if (-not $docEntry) {
    Write-Error "document.xml not found"
    $zip.Dispose()
    exit 1
}

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
} else {
    $relsXml = ""
}

$zip.Dispose()

# Save XML files for debugging
$docXml | Out-File "libreria_document_full.xml" -Encoding UTF8
$relsXml | Out-File "libreria_rels_full.xml" -Encoding UTF8

# Parse XML
$xmlDoc = [xml]$docXml
$relsDoc = if ($relsXml) { [xml]$relsXml } else { $null }

# Create mapping of rId to image filename
$imageMap = @{}
if ($relsDoc) {
    $ns = New-Object System.Xml.XmlNamespaceManager($relsDoc.NameTable)
    $ns.AddNamespace("r", "http://schemas.openxmlformats.org/package/2006/relationships")
    $rels = $relsDoc.SelectNodes("//r:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image']", $ns)
    foreach ($rel in $rels) {
        $rId = $rel.Id
        $target = $rel.Target
        $filename = Split-Path $target -Leaf
        $imageMap[$rId] = $filename
    }
}

# Parse document.xml to find images and text in EXACT order
$nsW = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
$nsW.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$nsW.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
$nsW.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
$nsW.AddNamespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")
$nsW.AddNamespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")

$content = @()
$paragraphs = $xmlDoc.SelectNodes("//w:p", $nsW)

foreach ($para in $paragraphs) {
    # Check for images first (they come before text in the paragraph)
    $drawings = $para.SelectNodes(".//a:blip", $nsW)
    $inlineDrawings = $para.SelectNodes(".//wp:inline", $nsW)
    
    # Get text
    $text = ""
    $textNodes = $para.SelectNodes(".//w:t", $nsW)
    foreach ($t in $textNodes) {
        $text += $t.InnerText
    }
    
    # Process images first if they exist
    if ($drawings.Count -gt 0) {
        foreach ($drawing in $drawings) {
            $embed = $drawing.SelectSingleNode("./r:embed", $nsW)
            if ($embed) {
                $rId = $embed.GetAttribute("r:embed")
                if ($imageMap.ContainsKey($rId)) {
                    $content += @{Type="Image"; Value=$imageMap[$rId]; Index=$content.Count}
                }
            }
        }
    }
    
    # Also check inline drawings
    if ($inlineDrawings.Count -gt 0) {
        foreach ($inline in $inlineDrawings) {
            $blip = $inline.SelectSingleNode(".//a:blip", $nsW)
            if ($blip) {
                $embed = $blip.SelectSingleNode("./r:embed", $nsW)
                if ($embed) {
                    $rId = $embed.GetAttribute("r:embed")
                    if ($imageMap.ContainsKey($rId)) {
                        $content += @{Type="Image"; Value=$imageMap[$rId]; Index=$content.Count}
                    }
                }
            }
        }
    }
    
    # Add text if it exists
    if ($text.Trim() -ne "") {
        $content += @{Type="Text"; Value=$text.Trim(); Index=$content.Count}
    }
}

# Output the order
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

$output | Out-File "libreria_full_order_complete.txt" -Encoding UTF8
Write-Output "Content order extracted. Total items: $($content.Count)"
Write-Output "Images found: $(($content | Where-Object {$_.Type -eq 'Image'}).Count)"
Write-Output "Text blocks found: $(($content | Where-Object {$_.Type -eq 'Text'}).Count)"
