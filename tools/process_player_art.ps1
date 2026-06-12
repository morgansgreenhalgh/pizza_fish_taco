param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Output,
    [int]$TargetHeight = 156
)

Add-Type -AssemblyName System.Drawing

$sourceImage = [System.Drawing.Bitmap]::new($Source)
$threshold = 242
$softThreshold = 214
$minX = $sourceImage.Width
$minY = $sourceImage.Height
$maxX = 0
$maxY = 0

for ($y = 0; $y -lt $sourceImage.Height; $y++) {
    for ($x = 0; $x -lt $sourceImage.Width; $x++) {
        $pixel = $sourceImage.GetPixel($x, $y)
        if ($pixel.R -lt $threshold -or $pixel.G -lt $threshold -or $pixel.B -lt $threshold) {
            if ($x -lt $minX) { $minX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

$padding = 12
$minX = [Math]::Max(0, $minX - $padding)
$minY = [Math]::Max(0, $minY - $padding)
$maxX = [Math]::Min($sourceImage.Width - 1, $maxX + $padding)
$maxY = [Math]::Min($sourceImage.Height - 1, $maxY + $padding)

$cropWidth = $maxX - $minX + 1
$cropHeight = $maxY - $minY + 1
$scale = $TargetHeight / $cropHeight
$targetWidth = [Math]::Max(1, [int][Math]::Round($cropWidth * $scale))

$outputImage = [System.Drawing.Bitmap]::new($targetWidth, $TargetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($outputImage)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

for ($ty = 0; $ty -lt $TargetHeight; $ty++) {
    for ($tx = 0; $tx -lt $targetWidth; $tx++) {
        $sx = [Math]::Min($sourceImage.Width - 1, $minX + [int][Math]::Floor($tx / $scale))
        $sy = [Math]::Min($sourceImage.Height - 1, $minY + [int][Math]::Floor($ty / $scale))
        $pixel = $sourceImage.GetPixel($sx, $sy)
        $whiteDistance = [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B))
        $alpha = 255
        if ($whiteDistance -ge $threshold) {
            $alpha = 0
        } elseif ($whiteDistance -gt $softThreshold) {
            $alpha = [int][Math]::Round(255 * (($threshold - $whiteDistance) / ($threshold - $softThreshold)))
        }
        $outputImage.SetPixel($tx, $ty, [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B))
    }
}

$outputDir = Split-Path -Parent $Output
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$outputImage.Save($Output, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$outputImage.Dispose()
$sourceImage.Dispose()

Write-Host "Wrote $Output ($targetWidth x $TargetHeight)"
