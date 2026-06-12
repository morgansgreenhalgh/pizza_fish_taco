param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$OutputDir,
    [string[]]$FrameNames = @(
        "idle_0", "walk_0", "walk_1", "windup_0",
        "attack_0", "hurt_0", "knockback_0", "defeated_0",
        "taunt_0", "run_0", "stunned_0", "recover_0"
    ),
    [int]$Columns = 4,
    [int]$Rows = 3,
    [int]$TargetHeight = 96
)

Add-Type -AssemblyName System.Drawing

function Is-KeyPixel($pixel) {
    return ($pixel.G -gt 145 -and $pixel.G -gt ($pixel.R * 1.25) -and $pixel.G -gt ($pixel.B * 1.25))
}

function Export-Frame($sourceImage, $rect, $name, $outputDir, $targetHeight) {
    $cell = [System.Drawing.Bitmap]::new($rect.Width, $rect.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cellGraphics = [System.Drawing.Graphics]::FromImage($cell)
    $cellGraphics.DrawImage($sourceImage, [System.Drawing.Rectangle]::new(0, 0, $rect.Width, $rect.Height), $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $cellGraphics.Dispose()

    $minX = $rect.Width
    $minY = $rect.Height
    $maxX = 0
    $maxY = 0

    for ($y = 0; $y -lt $rect.Height; $y++) {
        for ($x = 0; $x -lt $rect.Width; $x++) {
            $pixel = $cell.GetPixel($x, $y)
            if (Is-KeyPixel $pixel) {
                $cell.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            } else {
                $alpha = 255
                if ($pixel.G -gt 105 -and $pixel.G -gt ($pixel.R * 1.08) -and $pixel.G -gt ($pixel.B * 1.08)) {
                    $alpha = [Math]::Max(0, [Math]::Min(255, 255 - (($pixel.G - [Math]::Max($pixel.R, $pixel.B)) * 3)))
                }
                if ($alpha -gt 0) {
                    if ($x -lt $minX) { $minX = $x }
                    if ($y -lt $minY) { $minY = $y }
                    if ($x -gt $maxX) { $maxX = $x }
                    if ($y -gt $maxY) { $maxY = $y }
                }
                $cell.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B))
            }
        }
    }

    if ($minX -gt $maxX -or $minY -gt $maxY) {
        $cell.Dispose()
        return
    }

    $padding = 6
    $minX = [Math]::Max(0, $minX - $padding)
    $minY = [Math]::Max(0, $minY - $padding)
    $maxX = [Math]::Min($rect.Width - 1, $maxX + $padding)
    $maxY = [Math]::Min($rect.Height - 1, $maxY + $padding)

    $cropWidth = $maxX - $minX + 1
    $cropHeight = $maxY - $minY + 1
    $scale = $targetHeight / $cropHeight
    $targetWidth = [Math]::Max(1, [int][Math]::Round($cropWidth * $scale))

    $output = [System.Drawing.Bitmap]::new($targetWidth, $targetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($ty = 0; $ty -lt $targetHeight; $ty++) {
        for ($tx = 0; $tx -lt $targetWidth; $tx++) {
            $sx = [Math]::Min($rect.Width - 1, $minX + [int][Math]::Floor($tx / $scale))
            $sy = [Math]::Min($rect.Height - 1, $minY + [int][Math]::Floor($ty / $scale))
            $output.SetPixel($tx, $ty, $cell.GetPixel($sx, $sy))
        }
    }

    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    $outputPath = Join-Path $outputDir "$name.png"
    $output.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "Wrote $outputPath ($targetWidth x $targetHeight)"

    $output.Dispose()
    $cell.Dispose()
}

$sourceImage = [System.Drawing.Bitmap]::new($Source)
$cellWidth = [int][Math]::Floor($sourceImage.Width / $Columns)
$cellHeight = [int][Math]::Floor($sourceImage.Height / $Rows)
$frameIndex = 0

for ($row = 0; $row -lt $Rows; $row++) {
    for ($col = 0; $col -lt $Columns; $col++) {
        if ($frameIndex -ge $FrameNames.Count) {
            break
        }
        $rect = [System.Drawing.Rectangle]::new($col * $cellWidth, $row * $cellHeight, $cellWidth, $cellHeight)
        Export-Frame $sourceImage $rect $FrameNames[$frameIndex] $OutputDir $TargetHeight
        $frameIndex++
    }
}

$sourceImage.Dispose()
