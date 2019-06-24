$sources = New-Object 'System.Collections.Generic.List[string]'
$sources.Add("microsoft.virtualmachines.rca.tdp")
$sources.Add("microsoft.virtualmachine.rca.restarts")

$repoPath = "C:\Repos\SelfHelpContent\articles"
$logPath = "C:\Logs"
Set-Location $repoPath
Foreach ($dir in $sources) {
    $fullPath = Join-Path -Path $repoPath -ChildPath $dir
    $mdPth = "{0}\*.md" -f $fullPath
    $files = Get-ChildItem $mdPth -Recurse
 
    foreach ($file in $files) {
        $mdFile = [System.IO.Path]::GetFileName($file)
        $fName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $fullPath = [IO.Path]::Combine($repoPath, $dir, $mdFile)
        $logName = "{0}\{1}.txt" -f $logPath, $fName
        git log -- $fullPath > $logName
    }
}
Set-Location $logPath
