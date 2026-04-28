$file = 'c:\feb1\dec_02\lib\views\admin_dashboard.dart'
$lines = [System.IO.File]::ReadAllLines($file)
$out = [System.Collections.Generic.List[string]]::new()

for ($i = 0; $i -lt $lines.Count; $i++) {
  # Fix: line 2035 is the closing '{' of the if, insert missing ScaffoldMessenger line after it
  if ($i -eq 2035) {
    $out.Add($lines[$i])
    $out.Add('      ScaffoldMessenger.of(context).showSnackBar(')
    continue
  }
  $out.Add($lines[$i])
}

[System.IO.File]::WriteAllLines($file, $out)
Write-Host 'Fix done'
