# Extract full content order from DOCX including images
$docxPath = Join-Path $PSScriptRoot "Nuevo dossier La librería de las almas.docx"
if (-not (Test-Path $docxPath)) {
    $docxPath = "C:\Users\eslim\ANDA QUE ANDA\Nuevo dossier La librería de las almas.docx"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Open the docx file (it's a zip)
$zip = [System.IO.Compression.ZipFile]::OpenRead($docxPath)

# Get document.xml
$docEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
$docStream = $docEntry.Open()
$docReader = New-Object System.IO.StreamReader($docStream)
$docXml = $docReader.ReadToEnd()
$docReader.Close()
$docStream.Close()

# Get relationships
$relsEntry = $zip.Entries | Where-Object { $_.FullName -eq 'word/_rels/document.xml.rels' }
$relsStream = $relsEntry.Open()
$relsReader = New-Object System.IO.StreamReader($relsStream)
$relsXml = $relsReader.ReadToEnd()
$relsReader.Close()
$relsStream.Close()

$zip.Dispose()

# Save XML files
$docXml | Out-File "libreria_document.xml" -Encoding UTF8
$relsXml | Out-File "libreria_rels.xml" -Encoding UTF8

# Parse XML
$xmlDoc = [xml]$docXml
$relsDoc = [xml]$relsXml

# Create mapping of rId to image filename
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

# Parse document.xml to find images and text
$nsW = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
$nsW.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$nsW.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
$nsW.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
$nsW.AddNamespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")

$content = @()
$paragraphs = $xmlDoc.SelectNodes("//w:p", $nsW)

foreach ($para in $paragraphs) {
    # Check if paragraph has an image
    $drawings = $para.SelectNodes(".//a:blip", $nsW)
    $text = ""
    $textNodes = $para.SelectNodes(".//w:t", $nsW)
    foreach ($t in $textNodes) {
        $text += $t.InnerText
    }
    
    if ($drawings.Count -gt 0) {
        # This paragraph has an image
        foreach ($drawing in $drawings) {
            $embed = $drawing.SelectSingleNode("./r:embed", $nsW)
            if ($embed) {
                $rId = $embed.GetAttribute("r:embed")
                if ($imageMap.ContainsKey($rId)) {
                    $content += @{Type="Image"; Value=$imageMap[$rId]}
                }
            }
        }
    }
    
    if ($text.Trim() -ne "") {
        $content += @{Type="Text"; Value=$text.Trim()}
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

$output | Out-File "libreria_full_order.txt" -Encoding UTF8
Write-Output "Content order extracted. Total items: $($content.Count)"
