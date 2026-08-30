param([string]$inPath, [string]$outPath)
$xml = [xml](Get-Content $inPath -Raw -Encoding UTF8)
$nsmgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$nsmgr.AddNamespace("w","http://schemas.openxmlformats.org/wordprocessingml/2006/main")
$paragraphs = $xml.SelectNodes("//w:p", $nsmgr)
$out = @()
foreach($p in $paragraphs){
    $texts = $p.SelectNodes(".//w:t", $nsmgr)
    $line = ""
    foreach($t in $texts){ $line += $t.InnerText }
    $out += $line
}
($out -join "`n") | Out-File -FilePath $outPath -Encoding UTF8
Write-Host "Extracted $($out.Count) paragraphs to $outPath"
