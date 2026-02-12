$ErrorActionPreference = "Stop"

$order = Get-Content "camino_exact_order.json" -Encoding UTF8 | ConvertFrom-Json

$html = ""
foreach ($item in $order) {
    if ($item.Type -eq "IMAGE") {
        $html += "            <div class=`"my-4`">`n"
        $html += "              <img src=`"/assets/$($item.Value)`" alt=`"`" class=`"w-full rounded-xl object-cover ring-1 ring-black/10`" />`n"
        $html += "            </div>`n"
    } elseif ($item.Type -eq "TEXT") {
        $text = $item.Value
        $text = $text -replace '\*([^*]+)\*', '<em>$1</em>'
        $text = $text -replace '\*\*([^*]+)\*\*', '<strong>$1</strong>'
        
        # Split by newlines
        $lines = $text -split '`n'
        
        # Check if it's a heading
        if ($text -match '^(Introducción|Características de la obra|La autora|La directora|Ficha técnica y reparto)$') {
            $html += "            <h3 class=`"mt-6 font-serif text-xl font-semibold text-ink`">$text</h3>`n"
        } elseif ($text -match '^(\d+\.\s+[^`n]+)') {
            # Numbered section heading
            $heading = $matches[1]
            $html += "            <h4 class=`"mt-4 font-semibold text-ink`">$heading</h4>`n"
            $remaining = $text -replace '^\d+\.\s+[^`n]+`n`n', ''
            if ($remaining -ne $text -and $remaining.Trim() -ne "") {
                # Check if it contains bullet points
                if ($remaining -match '•') {
                    $html += "            <p>$($remaining -split '•')[0]</p>`n"
                    $html += "            <ul class=`"list-disc list-inside space-y-2 ml-4`">`n"
                    $bullets = $remaining -split '•'
                    foreach ($bullet in $bullets) {
                        if ($bullet.Trim() -ne "") {
                            $bulletText = $bullet.Trim()
                            $bulletText = $bulletText -replace '^\s*:\s*', ''
                            $html += "              <li>$bulletText</li>`n"
                        }
                    }
                    $html += "            </ul>`n"
                } else {
                    $html += "            <p>$remaining</p>`n"
                }
            }
        } elseif ($text.Contains('•')) {
            # List items
            $html += "            <p>$($text -split '•')[0]</p>`n" 
            $html += "            <ul class=`"list-disc list-inside space-y-2 ml-4`">`n"
            $bullets = $text -split '•'
            foreach ($bullet in $bullets) {
                if ($bullet.Trim() -ne "" -and $bullet -notmatch '^[^:]+:') {
                    $bulletText = $bullet.Trim()
                    $html += "              <li>$bulletText</li>`n"
                }
            }
            $html += "            </ul>`n"
        } else {
            # Regular paragraph - split by double newlines
            $paragraphs = $text -split '`n`n'
            foreach ($para in $paragraphs) {
                $para = $para.Trim()
                if ($para -ne "") {
                    # Replace single newlines with spaces within paragraphs
                    $para = $para -replace '`n', ' '
                    $html += "            <p>$para</p>`n"
                }
            }
        }
    }
}

$html | Out-File -FilePath "camino_exact_generated.html" -Encoding UTF8

Write-Output "HTML generated with exact order"
