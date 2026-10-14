param([int]$DebugPort=9223)
$ErrorActionPreference='Stop'
$target=(Invoke-RestMethod "http://localhost:$DebugPort/json/list") | Where-Object url -eq 'about:blank' | Select-Object -First 1
if(!$target){$target=(Invoke-RestMethod "http://localhost:$DebugPort/json/list") | Where-Object url -like 'http://localhost:4173/*' | Select-Object -First 1}
$socket=[Net.WebSockets.ClientWebSocket]::new()
$null=$socket.ConnectAsync([uri]$target.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
$script:messageId=0
function Cdp($method,$parameters=@{}){
 $script:messageId++
 $request=@{id=$script:messageId;method=$method;params=$parameters}|ConvertTo-Json -Depth 12 -Compress
 $bytes=[Text.Encoding]::UTF8.GetBytes($request)
 $null=$socket.SendAsync([ArraySegment[byte]]::new($bytes),[Net.WebSockets.WebSocketMessageType]::Text,$true,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
 do{
  $stream=[IO.MemoryStream]::new()
  do{$buffer=New-Object byte[] 65536;$received=$socket.ReceiveAsync([ArraySegment[byte]]::new($buffer),[Threading.CancellationToken]::None).GetAwaiter().GetResult();$stream.Write($buffer,0,$received.Count)}while(!$received.EndOfMessage)
  $message=[Text.Encoding]::UTF8.GetString($stream.ToArray())|ConvertFrom-Json;$stream.Dispose()
 }while($message.id -ne $script:messageId)
 if($message.error){throw ($message.error|ConvertTo-Json)}
 return $message.result
}
function Evaluate($expression){$response=Cdp 'Runtime.evaluate' @{expression=$expression;returnByValue=$true;awaitPromise=$true};if($response.exceptionDetails){throw ($response.exceptionDetails|ConvertTo-Json -Depth 5)};$response.result.value}
$null=Cdp 'Page.enable'
$results=@()
[xml]$sitemap=Get-Content (Join-Path (Split-Path $PSScriptRoot -Parent) 'sitemap.xml') -Raw
foreach($width in 375,768,1440){
 $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=$width;height=900;deviceScaleFactor=1;mobile=$false}
 foreach($url in $sitemap.urlset.url.loc){
  $path=([uri]$url).AbsolutePath
  $null=Cdp 'Page.navigate' @{url="http://localhost:4173$path"}
  Start-Sleep -Milliseconds 400
  $probe=Evaluate @"
(async()=>{await new Promise(r=>setTimeout(r,350));const toggle=document.querySelector('.menu-toggle'),menu=document.querySelector('#primary-menu');let menuOK=true;if(innerWidth<1100){toggle.click();menuOK=getComputedStyle(menu).display!=='none'&&toggle.getAttribute('aria-expanded')==='true';document.dispatchEvent(new KeyboardEvent('keydown',{key:'Escape'}));menuOK=menuOK&&getComputedStyle(menu).display==='none'&&document.activeElement===toggle;}const faq=document.querySelector('details.faq-item');if(faq){faq.querySelector('summary').click();menuOK=menuOK&&faq.open;faq.open=false;}return {path:location.pathname,width:innerWidth,scrollWidth:document.documentElement.scrollWidth,overflow:document.documentElement.scrollWidth>document.documentElement.clientWidth+1,menuOK,bootstrap:[...document.querySelectorAll('.row')].every(e=>getComputedStyle(e).display==='flex'),main:document.querySelectorAll('main').length,h1:document.querySelectorAll('h1').length,brokenImages:[...document.images].filter(i=>i.complete&&!i.naturalWidth).map(i=>i.src)};})()
"@
  $results+=$probe; Write-Output ("Checked "+$width+" "+$path)
  if($probe.overflow -or !$probe.menuOK -or !$probe.bootstrap -or $probe.main -ne 1 -or $probe.h1 -ne 1 -or $probe.brokenImages.Count){Write-Output ('FAIL '+($probe|ConvertTo-Json -Compress))}
 }
}
$results|ConvertTo-Json -Depth 6|Set-Content (Join-Path $env:TEMP 'finishline-browser-results.json') -Encoding UTF8
foreach($shot in @(@('desktop',1440,'/'),@('mobile',375,'/'),@('contact',375,'/contact/'),@('gallery',768,'/projects/concrete-projects/'))){
 $null=Cdp 'Emulation.setDeviceMetricsOverride' @{width=[int]$shot[1];height=1000;deviceScaleFactor=1;mobile=$false}
 $null=Cdp 'Page.navigate' @{url=('http://localhost:4173'+$shot[2])};Start-Sleep -Milliseconds 700
 $capture=Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$false}
 [IO.File]::WriteAllBytes((Join-Path $env:TEMP ('finishline-'+$shot[0]+'.png')),[Convert]::FromBase64String($capture.data))
}
$null=Cdp 'Emulation.setScriptExecutionDisabled' @{value=$true}
$null=Cdp 'Page.navigate' @{url='http://localhost:4173/'};Start-Sleep -Milliseconds 500
$fallback=Evaluate "({nav:!!document.querySelector('.site-nav'),menuVisible:getComputedStyle(document.querySelector('#primary-menu')).display!=='none',footer:!!document.querySelector('footer')})"
Write-Output ('No-JS fallback: '+($fallback|ConvertTo-Json -Compress))
$null=Cdp 'Emulation.setScriptExecutionDisabled' @{value=$false}
$failed=@($results|Where-Object {$_.overflow -or !$_.menuOK -or !$_.bootstrap -or $_.main -ne 1 -or $_.h1 -ne 1 -or $_.brokenImages.Count})
Write-Output "Browser checks: $($results.Count) page/viewport combinations; $($failed.Count) failures. Screenshots and JSON are in TEMP."
$socket.Dispose()
if($failed.Count -or !$fallback.menuVisible){throw 'Browser smoke checks failed'}
