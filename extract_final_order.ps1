$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read the XML files
$docContent = Get-Content "docx_document.xml" -Raw -Encoding UTF8
$relsContent = Get-Content "docx_rels.xml" -Raw -Encoding UTF8

# Parse relationships to map rId to image filename
$imageMap = @{}
$relsMatches = [regex]::Matches($relsContent, 'Id="(rId\d+)"[^>]*Target="media/([^"]+)"')
foreach ($match in $relsMatches) {
    $rId = $match.Groups[1].Value
    $imageName = $match.Groups[2].Value
    $imageMap[$rId] = $imageName
}

Write-Output "Image mappings:"
$imageMap.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Output "  $($_.Key) -> $($_.Value)" }

# Extract paragraphs
$paraMatches = [regex]::Matches($docContent, '<w:p[^>]*>.*?</w:p>', [System.Text.RegularExpressions.RegexOptions]::Singleline)

$contentOrder = @()

foreach ($para in $paraMatches) {
    $paraXml = $para.Value
    
    # Check for image
    $imageMatch = [regex]::Match($paraXml, 'r:embed="(rId\d+)"')
    if ($imageMatch.Success) {
        $rId = $imageMatch.Groups[1].Value
        if ($imageMap.ContainsKey($rId)) {
            $contentOrder += @{
                Type = "IMAGE"
                Value = $imageMap[$rId]
            }
        }
    }
    
    # Extract text from all w:t nodes
    $textMatches = [regex]::Matches($paraXml, '<w:t[^>]*>(.*?)</w:t>')
    $paraText = ""
    foreach ($textMatch in $textMatches) {
        $paraText += $textMatch.Groups[1].Value
    }
    
    # Add text if not empty
    $paraText = $paraText.Trim()
    if ($paraText -ne "") {
        $contentOrder += @{
            Type = "TEXT"
            Value = $paraText
        }
    }
}

# Output JSON
$contentOrder | ConvertTo-Json -Depth 10 | Out-File -FilePath "final_order.json" -Encoding UTF8

# Also output readable text
$output = ""
foreach ($item in $contentOrder) {
    if ($item.Type -eq "IMAGE") {
        $output += "[IMAGE: $($item.Value)]`n"
    } else {
        $output += "[TEXT: $($item.Value)]`n"
    }
}
$output | Out-File -FilePath "final_order.txt" -Encoding UTF8

Write-Output "`nExtracted $($contentOrder.Count) items:"
Write-Output "  Images: $($contentOrder | Where-Object { $_.Type -eq 'IMAGE' } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Output "  Texts: $($contentOrder | Where-Object { $_.Type -eq 'TEXT' } | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Output "`nFirst 5 items:"
$contentOrder | Select-Object -First 5 | ForEach-Object { 
    if ($_.Type -eq "IMAGE") {
        Write-Output "  IMAGE: $($_.Value)"
    } else {
        $text = $_.Value.Substring(0, [Math]::Min(60, $_.Value.Length))
        Write-Output "  TEXT: $text..."
    }
}
