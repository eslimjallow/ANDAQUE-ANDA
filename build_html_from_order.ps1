# Build HTML from exact order
$imageMap = @{
    "rId6" = "image1.jpeg"
    "rId7" = "image2.jpeg"
    "rId8" = "image3.jpeg"
    "rId9" = "image4.jpeg"
    "rId10" = "image5.jpeg"
    "rId11" = "image6.jpeg"
    "rId12" = "image7.jpeg"
    "rId13" = "image8.jpeg"
    "rId14" = "image9.png"
    "rId15" = "image10.jpeg"
    "rId16" = "image11.jpeg"
    "rId17" = "image12.jpeg"
    "rId18" = "image13.jpeg"
    "rId20" = "image14.jpeg"
    "rId21" = "image15.jpeg"
    "rId22" = "image16.jpeg"
    "rId23" = "image17.jpeg"
    "rId24" = "image18.jpeg"
    "rId25" = "image19.jpeg"
    "rId26" = "image20.jpeg"
    "rId27" = "image21.jpeg"
}

$order = Get-Content "para_order.txt"
$html = ""
$isFirst = $true

foreach ($line in $order) {
    if ($line -match 'IMAGE: rId=(rId\d+)') {
        $rId = $matches[1]
        if ($imageMap.ContainsKey($rId)) {
            $imgFile = $imageMap[$rId]
            # User said image9.png should be first
            if ($imgFile -eq "image9.png" -and $isFirst) {
                $html += "IMAGE: $imgFile`n"
                $isFirst = $false
            } elseif ($imgFile -ne "image9.png") {
                $html += "IMAGE: $imgFile`n"
            }
        }
    } elseif ($line -match 'TEXT: (.+)') {
        $text = $matches[1]
        if ($text -notmatch '^<w:' -and $text.Trim().Length -gt 1) {
            $html += "TEXT: $text`n`n"
        }
    }
}

$html | Out-File "final_order.txt" -Encoding UTF8
Write-Output "HTML order built"
