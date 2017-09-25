Class RFind
{
    [string]$URL
    [string]$Repo
    [string]$Folder
    [string]$FileName
    [string]$LineNum
    [string]$Context
    [bool]$Multiple
    [string]$Line
    [string]$Heading
 }

$RFresults = New-Object "System.Collections.Generic.List[RFind]"
$homeFolder = $HOME
$rfDir = "";
$curdir = (Get-Item -Path ".\" -Verbose).FullName
$configFile = Join-Path -Path $curdir -ChildPath "rfconfig.xml"
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
$outfile = Join-Path -Path $curdir -ChildPath "rfresults.txt"
$lasthead = ""

Foreach ($sf in $sources)
{
    if ($rfDir -eq "")
    {
        $spath = Join-Path -Path $HOME -ChildPath $sf
    }
    else
    {
        $spath = Join-Path -Path $rfDir -ChildPath $sf        
    }
    $mdPth = "{0}\*.md" -f $spath
    $files = Get-ChildItem $mdPth -Recurse
    foreach ($file in $files) 
    {
        $filetxt = [System.IO.File]::ReadAllText($file)
        $ln = 1
        if ($filetxt.Contains($srchstr))  
        {
            $content = Get-Content $file
            foreach($line in $content)
            {
                if($line.Contains($srchstr))
                {
                    $entry = "{0}`t{1}`t{2}`t{3}" -f $file,$ln,$line,$lasthead
                    $hit = New-Object "RFind"
  
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
                    if ($ix + $slen + 40 -gt $line.Length)
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
                    $hit.Folder = [System.IO.Path]::GetDirectoryName($file)
                    $hit.Line = $line
                    $hit.LineNum = $ln
                    $idx = $sf.IndexOf("\")
                    $hit.Repo = $sf.Substring(0,$idx -1)
                    $hit.URL = "MEOW"

                    $RFresults.Add($hit)

                    # Add-Content $outfile -Value $entry
                }
                if ($line.StartsWith("#"))
                {
                    $ix = $line.IndexOf(" #")
                    $lasthead = $line.Substring($ix + 1)
                }
                $ln++
            }
        }
    }
}

$RFresults | Export-Csv -Path c:\meowmeta\meow.csv -NoTypeInformation










