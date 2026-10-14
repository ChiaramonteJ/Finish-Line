# Dependency-free static validation for this GitHub Pages repository.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$base = 'https://finishline-concrete.com'
$issues = [Collections.Generic.List[string]]::new()
$pages = @{}
$titles = @{}; $headings = @{}; $descriptions = @{}
$indexable = [Collections.Generic.List[string]]::new()
function Fail($file,$message) { $issues.Add("${file}: $message") }
function Attr($tag,$name) { [regex]::Match($tag, ('\b'+$name+'="([^"]*)"')).Groups[1].Value }
foreach ($file in Get-ChildItem $root -Recurse -Filter *.html | Where-Object FullName -NotMatch '\\components\\') {
 $relative = $file.FullName.Substring($root.Length+1).Replace('\','/')
 $html = Get-Content $file.FullName -Raw -Encoding UTF8
 $path = '/' + $relative.Replace('index.html','')
 $pages[$path] = $html
 $title = [regex]::Match($html,'<title>(.*?)</title>').Groups[1].Value
 if (!$title) {Fail $relative 'Missing title'}
 $redirect = $relative -like '*concrete-pojects*'
 if ($redirect) {if($html -notmatch 'noindex') {Fail $relative 'Redirect must be noindex'};continue}
 $h1 = [regex]::Matches($html,'(?s)<h1\b[^>]*>(.*?)</h1>')
 if($h1.Count -ne 1){Fail $relative "Expected one H1, found $($h1.Count)"}
 if([regex]::Matches($html,'<main\b').Count -ne 1){Fail $relative 'Expected one main landmark'}
 foreach($field in @(@($titles,$title,'title'),@($headings,$h1[0].Groups[1].Value,'H1'),@($descriptions,[regex]::Match($html,'<meta name="description" content="([^"]+)"').Groups[1].Value,'description'))) {
  if(!$field[1]){Fail $relative "Missing $($field[2])"} elseif($field[0].ContainsKey($field[1])){Fail $relative "Duplicate $($field[2]) with $($field[0][$field[1]])"}else{$field[0][$field[1]]=$relative}
 }
 $canonical=[regex]::Matches($html,'<link rel="canonical" href="([^"]+)"')
 if($canonical.Count -ne 1 -or $canonical[0].Groups[1].Value -ne "$base$path"){Fail $relative 'Canonical does not match file URL'}
 if($html -notmatch 'name="robots" content="noindex'){$indexable.Add("$base$path")}
 foreach($tag in 'og:title','og:description','og:url','og:image','twitter:card'){if($html -notmatch ('(?:property|name)="'+$tag+'"')){Fail $relative "Missing $tag"}}
 foreach($json in [regex]::Matches($html,'(?s)<script type="application/ld\+json">(.*?)</script>')){try{$null=$json.Groups[1].Value|ConvertFrom-Json}catch{Fail $relative 'Invalid JSON-LD'}}
 if($html -match 'ConcreteContractor|"FAQPage"'){Fail $relative 'Disallowed schema type'}
 foreach($name in 'navbar','footer'){
  $fragment=(Get-Content (Join-Path $root "components/$name.html") -Raw -Encoding UTF8).Trim()
  $actual=[regex]::Match($html,"(?s)<!-- shared:$name`:start -->\s*(.*?)\s*<!-- shared:$name`:end -->").Groups[1].Value.Trim()
  if($actual -ne $fragment){Fail $relative "Shared $name differs from source"}
 }
 $ids=@{}
 foreach($id in [regex]::Matches($html,'\bid="([^"]+)"')){if($ids.ContainsKey($id.Groups[1].Value)){Fail $relative "Duplicate id $($id.Groups[1].Value)"};$ids[$id.Groups[1].Value]=$true}
 foreach($img in [regex]::Matches($html,'(?s)<img\s[^>]+>')){
  foreach($attr in 'alt','width','height'){if($img.Value -notmatch ('\b'+$attr+'="')){Fail $relative "Image missing $attr"}}
  if((Attr $img.Value 'src') -like '*projects*' -and $img.Value -notmatch 'loading="'){Fail $relative 'Project image lacks loading hint'}
  foreach($candidate in (Attr $img.Value 'srcset').Split(',')){if($candidate.Trim()){ $asset=$candidate.Trim().Split(' ')[0];if(!(Test-Path (Join-Path $root $asset.TrimStart('/')))){Fail $relative "Missing srcset asset $asset"}}}
 }
 # Check explicit tag nesting, excluding comments/scripts/styles and HTML void elements.
 $clean=[regex]::Replace($html,'(?s)<!--.*?-->|<script\b.*?</script>|<style\b.*?</style>','')
 $stack=[Collections.Generic.List[string]]::new()
 foreach($tag in [regex]::Matches($clean,'<(/?)([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>')){
  $name=$tag.Groups[2].Value.ToLower()
  if($name -in @('area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr')){continue}
  if($tag.Groups[1].Value -eq '/'){
   if(!$stack.Count -or $stack[$stack.Count-1] -ne $name){Fail $relative "Unmatched closing $name";break}
   $stack.RemoveAt($stack.Count-1)
  }else{$stack.Add($name)}
 }
 if($stack.Count){Fail $relative "Unclosed tags: $($stack -join ',')"}
 $level=0
 foreach($heading in [regex]::Matches([regex]::Match($html,'(?s)<main\b.*?</main>').Value,'<h([1-6])\b')){$next=[int]$heading.Groups[1].Value;if($next -gt $level+1){Fail $relative "Skipped heading level H$level to H$next"};$level=$next}
}
$linkCount=0
foreach($entry in $pages.GetEnumerator()){
 foreach($tag in [regex]::Matches($entry.Value,'<(?:a|img|script|link)\b[^>]*>')){
  $url=Attr $tag.Value 'href';if(!$url){$url=Attr $tag.Value 'src'}
  if(!$url -or $url -match '^(?:tel:|sms:|mailto:|https?://|//|data:)'){continue}
  $linkCount++
  $bits=$url.Split('#',2);$path=$bits[0].Split('?')[0]
  if(!$path){$target=$entry.Key}elseif($path.StartsWith('/')){$target=$path}else{$target=$entry.Key.Substring(0,$entry.Key.LastIndexOf('/')+1)+$path}
  $disk=Join-Path $root $target.TrimStart('/')
  if(Test-Path $disk -PathType Container){$disk=Join-Path $disk 'index.html'}
  if(!(Test-Path $disk)){Fail $entry.Key "Missing local reference $url";continue}
  if($bits.Count -gt 1 -and $bits[1]){$targetHtml=Get-Content $disk -Raw -Encoding UTF8;if($targetHtml -notmatch ('\bid="'+[regex]::Escape($bits[1])+'"')){Fail $entry.Key "Missing fragment $url"}}
 }
}
[xml]$sitemap=Get-Content (Join-Path $root 'sitemap.xml') -Raw
$locations=@($sitemap.urlset.url | ForEach-Object {$_.loc})
foreach($url in $locations){if($url -notin $indexable){Fail 'sitemap.xml' "Unexpected URL $url"}}
foreach($url in $indexable){if($url -notin $locations){Fail 'sitemap.xml' "Missing URL $url"}}
if(($locations | Select-Object -Unique).Count -ne $locations.Count){Fail 'sitemap.xml' 'Duplicate entries'}
$manifest=Get-Content (Join-Path $root 'images/favicon/site.webmanifest') -Raw | ConvertFrom-Json
foreach($icon in $manifest.icons){if(!(Test-Path (Join-Path $root $icon.src.TrimStart('/')))){Fail 'site.webmanifest' "Missing icon $($icon.src)"}}
if($issues.Count){$issues | ForEach-Object {Write-Output "FAIL $_"};throw "$($issues.Count) validation failures"}
Write-Output "PASS: $($pages.Count) pages; $($indexable.Count) indexable URLs; $linkCount local references; metadata, headings, landmarks, nesting, JSON-LD, sitemap, manifest and shared components."
