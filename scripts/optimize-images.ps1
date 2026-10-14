# Generate responsive JPEG assets with built-in Windows imaging. Originals stay untouched.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$names = @('concrete-driveway-plainwell-mi.jpeg','stamped-colored-concrete-patio-deltion-mi.jpeg','concrete-slab-kalamazoo-mi.jpeg','site-excavation-grand-rapids-mi.jpg','site-clearing-stump-removal-allegan-mi.jpeg','site-clearing-allegan-mi.jpeg','drainage-culvert-under-driveway-allegan-mi.jpeg')
$dest = Join-Path $root 'images/projects/optimized'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
foreach ($name in $names) {
 $image = [System.Drawing.Image]::FromFile((Join-Path $root "images/projects/$name"))
 try {
  if ($image.PropertyIdList -contains 274) {
   $orientation = [BitConverter]::ToUInt16($image.GetPropertyItem(274).Value,0)
   switch ($orientation) { 2 {$image.RotateFlip(4)} 3 {$image.RotateFlip(2)} 4 {$image.RotateFlip(6)} 5 {$image.RotateFlip(5)} 6 {$image.RotateFlip(1)} 7 {$image.RotateFlip(7)} 8 {$image.RotateFlip(3)} }
  }
  $stem = [IO.Path]::GetFileNameWithoutExtension($name).Replace('deltion','delton')
  foreach ($width in 480,960,1440) {
   if ($width -gt $image.Width) { continue }
   $height = [int][Math]::Round($image.Height * $width / $image.Width)
   $bitmap = New-Object System.Drawing.Bitmap($width,$height)
   $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
   try {
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($image,0,0,$width,$height)
    $parameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $parameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]80)
    $bitmap.Save((Join-Path $dest "$stem-$width.jpg"),$jpeg,$parameters)
    $parameters.Dispose()
   } finally { $graphics.Dispose(); $bitmap.Dispose() }
  }
 } finally { $image.Dispose() }
}
