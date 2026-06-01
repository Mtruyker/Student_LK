param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

Add-Type -AssemblyName System.Drawing

function New-RoundedRectPath {
    param(
        [System.Drawing.RectangleF]$Rect,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-ResizedPng {
    param(
        [System.Drawing.Bitmap]$Source,
        [int]$Size,
        [string]$Path
    )

    $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($Source, 0, 0, $Size, $Size)
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()
}

$iconDir = Join-Path $ProjectRoot "assets\icon"
$resRoot = Join-Path $ProjectRoot "android\app\src\main\res"
New-Item -ItemType Directory -Force -Path $iconDir | Out-Null

$sourceSize = 1024
$sourceBitmap = New-Object System.Drawing.Bitmap $sourceSize, $sourceSize
$graphics = [System.Drawing.Graphics]::FromImage($sourceBitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

$background = New-RoundedRectPath ([System.Drawing.RectangleF]::new(0, 0, $sourceSize, $sourceSize)) 220
$gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    [System.Drawing.Rectangle]::new(0, 0, $sourceSize, $sourceSize),
    [System.Drawing.Color]::FromArgb(255, 27, 74, 60),
    [System.Drawing.Color]::FromArgb(255, 92, 166, 108),
    55
)
$graphics.FillPath($gradient, $background)

$glowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(40, 255, 255, 255))
$graphics.FillEllipse($glowBrush, 110, 90, 820, 820)
$graphics.FillEllipse($glowBrush, 220, 520, 320, 220)

$shadowPath = New-RoundedRectPath ([System.Drawing.RectangleF]::new(248, 226, 528, 580)) 84
$shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(42, 10, 32, 24))
$graphics.FillPath($shadowBrush, $shadowPath)

$cardPath = New-RoundedRectPath ([System.Drawing.RectangleF]::new(232, 206, 528, 580)) 84
$cardBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 247, 251, 248))
$graphics.FillPath($cardBrush, $cardPath)

$tabPath = New-RoundedRectPath ([System.Drawing.RectangleF]::new(336, 168, 172, 82)) 34
$tabBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 38, 128, 91))
$graphics.FillPath($tabBrush, $tabPath)

$avatarBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 38, 128, 91))
$graphics.FillEllipse($avatarBrush, 320, 332, 184, 184)

$avatarCutBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 247, 251, 248))
$graphics.FillEllipse($avatarCutBrush, 387, 366, 50, 50)
$graphics.FillEllipse($avatarCutBrush, 362, 418, 100, 66)

$lineBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 44, 111, 84))
$lineSoftBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 153, 188, 165))

$line1 = New-RoundedRectPath ([System.Drawing.RectangleF]::new(540, 350, 132, 26)) 13
$line2 = New-RoundedRectPath ([System.Drawing.RectangleF]::new(540, 400, 180, 26)) 13
$line3 = New-RoundedRectPath ([System.Drawing.RectangleF]::new(300, 566, 336, 24)) 12
$line4 = New-RoundedRectPath ([System.Drawing.RectangleF]::new(300, 618, 266, 24)) 12
$graphics.FillPath($lineBrush, $line1)
$graphics.FillPath($lineSoftBrush, $line2)
$graphics.FillPath($lineBrush, $line3)
$graphics.FillPath($lineSoftBrush, $line4)

$capBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 233, 184, 82))
$capPoints = [System.Drawing.Point[]]@(
    [System.Drawing.Point]::new(568, 208),
    [System.Drawing.Point]::new(760, 270),
    [System.Drawing.Point]::new(602, 328),
    [System.Drawing.Point]::new(410, 266)
)
$graphics.FillPolygon($capBrush, $capPoints)

$capBasePath = New-RoundedRectPath ([System.Drawing.RectangleF]::new(520, 286, 118, 38)) 16
$graphics.FillPath($capBrush, $capBasePath)
$tasselPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 233, 184, 82), 12)
$tasselPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$tasselPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$graphics.DrawLine($tasselPen, 693, 283, 720, 388)
$graphics.FillEllipse($capBrush, 704, 380, 26, 26)

$accentBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 233, 184, 82))
$graphics.FillEllipse($accentBrush, 208, 694, 70, 70)
$graphics.FillEllipse($accentBrush, 760, 178, 40, 40)

$sourcePath = Join-Path $iconDir "app_icon.png"
$sourceBitmap.Save($sourcePath, [System.Drawing.Imaging.ImageFormat]::Png)

$sizes = @{
    "mipmap-mdpi"  = 48
    "mipmap-hdpi"  = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($entry in $sizes.GetEnumerator()) {
    $folder = Join-Path $resRoot $entry.Key
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $iconPath = Join-Path $folder "ic_launcher.png"
    Save-ResizedPng -Source $sourceBitmap -Size $entry.Value -Path $iconPath
}

$gradient.Dispose()
$graphics.Dispose()
$sourceBitmap.Dispose()
