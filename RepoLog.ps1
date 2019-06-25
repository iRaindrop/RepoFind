$logPath = "C:\Logs"
$repoTop = "c:\Repos\SelfhelpContent"

$sources = New-Object 'System.Collections.Generic.List[string]'
$sources.Add("C:\Repos\SelfHelpContent\articles\microsoft.virtualmachine.rca.restarts")
$sources.Add("C:\Repos\SelfHelpContent\articles\microsoft.virtualmachines.rca.tdp")

Set-Location $repoTop
Foreach ($dir in $sources) {
    $mdPth = "{0}\*.md" -f $dir
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

