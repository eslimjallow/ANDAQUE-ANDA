param (
    [string]$pdfPath
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

try {
    $pdfBytes = [System.IO.File]::ReadAllBytes($pdfPath)
    $pdfText = [System.Text.Encoding]::ASCII.GetString($pdfBytes)
    
    Write-Output "Extracting images from PDF..."
    
    # Find all image objects
    $imageObjects = [regex]::Matches($pdfText, '(\d+) 0 obj\s*<</Type/XObject/Subtype/Image')
    Write-Output "Found $($imageObjects.Count) image objects"
    
    # Find page-to-image mapping
    $pageImageMap = @{}
    $pages = [regex]::Matches($pdfText, '(\d+) 0 obj\s*<</Type/Page[^>]*/XObject<</Image(\d+)')
    foreach ($match in $pages) {
        $pageObj = $match.Groups[1].Value
        $imageNum = $match.Groups[2].Value
        $pageImageMap[$pageObj] = $imageNum
        Write-Output "Page object $pageObj has Image$imageNum"
    }
    
    # Determine page order
    $pageOrder = @(3, 12, 37, 57, 60, 63, 66, 69)
    Write-Output "`nPage order: $($pageOrder -join ', ')"
    
    Write-Output "`nImage order based on pages:"
    for ($i = 0; $i -lt $pageOrder.Count; $i++) {
        $pageObj = $pageOrder[$i]
        if ($pageImageMap.ContainsKey($pageObj)) {
            $imgNum = $pageImageMap[$pageObj]
            Write-Output "  Page $($i+1) -> Image$imgNum -> camino-$($i+1).jpg"
        }
    }
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
}
