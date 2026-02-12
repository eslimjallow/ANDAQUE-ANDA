$ErrorActionPreference = "Stop"

# Read the order
$order = Get-Content "final_order.json" -Encoding UTF8 | ConvertFrom-Json

# Reorder: image9.png first, then "Sinopsis", then rest
$reordered = @()
$image9Found = $false
$sinopsisFound = $false

# First, add image9.png if it exists
foreach ($item in $order) {
    if ($item.Type -eq "IMAGE" -and $item.Value -eq "image9.png" -and -not $image9Found) {
        $reordered += $item
        $image9Found = $true
        break
    }
}

# Then add "Sinopsis" text
foreach ($item in $order) {
    if ($item.Type -eq "TEXT" -and $item.Value.Trim() -eq "Sinopsis" -and -not $sinopsisFound) {
        $reordered += $item
        $sinopsisFound = $true
        break
    }
}

# Then add the rest, skipping image9.png and the first "Sinopsis"
foreach ($item in $order) {
    if ($item.Type -eq "IMAGE" -and $item.Value -eq "image9.png") {
        continue  # Skip, already added
    }
    if ($item.Type -eq "TEXT" -and $item.Value.Trim() -eq "Sinopsis" -and $sinopsisFound) {
        continue  # Skip, already added
    }
    $reordered += $item
}

# Build HTML
$html = ""
foreach ($item in $reordered) {
    if ($item.Type -eq "IMAGE") {
        $html += "            <div class=`"my-4`">`n"
        $html += "              <img src=`"/assets/$($item.Value)`" alt=`"`" class=`"w-full rounded-xl object-cover ring-1 ring-black/10`" />`n"
        $html += "            </div>`n"
    } elseif ($item.Type -eq "TEXT") {
        $text = $item.Value
        # Clean up any XML artifacts
        $text = $text -replace '<[^>]+>', ''
        $text = $text.Trim()
        
        if ($text -ne "") {
            # Check if it's a heading (bold text or short text)
            if ($text -match '^<strong>|^\*\*' -or ($text.Length -lt 50 -and -not $text.Contains('.'))) {
                $html += "            <p><strong>$text</strong></p>`n"
            } else {
                $html += "            <p>$text</p>`n"
            }
        }
    }
}

$html | Out-File -FilePath "generated_content.html" -Encoding UTF8

Write-Output "HTML generated with $($reordered.Count) items"
Write-Output "First 3 items:"
$reordered | Select-Object -First 3 | ForEach-Object {
    if ($_.Type -eq "IMAGE") {
        Write-Output "  IMAGE: $($_.Value)"
    } else {
        $text = $_.Value.Substring(0, [Math]::Min(50, $_.Value.Length))
        Write-Output "  TEXT: $text..."
    }
}
