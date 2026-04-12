# Extract exact order from existing XML files
$docPath = "C:\Users\eslim\ANDA QUE ANDA\dossier_document.xml"
$relsPath = "C:\Users\eslim\ANDA QUE ANDA\dossier_rels.xml"

if (-not (Test-Path $docPath) -or -not (Test-Path $relsPath)) {
    Write-Host "XML files not found"
    exit 1
}

# Load XML files
$xmlDoc = New-Object System.Xml.XmlDocument
$xmlDoc.Load($docPath)

$relsDoc = New-Object System.Xml.XmlDocument
$relsDoc.Load($relsPath)

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
