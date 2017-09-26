Class RFind
{
    [string]$URL
    [string]$Repo
    [string]$Folder
    [string]$FileName
    [string]$LineNum
    [string]$Context
    [bool]$Multiple
    [string]$Heading
 }

$RFresults = New-Object "System.Collections.Generic.List[RFind]"
$homeFolder = $HOME
$rfDir = "";
$curDir = (Get-Item -Path ".\" -Verbose).FullName
$configFile = Join-Path -Path $curDir -ChildPath "rfconfig.xml"
$sources = New-Object 'System.Collections.Generic.List[string]'
if(Test-Path $configFile)
 {
    Try
    {
        #Load config appsettings
        $config = [xml](get-content $configFile)
        $rfDir = $config.configuration.startup.installdir.Value
        foreach ($s in $config.configuration.srchFolders.folder)
        {
            $sources.Add($s.Value)
        }
    }

    Catch [system.exception]
    {
        Write-Host $_.Exception.Message
    }
 }
 else
 {
    Write-Host "Config file not valid."
 }

$srchstr = $args[0]
$lasthead = ""

Foreach ($sf in $sources)
{
    $spath = ""
    if ($rfDir -eq "")
    {
        $spath = Join-Path -Path $HOME -ChildPath $sf
        $repStart = $HOME.Length + 1
    }
    else
    {
        $spath = Join-Path -Path $rfDir -ChildPath $sf
        $repStart = $rfDir.Length + 1        
    }
    $mdPth = "{0}\*.md" -f $spath
    $repPath = $spath.Substring($repStart)

    $files = Get-ChildItem $mdPth -Recurse
    foreach ($file in $files) 
    {
        $filetxt = [System.IO.File]::ReadAllText($file)
        $ln = 1
        if ($filetxt.ToLower().Contains($srchstr.ToString().ToLower()))  
        {
            $content = Get-Content $file
            foreach($line in $content)
            {
                if($line.ToLower().Contains($srchstr.ToString().ToLower()))
                {
                    $hit = New-Object "RFind"

                    # Construct the URL to published topic
                    $idx = $repPath.IndexOf("\");
                    $repo = $repPath.Substring(0,$idx)
                    $hit.Repo = $repo
                    $ridx = $file.FullName.IndexOf($repo);
                    if ($repo -eq "sql-docs-pr")
                    {
                        $strt = $ridx + 17;
                        $urlpart = "sql"
                    }
                    elseif ($repo -eq "azure-docs-pr")
                    {
                        $strt = $ridx + 23;
                        $urlpart = "azure"
                    }
                    $urlx = $file.FullName.SubString($strt)
                    $urlx = $urlx.Replace("\","/")
                    $urlx = $urlx.TrimEnd('.','m','d')
                    $msURL = "=HYPERLINK(`"https://docs.microsoft.com/{0}/{1}`")" -f $urlPart, $urlx
                    $hit.URL = $msURL
                    
                    $hit.Multiple = $false
                    

                    # get context, 40 chars before hit and after
                    $ix = $line.IndexOf($srchstr)
                    if ($ix -ge 40)
                    {
                        $start = $ix - 40;
                        $alpha = $line.Substring($start,40)
                    }
                    else
                    {
                        $alpha = $line.Substring(0,$ix)
                    }
                    $slen = $srchstr.ToString().Length
                    if ($ix + $slen + 40 -ge $line.Length)
                    {
                        $rlen = $line.Length - ($ix + $slen)
                        $omega = $line.Substring($ix + $slen,$rlen)
                    }
                    else
                    {
                        $omega = $line.Substring($ix + $slen,40)
                    }
                    $context = "{0}{1}{2}" -f $alpha, $srchstr, $omega
                    $hit.Context = $context

                    $hit.FileName = [System.IO.Path]::GetFileName($file)
                    $fldr = [System.IO.Path]::GetDirectoryName($file)
                    $hit.Folder = Split-Path -Path $fldr -Leaf
                    $hit.LineNum = $ln
                    $hit.Heading = $lasthead

                    if ($omega.Contains($srchstr))
                    {
                        $hit.Multiple = $true
                    }
 
                    $RFresults.Add($hit)

                }
                if ($line.StartsWith("#"))
                {
                    $ix = $line.ToString().IndexOf("# ")
                    $lasthead = $line.Substring($ix + 1)
                }
                $ln++
            }
        }
    }
}

try
{
    if ($RFresults.Count -ge 0)
    {
        $csvFile = [System.IO.Path]::Combine($curDir, "RepoFindResults.csv")
        $RFresults | Export-Csv -Path $csvFile -NoTypeInformation
        $msg = "{0} occurences found. See RepoFindResults.csv." -f $RFresults.Count
        Write-Host $msg
    }
    else
    {
        Write-Host "No search results found."
    }
}
Catch [System.IO.IOException]
{
    Write-Host "RFresults.csv is open, please close it."
}

