# Extract full content order from DOCX
$xmlDoc = [xml](Get-Content "dossier_document.xml" -Encoding UTF8)
$relsDoc = [xml](Get-Content "dossier_rels.xml" -Encoding UTF8)

# Create mapping of rId to image filename
$imageMap = @{}
$nsRels = New-Object System.Xml.XmlNamespaceManager($relsDoc.NameTable)
$nsRels.AddNamespace("r", "http://schemas.openxmlformats.org/package/2006/relationships")
$rels = $relsDoc.SelectNodes("//r:Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image']", $nsRels)
foreach ($rel in $rels) {
    $rId = $rel.Id
    $target = $rel.Target
    $filename = Split-Path $target -Leaf
    $imageMap[$rId] = $filename
}

# Parse document.xml
$ns = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
$ns.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$ns.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
$ns.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
$ns.AddNamespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")
$ns.AddNamespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")

$content = @()
$paragraphs = $xmlDoc.SelectNodes("//w:p", $ns)

foreach ($para in $paragraphs) {
    # Check for images in this paragraph
    $drawings = $para.SelectNodes(".//a:blip", $ns)
    foreach ($drawing in $drawings) {
        $embed = $drawing.SelectSingleNode("./r:embed", $ns)
        if ($embed) {
            $rId = $embed.GetAttribute("r:embed")
            if ($imageMap.ContainsKey($rId)) {
                $content += @{Type="Image"; Value=$imageMap[$rId]; Position=$content.Count}
            }
        }
    }
    
    # Get text from paragraph
    $textNodes = $para.SelectNodes(".//w:t", $ns)
    $text = ""
    foreach ($t in $textNodes) {
        $text += $t.InnerText
    }
    
    if ($text.Trim() -ne "" -and $text.Trim() -ne ".") {
        $content += @{Type="Text"; Value=$text.Trim(); Position=$content.Count}
    }
}

# Output the order
$output = ""
$i = 0
foreach ($item in $content) {
    $i++
    if ($item.Type -eq "Image") {
        $output += "[$i] IMAGE: $($item.Value)`n"
    } else {
        $output += "[$i] TEXT: $($item.Value)`n`n"
    }
}

$output | Out-File "dossier_full_order.txt" -Encoding UTF8
Write-Output "Full content order extracted. Total items: $($content.Count)"
