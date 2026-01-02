# PowerShell script to generate REAL icons from TTF
Add-Type -AssemblyName System.Drawing

$baseDir = "D:\workspace\github\uniapp-components\uniapp-components\neo-beauty-template"
$iconDir = "$baseDir\static\icons"
$shejiDir = "$baseDir\sheji"
$fontPath = "$baseDir\static\fonts\MaterialSymbolsOutlined.ttf"
$codepointsPath = "$baseDir\static\fonts\MaterialSymbolsOutlined.codepoints"

# Ensure directories exist
if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Force -Path $iconDir | Out-Null }

# 1. Load Codepoints into Hash
$codepoints = @{}
if (Test-Path $codepointsPath) {
    Get-Content $codepointsPath | ForEach-Object {
        $parts = $_.Split(' ')
        if ($parts.Count -ge 2) {
            $name = $parts[0]
            $code = $parts[1]
            $codepoints[$name] = [int]"0x$code"
        }
    }
} else {
    Write-Error "Codepoints file not found!"
    exit 1
}

# 2. Load Custom Font
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($fontPath)
$fontFamily = $pfc.Families[0]

function Generate-Icon {
    param (
        [string]$IconName,
        [string]$ColorHex,
        [string]$OutputPath,
        [int]$Size = 80,
        [switch]$Force
    )

    if (-not $Force -and (Test-Path $OutputPath)) {
        # Write-Host "Skipping $IconName (Already exists)" -ForegroundColor Gray
        return
    }

    if (-not $codepoints.ContainsKey($IconName)) {
        Write-Warning "Icon '$IconName' not found in codepoints."
        return
    }

    $unicodeVal = $codepoints[$IconName]
    $charStr = [char]$unicodeVal

    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $graph = [System.Drawing.Graphics]::FromImage($bmp)
    $graph.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $graph.Clear([System.Drawing.Color]::Transparent)

    $brushColor = [System.Drawing.ColorTranslator]::FromHtml($ColorHex)
    $brush = New-Object System.Drawing.SolidBrush $brushColor

    # Adjust font size to fit. Usually 0.8 * box size for icon fonts is good.
    $emSize = [float]($Size * 0.8)
    $unit = [System.Drawing.GraphicsUnit]::Pixel
    $font = New-Object System.Drawing.Font($fontFamily, $emSize, $unit)

    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center

    $rect = New-Object System.Drawing.RectangleF 0, 0, $Size, $Size
    # Offset Y slightly if needed, but Center/Center usually works for Material Icons
    $graph.DrawString($charStr, $font, $brush, $rect, $format)

    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graph.Dispose()
    $bmp.Dispose()
    $brush.Dispose()
    $font.Dispose()
    
    Write-Host "Generated $OutputPath ($IconName)"
}

# 3. Scan for icons in HTML
$foundIcons = @{}
$files = Get-ChildItem -Path $shejiDir -Recurse -Filter *.html
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    # Regex to find material symbols. Simplified regex.
    # Pattern: class="...material-symbols-outlined..." ... > icon_name </span>
    # We look for the class, then capture content between > and <
    
    $matches = [regex]::Matches($content, 'material-symbols-outlined[^\"]*">([^<]+)</span>')
    foreach ($match in $matches) {
        $iconName = $match.Groups[1].Value.Trim()
        # Remove any surrounding whitespace or newlines
        $iconName = $iconName -replace '\s+', ''
        if (-not [string]::IsNullOrWhiteSpace($iconName)) {
            $foundIcons[$iconName] = $true
        }
    }
}

# 4. Generate Standard Icons (Black/Default)
foreach ($icon in $foundIcons.Keys) {
    Generate-Icon -IconName $icon -ColorHex "#333333" -OutputPath "$iconDir\$icon.png"
}

# 5. Generate Tabbar Icons (Specific)
# Home -> spa
Generate-Icon -IconName "spa" -ColorHex "#E29578" -OutputPath "$iconDir\home_active.png"
Generate-Icon -IconName "spa" -ColorHex "#999999" -OutputPath "$iconDir\home_inactive.png"

# Booking -> calendar_month
Generate-Icon -IconName "calendar_month" -ColorHex "#E29578" -OutputPath "$iconDir\calendar_active.png"
Generate-Icon -IconName "calendar_month" -ColorHex "#999999" -OutputPath "$iconDir\calendar_inactive.png"

# User -> person
Generate-Icon -IconName "person" -ColorHex "#E29578" -OutputPath "$iconDir\user_active.png"
Generate-Icon -IconName "person" -ColorHex "#999999" -OutputPath "$iconDir\user_inactive.png"

Write-Host "Real Icon generation complete."
