$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$files = Get-ChildItem
$docx = $files | Where-Object { $_.Extension -eq ".docx" } | Select-Object -First 1
if (-not $docx) {
    Write-Error "DOCX file not found"
    exit 1
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::OpenRead($docx.FullName)

# Extract document.xml
$document = $zip.Entries | Where-Object { $_.FullName -eq "word/document.xml" }
$rels = $zip.Entries | Where-Object { $_.FullName -eq "word/_rels/document.xml.rels" }

$documentStream = $document.Open()
$documentReader = New-Object System.IO.StreamReader($documentStream, [System.Text.Encoding]::UTF8)
$documentContent = $documentReader.ReadToEnd()
$documentReader.Close()
$documentStream.Close()

$relsStream = $rels.Open()
$relsReader = New-Object System.IO.StreamReader($relsStream, [System.Text.Encoding]::UTF8)
$relsContent = $relsReader.ReadToEnd()
$relsReader.Close()
$relsStream.Close()

$documentContent | Out-File -FilePath "docx_document.xml" -Encoding UTF8
$relsContent | Out-File -FilePath "docx_rels.xml" -Encoding UTF8

# Extract all images
$mediaEntries = $zip.Entries | Where-Object { $_.FullName -like "word/media/*" }
if (-not (Test-Path "docx_images")) {
    New-Item -ItemType Directory -Path "docx_images" | Out-Null
}
foreach ($entry in $mediaEntries) {
    $entryStream = $entry.Open()
    $fileStream = [System.IO.File]::Create("docx_images\$($entry.Name)")
    $entryStream.CopyTo($fileStream)
    $fileStream.Close()
    $entryStream.Close()
}

$zip.Dispose()

Write-Output "Extracted document.xml, rels, and $($mediaEntries.Count) images"
