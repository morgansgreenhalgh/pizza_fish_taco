param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$OutputDir,
    [int]$Columns = 4,
    [int]$Rows = 4,
    [int]$TargetHeight = 156
)

Add-Type -AssemblyName System.Drawing

$frameNames = @(
    "idle_0", "idle_1", "walk_0", "idle_2",
    "run_0", "run_1", "run_2", "run_3",
    "bite_0", "bite_1", "sauce_0", "hurt_0",
    "spin_0", "spin_1", "crouch_0", "jump_0"
)

function Is-BackgroundPixel($pixel) {
    $max = [Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B))
    $min = [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B))
    return ($min -ge 205 -and ($max - $min) -le 18)
}

function Export-Frame($sourceImage, $rect, $name, $outputDir, $targetHeight) {
    $cell = [System.Drawing.Bitmap]::new($rect.Width, $rect.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $cellGraphics = [System.Drawing.Graphics]::FromImage($cell)
    $cellGraphics.DrawImage($sourceImage, [System.Drawing.Rectangle]::new(0, 0, $rect.Width, $rect.Height), $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $cellGraphics.Dispose()

    $transparent = New-Object 'bool[,]' $rect.Width, $rect.Height
    $queue = [System.Collections.Generic.Queue[System.Drawing.Point]]::new()

    for ($x = 0; $x -lt $rect.Width; $x++) {
        $queue.Enqueue([System.Drawing.Point]::new($x, 0))
        $queue.Enqueue([System.Drawing.Point]::new($x, $rect.Height - 1))
    }
    for ($y = 0; $y -lt $rect.Height; $y++) {
        $queue.Enqueue([System.Drawing.Point]::new(0, $y))
        $queue.Enqueue([System.Drawing.Point]::new($rect.Width - 1, $y))
    }

    while ($queue.Count -gt 0) {
        $point = $queue.Dequeue()
        if ($point.X -lt 0 -or $point.X -ge $rect.Width -or $point.Y -lt 0 -or $point.Y -ge $rect.Height) {
            continue
        }
        if ($transparent[$point.X, $point.Y]) {
            continue
        }
        if (-not (Is-BackgroundPixel $cell.GetPixel($point.X, $point.Y))) {
            continue
        }
        $transparent[$point.X, $point.Y] = $true
        $queue.Enqueue([System.Drawing.Point]::new($point.X + 1, $point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X - 1, $point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y + 1))
        $queue.Enqueue([System.Drawing.Point]::new($point.X, $point.Y - 1))
    }

    $minX = $rect.Width
    $minY = $rect.Height
    $maxX = 0
    $maxY = 0

    for ($y = 0; $y -lt $rect.Height; $y++) {
        for ($x = 0; $x -lt $rect.Width; $x++) {
            $pixel = $cell.GetPixel($x, $y)
            if ($transparent[$x, $y]) {
                $cell.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            } else {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
                $cell.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B))
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
        if ($frameIndex -ge $frameNames.Count) {
            break
        }
        $rect = [System.Drawing.Rectangle]::new($col * $cellWidth, $row * $cellHeight, $cellWidth, $cellHeight)
        Export-Frame $sourceImage $rect $frameNames[$frameIndex] $OutputDir $TargetHeight
        $frameIndex++
    }
}

$sourceImage.Dispose()
