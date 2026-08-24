# Génère l'icône de l'app (1024x1024) : ciel bleu + soleil + lettre fur ŋ.
# Usage : powershell -File assets_dev/make_icon.ps1
Add-Type -AssemblyName System.Drawing

function New-Icon([string]$path, [bool]$transparent, [double]$scale) {
    $size = 1024
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

    if (-not $transparent) {
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point(0, 0)),
            (New-Object System.Drawing.Point(0, $size)),
            [System.Drawing.Color]::FromArgb(255, 63, 169, 245),
            [System.Drawing.Color]::FromArgb(255, 125, 201, 250))
        $g.FillRectangle($bgBrush, 0, 0, $size, $size)
        $bgBrush.Dispose()
    }

    $cx = $size / 2.0
    $cy = $size / 2.0
    $sunR = 300.0 * $scale
    $rayIn = 340.0 * $scale
    $rayOut = 440.0 * $scale
    $rayW = [single](46.0 * $scale)

    $rayPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 193, 7), $rayW)
    $rayPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $rayPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    for ($i = 0; $i -lt 12; $i++) {
        $angle = $i * [math]::PI / 6.0
        $x1 = $cx + [math]::Cos($angle) * $rayIn
        $y1 = $cy + [math]::Sin($angle) * $rayIn
        $x2 = $cx + [math]::Cos($angle) * $rayOut
        $y2 = $cy + [math]::Sin($angle) * $rayOut
        $g.DrawLine($rayPen, [single]$x1, [single]$y1, [single]$x2, [single]$y2)
    }
    $rayPen.Dispose()

    $sunBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 193, 7))
    $g.FillEllipse($sunBrush, [single]($cx - $sunR), [single]($cy - $sunR), [single](2 * $sunR), [single](2 * $sunR))
    $sunBrush.Dispose()

    $inner = $sunR * 0.86
    $innerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 214, 64))
    $g.FillEllipse($innerBrush, [single]($cx - $inner), [single]($cy - $inner), [single](2 * $inner), [single](2 * $inner))
    $innerBrush.Dispose()

    $font = New-Object System.Drawing.Font('Arial', [single](300 * $scale), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 43, 58, 74))
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString([string][char]0x014B, $font, $textBrush, (New-Object System.Drawing.PointF([single]$cx, [single]($cy - 20 * $scale))), $format)
    $font.Dispose(); $textBrush.Dispose(); $format.Dispose()

    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Output "OK $path"
}

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Icon (Join-Path $dir 'icon.png') $false 1.0
New-Icon (Join-Path $dir 'icon_fg.png') $true 0.62
