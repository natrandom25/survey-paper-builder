# Rebuilds the single-file version from the split sources.
#
# Once you split, the parts become the source of truth and the single file becomes a build
# output. Without this script you maintain the same program twice and they drift silently —
# a fix in one never reaches the other.
#
# Run:  powershell -ExecutionPolicy Bypass -File build.ps1
# Or just double-click build.bat.
#
# Windows PowerShell 5.1 compatible.

param(
  [string]$SiteDir = "docs",
  [string]$Output  = "Survey_Paper_Builder_single_file.html"
)

$ErrorActionPreference = "Stop"

$indexPath = Join-Path $SiteDir "index.html"
if (-not (Test-Path $indexPath)) {
  Write-Host "Not found: $indexPath" -ForegroundColor Red
  Write-Host "Run split.ps1 first."
  exit 1
}

$html = [System.IO.File]::ReadAllText((Resolve-Path $indexPath).Path)
$utf8 = New-Object System.Text.UTF8Encoding $false

# ---- inline every external script, back to front --------------------------
$srcRx = New-Object System.Text.RegularExpressions.Regex '<script\s+src="([^"]+)"([^>]*)></script>'
$hits = @($srcRx.Matches($html))
for ($i = $hits.Count - 1; $i -ge 0; $i--) {
  $m = $hits[$i]
  $p = Join-Path $SiteDir ($m.Groups[1].Value -replace '/','\')
  if (-not (Test-Path $p)) { Write-Host "Missing script: $p" -ForegroundColor Red; exit 1 }
  $body = [System.IO.File]::ReadAllText((Resolve-Path $p).Path)

  # A literal </script> inside a JS string is harmless in an external file but terminates the
  # tag once inlined. The SVG instruction block in app.js contains one, so this is live.
  $body = $body.Replace('</script>', '<\/script>')

  $tag = "<script" + $m.Groups[2].Value + ">`r`n" + $body + "`r`n</script>"
  $html = $html.Remove($m.Index, $m.Length).Insert($m.Index, $tag)
  Write-Host ("  inlined {0}" -f $m.Groups[1].Value)
}

# ---- inline the stylesheet ------------------------------------------------
$linkRx = New-Object System.Text.RegularExpressions.Regex '<link\s+rel="stylesheet"\s+href="([^"]+)"\s*/?>'
$lm = $linkRx.Match($html)
if ($lm.Success) {
  $p = Join-Path $SiteDir ($lm.Groups[1].Value -replace '/','\')
  if (-not (Test-Path $p)) { Write-Host "Missing stylesheet: $p" -ForegroundColor Red; exit 1 }
  $css = [System.IO.File]::ReadAllText((Resolve-Path $p).Path)
  $block = "<style>`r`n" + $css + "`r`n</style>"
  $html = $html.Remove($lm.Index, $lm.Length).Insert($lm.Index, $block)
  Write-Host ("  inlined {0}" -f $lm.Groups[1].Value)
}

[System.IO.File]::WriteAllText($Output, $html, $utf8)
Write-Host ""
Write-Host ("Wrote {0} ({1} MB)" -f $Output, [math]::Round($html.Length/1MB,2)) -ForegroundColor Green
Write-Host "Open it and import a PDF to confirm the vendor scripts inlined correctly."
