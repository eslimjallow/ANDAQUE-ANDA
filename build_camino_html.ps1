$ErrorActionPreference = "Stop"

$order = Get-Content "camino_content_order.json" -Encoding UTF8 | ConvertFrom-Json

$html = ""
foreach ($item in $order) {
    if ($item.Type -eq "IMAGE") {
        $html += "            <div class=`"my-4`">`n"
        $html += "              <img src=`"/assets/$($item.Value)`" alt=`"$($item.Description)`" class=`"w-full rounded-xl object-cover ring-1 ring-black/10`" />`n"
        $html += "            </div>`n"
    } elseif ($item.Type -eq "TEXT") {
        $text = $item.Value
        $text = $text -replace '\*([^*]+)\*', '<em>$1</em>'
        $text = $text -replace '\*\*([^*]+)\*\*', '<strong>$1</strong>'
        $text = $text -replace '`n', "`n            "
        
        # Check if it's a heading
        if ($text -match '^(Introducción|Características de la obra|La autora|La directora|Ficha técnica y reparto)$') {
            $html += "            <h3 class=`"mt-6 font-serif text-xl font-semibold text-ink`">$text</h3>`n"
        } elseif ($text -match '^(\d+\.\s+[^`n]+)') {
            # Numbered section
            $html += "            <h4 class=`"mt-4 font-semibold text-ink`">$($matches[1])</h4>`n"
            $remaining = $text -replace '^\d+\.\s+[^`n]+`n`n', ''
            if ($remaining -ne $text) {
                $html += "            <p>$remaining</p>`n"
            }
        } elseif ($text.Contains('•') -or $text.Contains('-')) {
            # List items
            $lines = $text -split '`n'
            $html += "            <ul class=`"list-disc list-inside space-y-2 ml-4`">`n"
            foreach ($line in $lines) {
                if ($line -match '^[•\-]\s*(.+)') {
                    $html += "              <li>$($matches[1])</li>`n"
                }
            }
            $html += "            </ul>`n"
        } else {
            # Regular paragraph
            $html += "            <p>$text</p>`n"
        }
    }
}

$html | Out-File -FilePath "camino_generated.html" -Encoding UTF8

Write-Output "HTML generated"
