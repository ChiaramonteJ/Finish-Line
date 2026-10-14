# Run from any directory after editing components/navbar.html or footer.html.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
foreach ($file in Get-ChildItem $root -Recurse -Filter *.html) {
    if ($file.FullName -match '\\components\\') { continue }
    $html = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($name in 'navbar','footer') {
        $fragment = (Get-Content -LiteralPath (Join-Path $root "components/$name.html") -Raw -Encoding UTF8).Trim()
        $replacement = "<!-- shared:${name}:start -->`n$fragment`n<!-- shared:${name}:end -->"
        $pattern = "(?s)<!-- shared:$name`:start -->.*?<!-- shared:$name`:end -->"
        $html = [regex]::Replace($html, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{param($m) $replacement})
    }
    Set-Content -LiteralPath $file.FullName -Value $html -Encoding UTF8 -NoNewline
}
