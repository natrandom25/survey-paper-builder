# Splits the single-file Survey Paper Builder into index.html + css/ + js/ + vendor/.
#
# Why a script rather than shipping the files directly: three of the <script> blocks are
# minified vendor libraries sitting on single lines hundreds of kilobytes long. They cannot
# be retyped, and one dropped character breaks PDF import silently. This copies them
# byte-for-byte.
#
# Run:  powershell -ExecutionPolicy Bypass -File split.ps1
# Or just double-click split.bat.
#
# Written for Windows PowerShell 5.1 — no ScriptBlock-as-MatchEvaluator, no ?? operator,
# no ternary. Those are PowerShell 7 features and 5.1 is what powershell.exe runs.

# Output goes to docs/ rather than site/ because GitHub Pages will only publish from the
# repository root or from a folder literally named /docs. Using docs/ lets the repo hold the
# build scripts and the source monolith as well, instead of only the deployed output.
param(
  [string]$Source = "Survey_Paper_Builder_with_Research_Intelligence_v12.html",
  [string]$OutDir = "docs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Source)) {
  Write-Host "Source file not found: $Source" -ForegroundColor Red
  Write-Host "Run this from the folder containing the HTML file, or pass -Source <name>."
  exit 1
}

$full = (Resolve-Path $Source).Path
$html = [System.IO.File]::ReadAllText($full)
$utf8 = New-Object System.Text.UTF8Encoding $false
Write-Host ("Read {0} ({1} MB)" -f $Source, [math]::Round($html.Length/1MB,2))

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "css") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "js") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $OutDir "vendor") | Out-Null

# ---- locate the blocks ----------------------------------------------------
$styleRx  = New-Object System.Text.RegularExpressions.Regex '(?s)<style>(.*?)</style>'
$scriptRx = New-Object System.Text.RegularExpressions.Regex '(?s)<script([^>]*)>(.*?)</script>'

$styleMatch = $styleRx.Match($html)
if (-not $styleMatch.Success) { Write-Host "No <style> block found." -ForegroundColor Red; exit 1 }

$scripts = @($scriptRx.Matches($html))
if ($scripts.Count -lt 2) {
  Write-Host ("Expected at least two <script> blocks, found {0}." -f $scripts.Count) -ForegroundColor Red
  exit 1
}
Write-Host ("Found 1 style block and {0} script blocks." -f $scripts.Count)

# ---- write the pieces -----------------------------------------------------
$css = $styleMatch.Groups[1].Value.Trim()
[System.IO.File]::WriteAllText((Join-Path $OutDir "css\styles.css"), $css, $utf8)
Write-Host ("  css/styles.css        {0} KB" -f [math]::Round($css.Length/1KB,1))

$tags = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $scripts.Count; $i++) {
  $attrs = $scripts[$i].Groups[1].Value.Trim()
  $body  = $scripts[$i].Groups[2].Value

  # The last block is the application; everything before it is vendored.
  if ($i -eq $scripts.Count - 1) {
    $rel  = "js/app.js"
    $body = $body.Trim()
  } else {
    $idMatch = [System.Text.RegularExpressions.Regex]::Match($attrs, 'id\s*=\s*["'']([^"'']+)["'']')
    if ($idMatch.Success) { $name = $idMatch.Groups[1].Value } else { $name = "lib-{0:d2}" -f ($i + 1) }
    $rel = "vendor/$name.js"
  }

  $dest = Join-Path $OutDir ($rel -replace '/','\')
  [System.IO.File]::WriteAllText($dest, $body, $utf8)
  Write-Host ("  {0,-21} {1} KB" -f $rel, [math]::Round($body.Length/1KB,1))

  if ($attrs) { $keep = " " + $attrs } else { $keep = "" }
  $tags.Add(('<script src="{0}"{1}></script>' -f $rel, $keep))
}

# ---- rebuild index.html ---------------------------------------------------
# Replace back-to-front so earlier match offsets stay valid.
$out = $html
for ($i = $scripts.Count - 1; $i -ge 0; $i--) {
  $m = $scripts[$i]
  $out = $out.Remove($m.Index, $m.Length).Insert($m.Index, $tags[$i])
}
$sm = $styleRx.Match($out)
$out = $out.Remove($sm.Index, $sm.Length).Insert($sm.Index, '<link rel="stylesheet" href="css/styles.css">')

[System.IO.File]::WriteAllText((Join-Path $OutDir "index.html"), $out, $utf8)
Write-Host ("  index.html            {0} KB" -f [math]::Round($out.Length/1KB,1))

foreach ($extra in @("README.md", ".gitignore")) {
  if (Test-Path $extra) { Copy-Item -Path $extra -Destination $OutDir -Force }
}

Write-Host ""
Write-Host ("Done. Files are in '{0}\'." -f $OutDir) -ForegroundColor Green
Write-Host "Open $OutDir\index.html and import a PDF before pushing — that is the one action"
Write-Host "that exercises all three vendor scripts, so it proves the split preserved load order."
