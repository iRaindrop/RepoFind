Class RMeta
{
    [string]$Repo
    [string]$Folder
    [string]$FileName
    [string]$Description
    [string]$InfoBubbleText
    [string]$Authors
    [string]$DiagnosticScenario
 }

 Class RFind
{
    [string]$Repo
    [string]$Folder
    [string]$FileName
    [string]$SearchFor
    [string]$LineNum
    [string]$Context
    [bool]$Multiple
    [string]$Heading
 }

$RFresults = New-Object "System.Collections.Generic.List[RFind]"
$RFmeta = New-Object "System.Collections.Generic.List[RMeta]"
$rfDir = ""
$curDir = (Get-Item -Path ".\" -Verbose).FullName
$configFile = Join-Path -Path $curDir -ChildPath "rfconfig.xml"
$sources = New-Object 'System.Collections.Generic.List[string]'


Function Get-PropValue
{
    Param($linetxt)
    $idx = $linetxt.IndexOf("=")
    $propval = $linetxt.SubString($idx + 2)
    return $propval.TrimEnd('"')
 }
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
 if ($srchstr)
 {
     $metaOnly = $false
 }
 else {
     $metaOnly = $true
 }

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
        if ($metaOnly) {
            $content = Get-Content $file

            $inProps = $false
            $meta = New-Object "RMeta"
            $meta.Repo = "SelfHelpContent"
            $meta.FileName = [System.IO.Path]::GetFileName($file)
            $fldr = [System.IO.Path]::GetDirectoryName($file)
            $meta.Folder = Split-Path -Path $fldr -Leaf
            
            foreach ($line in $content) {
                if ($line.StartsWith("<properties")) {
                    $inProps = $true
                }
                if ($line.StartsWith("/>")) { 
                    $inProps = $false
                }
                if ($inProps) {
                    if ($line.Contains("description=")) {
                        $meta.Description = Get-PropValue $line
                    }
                    elseif ($line.Contains("infoBubbleText=")) {
                        $meta.InfoBubbleText = Get-PropValue $line
                    }
                    elseif ($line.Contains("authors=")) {
                        $meta.Authors = Get-PropValue $line
                    }
                    elseif ($line.Contains("diagnosticScenario=")) {
                        $meta.DiagnosticScenario = Get-PropValue $line
                    }                
                }
            }
            $RFmeta.Add($meta)
        }
        else {
            $ln = 1
            $filetxt = [System.IO.File]::ReadAllText($file)
            if ($filetxt.ToLower().Contains($srchstr.ToString().ToLower())) {
                $content = Get-Content $file
                foreach ($line in $content) {
                    if ($line.StartsWith("<properties")) {
                        $inProps = $true
                        $pastProps = $false
                    }
                    if ($line.StartsWith("/>")) { 
                        $inProps = $false
                        $pastProps = $true
                    }
                    
                    if ($pastProps) {
                        if ($line.ToLower().Contains($srchstr.ToString().ToLower())) {
                            $hit = New-Object "RFind"
                            $hit.Repo = "SelfHelpContent"
                            $hit.SearchFor = $srchstr
                            $hit.FileName = [System.IO.Path]::GetFileName($file)
                            $fldr = [System.IO.Path]::GetDirectoryName($file)
                            $hit.Folder = Split-Path -Path $fldr -Leaf
                            $hit.Multiple = $false
        
                            # get context, 40 chars before hit and after
                            $ix = $line.ToLower().IndexOf($srchstr.ToLower())
                            if ($ix -ge 40) {
                                $start = $ix - 40;
                                $alpha = $line.Substring($start, 40)
                            }
                            else {
                                $alpha = $line.Substring(0, $ix)
                            }
                            $slen = $srchstr.ToString().Length
                            if ($ix + $slen + 40 -ge $line.Length) {
                                $rlen = $line.Length - ($ix + $slen)
                                $omega = $line.Substring($ix + $slen, $rlen)
                            }
                            else {
                                $omega = $line.Substring($ix + $slen, 40)
                            }
                            $context = "{0}{1}{2}" -f $alpha, $srchstr, $omega
                            $hit.Context = $context
        
                            $hit.LineNum = $ln
                            $hit.Heading = $lasthead
        
                            if ($omega.Contains($srchstr)) {
                                $hit.Multiple = $true
                            }

                            $RFresults.Add($hit)
                        }
                        if ($line.StartsWith("#")) {
                            $ix = $line.ToString().IndexOf("# ")
                            $lasthead = $line.Substring($ix + 1)
                        }
                    }
                    $ln++
                }
            }
        }
    }
}

try
{
    if ($RFresults.Count -gt 0) {
        $csvFile = [System.IO.Path]::Combine($curDir, "RepoFindResults.csv")
        $RFresults | Export-Csv -Path $csvFile -NoTypeInformation
        $msg = "{0} occurences found. See RepoFindResults.csv." -f $RFresults.Count
        Write-Host $msg
    }
    elseif ($RFmeta.Count -gt 0) {
        $csvFile = [System.IO.Path]::Combine($curDir, "RepoFindMetadata.csv")
        $RFmeta | Export-Csv -Path $csvFile -NoTypeInformation
        $msg = "{0} articles processed. See RepoFindmetadata.csv." -f $RFmeta.Count
        Write-Host $msg
    }
    else {
        Write-Host "No results found."
    }
}
Catch [System.IO.IOException]
{
    Write-Host "CSV file is open, please close it."
}
