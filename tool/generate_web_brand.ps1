$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$dir = Join-Path (Split-Path $PSScriptRoot -Parent) 'web/icons'
function Brush($hex) { [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex)) }
function Polygon($g,$brush,$coords) {
 $points = for($i=0;$i -lt $coords.Count;$i+=2) { [System.Drawing.PointF]::new($coords[$i],$coords[$i+1]) }
 $g.FillPolygon($brush,[System.Drawing.PointF[]]$points)
}
$bitmap = [System.Drawing.Bitmap]::new(1024,1024)
$g = [System.Drawing.Graphics]::FromImage($bitmap)
$g.SmoothingMode = 'AntiAlias'
$bg = [System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.Rectangle]::new(0,0,1024,1024),[System.Drawing.ColorTranslator]::FromHtml('#0C2923'),[System.Drawing.ColorTranslator]::FromHtml('#24765B'),45)
$g.FillRectangle($bg,0,0,1024,1024)
$ring = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(24,205,239,211),2)
$g.DrawEllipse($ring,86,86,852,852)
$g.DrawEllipse($ring,119,119,786,786)
$ivory = Brush '#F4F3DF'
$mint = Brush '#A7D8BB'
$gold = Brush '#DCC78B'
Polygon $g $ivory @(260,564,492,623,492,754,260,690)
Polygon $g $mint @(532,623,764,564,764,690,532,754)
Polygon $g $mint @(350,420,512,486,674,420,674,503,512,568,350,503)
Polygon $g $ivory @(220,368,512,258,804,368,512,478)
$pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#DCC78B'),18)
$pen.EndCap = 'Round'
$g.DrawLine($pen,776,386,776,506)
$g.FillEllipse($gold,761,496,30,30)
$g.Dispose()
foreach($size in @(32,180,192,512,1024)) {
 $out = [System.Drawing.Bitmap]::new($size,$size)
 $canvas = [System.Drawing.Graphics]::FromImage($out)
 $canvas.InterpolationMode = 'HighQualityBicubic'
 $canvas.DrawImage($bitmap,0,0,$size,$size)
 $out.Save((Join-Path $dir "campus-$size.png"),[System.Drawing.Imaging.ImageFormat]::Png)
 $canvas.Dispose(); $out.Dispose()
}
$bitmap.Dispose(); $bg.Dispose(); $ring.Dispose(); $ivory.Dispose(); $mint.Dispose(); $gold.Dispose(); $pen.Dispose()
