Class RData {
    [string]$Repo
    [string]$Folder
    [string]$FileName
    [string]$Date
    [string]$ArticleId
    [string]$IssueDescription
    [string]$Description
    [string]$Heading1
    [string]$Para1
    [string]$FirstH2

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
$RFdata = New-Object "System.Collections.Generic.List[RData]"
$rfDir = ""
$curDir = (Get-Item -Path ".\" -Verbose).FullName
$configFile = Join-Path -Path $curDir -ChildPath "rfconfig.xml"
$sources = New-Object 'System.Collections.Generic.List[string]'
$sb = [System.Text.StringBuilder]::new()

if (Test-Path $configFile) {
    Try {
        #Load config appsettings
        $config = [xml](get-content $configFile)
        $rfDir = $config.configuration.startup.installdir.Value
        $logDir = $config.configuration.startup.logfiledir.Value
        foreach ($s in $config.configuration.srchFolders.folder) {
            $sources.Add($s.Value)
        }
    }

    Catch [system.exception] {
        Write-Host $_.Exception.Message
    }
}
else {
    Write-Host "Config file not valid."
}


Function Get-PropValue {
    Param($linetxt)
    $idx = $linetxt.IndexOf("=")
    $propval = $linetxt.SubString($idx + 2)
    return $propval.TrimEnd('"')
}

Function Get-DateFromLog {
    Param($mdFileName)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($mdFileName)
    $logFileName = "{0}\{1}.txt" -f $logDir, $baseName    
    if (Test-Path -Path $logFileName) {
        $mdLines = Get-Content -Path $logFileName
        $dateTxt = $mdLines[2].Substring(5).Trim()
        $dtParts = $dateTxt.Split(' ');
        $mNum = Get-MonthNumber($dtParts[1])
        $dtVal = "{0}/{1}/{2}" -f $mNum, $dtParts[2], $dtParts[4]
        return $dtVal
    }
}

Function Get-MonthNumber {
    Param($month)
    $mo = $month.ToLower()
    if ($mo -eq "jan") {
        $monthNum = "01"
    }
    elseif ($mo -eq "feb") {
        $monthNum = "02"
    }
    elseif ($mo -eq "mar") {
        $monthNum = "03"
    }    
    elseif ($mo -eq "apr") {
        $monthNum = "04"
    }    
    elseif ($mo -eq "may") {
        $monthNum = "05"
    }    
    elseif ($mo -eq "jun") {
        $monthNum = "06"
    }    
    elseif ($mo -eq "jul") {
        $monthNum = "07"
    }    
    elseif ($mo -eq "aug") {
        $monthNum = "08"
    }    
    elseif ($mo -eq "sep") {
        $monthNum = "09"
    }    
    elseif ($mo -eq "oct") {
        $monthNum = "10"
    }    
    elseif ($mo -eq "nov") {
        $monthNum = "11"
    }    
    elseif ($mo -eq "dec") {
        $monthNum = "12"
    }
    return $monthNum
}




$srchstr = $args[0]

if ($srchstr) {
    $dataOnly = $false
}
else {
    $dataOnly = $true
}

$lasthead = ""


Foreach ($sf in $sources) {
    $spath = ""
    if ($rfDir -eq "") {
        $spath = Join-Path -Path $HOME -ChildPath $sf
    }
    else {
        $spath = Join-Path -Path $rfDir -ChildPath $sf      
    }
    $mdPth = "{0}\*.md" -f $spath


    $files = Get-ChildItem $mdPth -Recurse
    foreach ($file in $files) {
        if ($dataOnly) {
            $content = Get-Content $file
            $inProps = $false
            $data = New-Object "RData"
            $data.Date = Get-DateFromLog $file
            $data.FileName = [System.IO.Path]::GetFileName($file)
            $fldr = [System.IO.Path]::GetDirectoryName($file)
            $dirs = $fldr.Split('\')
            $data.Repo = $dirs[2]
            $data.Folder = Split-Path -Path $fldr -Leaf
            $lnum = 0
            $bodyParas = New-Object System.Collections.Generic.List[string]
            foreach ($line in $content) {
                if ($line.StartsWith("<properties")) {
                    $inProps = $true
                }
                if ($line.StartsWith("/>")) { 
                    $inProps = $false
                    $bodyStart = $lnum
                }
                if ($inProps) {
                    if ($line.Contains("description=")) {
                        $data.Description = Get-PropValue $line
                    }
                    elseif ($line.Contains("articleId=")) {
                        $data.ArticleId = Get-PropValue $line
                    }               
                }
                else {
                    if ($lnum -gt $bodyStart -and $line.Length -gt 1) {
                        $bodyParas.Add($line)
                    }
                    $lnum++
                }
            }
            $bodyLn = 0
    
            $gotPara1 = $false
            $gotH2 = $false
            foreach ($p in $bodyParas) {
                if ($p.StartsWith("# ")) {
                    $data.Heading1 = $p                        
                }
                elseif ($p.StartsWith("<!--issueDescription-->")) {
                    $issueLn = $bodyLn + 1
                    $data.IssueDescription = $bodyParas[$bodyLn + 1]
                }
                elseif ($p.StartsWith("## ") -and $gotH2 -eq $false) {
                    $data.FirstH2 = $p
                    $gotH2 = $true
                }
                else {
                    if ($gotPara1 -eq $false -and $bodyLn -gt $issueLn + 2) {
                        if (!$p.StartsWith("#")) {
                            $data.Para1 = $p
                            $GotPara1 = $true
                        } 
                    }  
                } 
                $bodyLn++                    
            }
        
            $RFdata.Add($data)
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
                            $fldr = [System.IO.Path]::GetDirectoryName($file)
                            $dirs = $fldr.Split('\')
                            $hit.Repo = $dirs[2]
                            $hit.SearchFor = $srchstr
                            $hit.FileName = [System.IO.Path]::GetFileName($file)
                            $fldr = [System.IO.Path]::GetDirectoryName($file)
                            $hit.Folder = Split-Path -Path $fldr -Leaf
                            $hit.Multiple = $false

                            # get context, 20 chars before hit and after
                            $ix = $line.ToLower().IndexOf($srchstr.ToLower())
                            if ($ix -ge 20) {
                                $start = $ix - 20;
                                $alpha = $line.Substring($start, 20)
                            }
                            else {
                                $alpha = $line.Substring(0, $ix)
                            }
                            $slen = $srchstr.ToString().Length
                            if ($ix + $slen + 20 -ge $line.Length) {
                                $rlen = $line.Length - ($ix + $slen)
                                $omega = $line.Substring($ix + $slen, $rlen)
                            }
                            else {
                                $omega = $line.Substring($ix + $slen, 20)
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

try {
    if ($RFresults.Count -gt 0) {
        $csvFile = [System.IO.Path]::Combine($curDir, "RepoFindResults.csv")
        $RFresults | Export-Csv -Path $csvFile -NoTypeInformation
        [void]$sb.AppendLine("Search results - file, line number:")
        [void]$sb.AppendLine()
        foreach ($rf in $RFresults) {
            [void]$sb.AppendLine($rf.FileName + "`t" + $rf.LineNum);
        } 
        Write-Host $sb.ToString()
        $msg = "{0} occurences found. See RepoFindResults.csv." -f $RFresults.Count
        Write-Host $msg
    }
    elseif ($RFdata.Count -gt 0) {
        $csvFile = [System.IO.Path]::Combine($curDir, "RepoFindMetadata.csv")
        $RFdata | Export-Csv -Path $csvFile -NoTypeInformation
        $msg = "{0} articles processed. See RepoFindMetadata.csv." -f $RFdata.Count
        Write-Host $msg
    }
    else {
        Write-Host "No results found."
    }
}
Catch [System.IO.IOException] {
    Write-Host "CSV file is open, please close it."
}
