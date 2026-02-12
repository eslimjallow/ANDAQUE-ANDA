$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$files = Get-ChildItem
$docx = $files | Where-Object { $_.Extension -eq ".docx" } | Select-Object -First 1
if (-not $docx) {
    Write-Error "DOCX file not found"
    exit 1
}
$docxPath = $docx.FullName
Write-Output "Using file: $($docx.Name)"

Add-Type -AssemblyName System.IO.Compression.FileSystem

try {
    $zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $docxPath).Path)
    
    $document = $zip.Entries | Where-Object { $_.FullName -eq "word/document.xml" }
    $rels = $zip.Entries | Where-Object { $_.FullName -eq "word/_rels/document.xml.rels" }
    
    if (-not $document) {
        Write-Error "document.xml not found"
        $zip.Dispose()
        exit 1
    }
    if (-not $rels) {
        Write-Error "document.xml.rels not found"
        $zip.Dispose()
        exit 1
    }
    
    # Read document.xml
    $documentStream = $document.Open()
    $documentReader = New-Object System.IO.StreamReader($documentStream, [System.Text.Encoding]::UTF8)
    $documentContent = $documentReader.ReadToEnd()
    $documentReader.Close()
    $documentStream.Close()
    
    # Read relationships
    $relsStream = $rels.Open()
    $relsReader = New-Object System.IO.StreamReader($relsStream, [System.Text.Encoding]::UTF8)
    $relsContent = $relsReader.ReadToEnd()
    $relsReader.Close()
    $relsStream.Close()
    
    $zip.Dispose()
    
    # Parse XML
    $docXml = New-Object System.Xml.XmlDocument
    $docXml.LoadXml($documentContent)
    
    $relsXml = New-Object System.Xml.XmlDocument
    $relsXml.LoadXml($relsContent)
    
    # Create namespace manager
    $nsManager = New-Object System.Xml.XmlNamespaceManager($docXml.NameTable)
    $nsManager.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
    $nsManager.AddNamespace("r", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
    $nsManager.AddNamespace("a", "http://schemas.openxmlformats.org/drawingml/2006/main")
    $nsManager.AddNamespace("pic", "http://schemas.openxmlformats.org/drawingml/2006/picture")
    $nsManager.AddNamespace("wp", "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing")
    
    # Build image ID to filename mapping
    $imageMap = @{}
    $relsNodes = $relsXml.SelectNodes("//Relationship[@Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image']")
    foreach ($rel in $relsNodes) {
        $id = $rel.GetAttribute("Id")
        $target = $rel.GetAttribute("Target")
        $imageName = Split-Path $target -Leaf
        $imageMap[$id] = $imageName
    }
    
    # Extract content in order
    $contentOrder = @()
    $paragraphs = $docXml.SelectNodes("//w:p", $nsManager)
    
    foreach ($p in $paragraphs) {
        $paraText = ""
        $paraImage = $null
        
        # Check for images in this paragraph
        $drawings = $p.SelectNodes(".//w:drawing", $nsManager)
        foreach ($drawing in $drawings) {
            $blip = $drawing.SelectSingleNode(".//a:blip", $nsManager)
            if ($blip) {
                $embedId = $blip.GetAttribute("embed", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
                if ($embedId -and $imageMap.ContainsKey($embedId)) {
                    $paraImage = $imageMap[$embedId]
                }
            }
        }
        
        # Extract text from runs
        $runs = $p.SelectNodes("w:r", $nsManager)
        foreach ($r in $runs) {
            $textNodes = $r.SelectNodes("w:t", $nsManager)
            foreach ($text in $textNodes) {
                if ($text.InnerText) {
                    $paraText += $text.InnerText
                }
            }
        }
        
        # Add image if found
        if ($paraImage) {
            $contentOrder += @{
                Type = "IMAGE"
                Value = $paraImage
            }
        }
        
        # Add text if found (and not just whitespace)
        if ($paraText.Trim() -ne "") {
            $contentOrder += @{
                Type = "TEXT"
                Value = $paraText.Trim()
            }
        }
    }
    
    # Output JSON
    $contentOrder | ConvertTo-Json -Depth 10 | Out-File -FilePath "exact_order.json" -Encoding UTF8
    
    Write-Output "Extracted $($contentOrder.Count) items"
    Write-Output "Images: $($contentOrder | Where-Object { $_.Type -eq 'IMAGE' } | Measure-Object | Select-Object -ExpandProperty Count)"
    Write-Output "Texts: $($contentOrder | Where-Object { $_.Type -eq 'TEXT' } | Measure-Object | Select-Object -ExpandProperty Count)"
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
