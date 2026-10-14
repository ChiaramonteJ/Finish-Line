# Local preview only; does not publish or change hosting.
param([int]$Port = 4173)
$root = Split-Path $PSScriptRoot -Parent
$listener = [Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Output "Preview: http://localhost:$Port/"
try {
 while ($listener.IsListening) {
  $context = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($context.Request.Url.AbsolutePath).TrimStart('/')
  $file = [IO.Path]::GetFullPath((Join-Path $root $path))
  if ($file -ne $root -and !$file.StartsWith($root + [IO.Path]::DirectorySeparatorChar)) {$context.Response.StatusCode=403;$context.Response.Close();continue}
  if (Test-Path $file -PathType Container) {$file = Join-Path $file 'index.html'}
  if (!(Test-Path $file -PathType Leaf)) {$context.Response.StatusCode=404;$file=Join-Path $root '404.html'}
  $extension = [IO.Path]::GetExtension($file)
  $mime = switch ($extension) {'.html' {'text/html; charset=utf-8'} '.css' {'text/css; charset=utf-8'} '.js' {'text/javascript; charset=utf-8'} '.jpg' {'image/jpeg'} '.jpeg' {'image/jpeg'} '.png' {'image/png'} '.svg' {'image/svg+xml'} '.xml' {'application/xml'} '.webmanifest' {'application/manifest+json'} default {'application/octet-stream'}}
  $bytes = [IO.File]::ReadAllBytes($file)
  $context.Response.ContentType=$mime
  $context.Response.ContentLength64=$bytes.Length
  try {$context.Response.OutputStream.Write($bytes,0,$bytes.Length)} catch {} finally {$context.Response.Close()}
 }
} finally {$listener.Stop();$listener.Close()}
