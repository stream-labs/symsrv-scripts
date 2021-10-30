# Based on https://github.com/Haemoglobin/GitHub-Source-Indexer

param(
       ## The path of the directory to recursively search for pdb files to index. 
       [Parameter(Mandatory = $true)]
       [Alias("symbols")]
       [string] $symbolsFolder,
       
       ## github user ID
       [Parameter(Mandatory = $true)]
       [string] $userId,
       
       ## github repository name
       [Parameter(Mandatory = $true)]
       [string] $repository,
       
       ## github branch name
       [Parameter(Mandatory = $true)]
       [string] $branch,
       
       ## A root path for the source files
       [Parameter(Mandatory = $true)]
       [string] $sourcesRoot,
       
       ## Debugging Tools for Windows installation path
       [Parameter(Mandatory = $true)]
       [string] $dbgToolsPath,
       
       ## Github URL
       [string] $gitHubUrl,
       
       ## Ignore a source path that contains any of the strings in this array
       [string[]] $ignore,
       
       ## An array of arrays of strings {one_FolderPath,one_UserName,one_RepoName,one_Branch}
       [string[][]] $subModules,
       
       ## Whether or not to ignore paths other than the source root, ie WINDOWS sources etc
       [switch] $ignoreUnknown
  )
       
###############################################################

function CorrectPathBackslash {
  param([string] $path)
  
  if (![String]::IsNullOrEmpty($path)) {
    if (!$path.EndsWith("\")) {
      $path += "\"
    }
  }
  return $path
}

###############################################################

function FindLongestCommonPath {
  param([string] $path1,
        [string] $path2)
  
  $path1Parts = $path1 -split "\\"
  $path2Parts = $path2 -split "\\"
  
  $result = @()
  for ($i = 0; ($i -lt $path1Parts.Length) -and ($i -lt $path2Parts.Length); $i++) {
    if ($path1Parts[$i] -eq $path2Parts[$i]) {
      $result += $path1Parts[$i]
    }
  }
  return [String]::Join("\", $result)
}

###############################################################

function CheckDebuggingToolsPath {
  param([string] $dbgToolsPath)

  $dbgToolsPath = CorrectPathBackslash $dbgToolsPath

  # check whether the dbgToolsPath variable is set
  # it links to srctool.exe application
  if (![String]::IsNullOrEmpty($dbgToolsPath)) {
    if (![System.IO.File]::Exists($dbgToolsPath + "srctool.exe")) {
      Write-Debug "Debugging Tools not found at the given location - trying \srcsrv subdirectory..."
      # Let's try maybe also srcsrv
      $dbgToolsPath += "srcsrv\"
      if (![System.IO.File]::Exists($dbgToolsPath + "srctool.exe")) {
          throw "The Debugging Tools for Windows could not be found at the provided location."
      }
    }
    # OK, we are fine - the srctool exists
    Write-Verbose "Debugging Tools for Windows found at $dbgToolsPath."
  } else {
    Write-Verbose "Debugging Tools path not provided - trying to guess it..."
    # Let's try to execute the srctool and check the error
    if ($(Get-Command "srctool.exe" 2>$null) -eq $null) {
      # srctool.exe can't be found - let's try cdb
      $cdbg = Get-Command "cdb.exe" 2>$null
      if ($cdbg -eq $null) {
        $errormsg = "The Debugging Tools for Windows could not be found. Please make sure " + `
                    "that they are installed and reference them using -dbgToolsPath switch."
        throw $errormsg        
      }
      # cdbg found srctool.exe should be then in the srcsrv subdirectory
      $dbgToolsPath = $([System.IO.Path]::GetDirectoryName($dbg.Defintion)) + "\srcsrv\"
      if (![System.IO.File]::Exists($dbgToolsPath + "srctool.exe")) {
        $errormsg = "The Debugging Tools for Windows could not be found. Please make sure " + `
                    "that they are installed and reference them using -dbgToolsPath switch."
        throw $errormsg
      }
      # OK, we are fine - the srctool exists
      Write-Verbose "The Debugging Tools For Windows found at $dbgToolsPath."
    }
  }
  return $dbgToolsPath
}

###############################################################

function WriteStreamHeader {
  param ([string] $streamPath)
  
  Write-Verbose "Preparing stream header section..."

  Add-Content -value "SRCSRV: ini ------------------------------------------------" -path $streamPath
  Add-Content -value "VERSION=1" -path $streamPath
  Add-Content -value "INDEXVERSION=2" -path $streamPath
  Add-Content -value "VERCTL=Archive" -path $streamPath
  Add-Content -value ("DATETIME=" + ([System.DateTime]::Now)) -path $streamPath
}

###############################################################

function WriteStreamVariables {
  param([string] $streamPath)
  
  Write-Verbose "Preparing stream variables section..."

  Add-Content -value "SRCSRV: variables ------------------------------------------" -path $streamPath
  Add-Content -value "SRCSRVVERCTRL=http" -path $streamPath
  Add-Content -value "HTTP_ALIAS=$gitHubUrl" -path $streamPath
  Add-Content -value "HTTP_EXTRACT_TARGET=%HTTP_ALIAS%/%var2%/%var3%/%var4%/%var5%" -path $streamPath
  Add-Content -value "SRCSRVTRG=%http_extract_target%" -path $streamPath
  Add-Content -value "SRCSRVCMD=" -path $streamPath
}

###############################################################

function WriteStreamSources {
  param([string] $streamPath,
        [string] $pdbPath)
        
  Write-Verbose "Preparing stream source files section..."

  $sources = & ($dbgToolsPath + 'srctool.exe') -r $pdbPath 2>$null
  if ($sources -eq $null) {
    write-warning "No steppable code in pdb file $pdbPath, skipping";
    "failed";
    return;
  }

  $numSources = $sources.Count
  Write-Verbose "Stream source contains $numSources files"
  Add-Content -value "SRCSRV: source files ---------------------------------------" -path $streamPath
    
  $sourcesRoot = CorrectPathBackslash $sourcesRoot
  $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($sourceArchivePath)
    
  #other source files
  foreach ($src in $sources) {
    
    #if the source path $src contains a string in the $ignore array, skip it
    [bool] $skip = $false;
    foreach ($istr in $ignore) 
    {
      $skip = ( ($istr) -and ($src.IndexOf($istr, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) );
      if ($skip) 
      {
        break;
      }
    }
    if ($skip) {
      Write-Verbose "Skipping $src"
      continue;
    }
    
    if (!$src.StartsWith($sourcesRoot, [System.StringComparison]::CurrentCultureIgnoreCase)) {
      if ($ignoreUnknown) {
        Write-Verbose "Ignore $src"
        continue;
      } else {
        throw "Script error. The source path ($src) was invalid";
      }
    }

    Write-Verbose "Attempting src = $src"

    try
    {
      # Github url's are case sensitive, match file case identically
      $wrongCasingPath = $src
      $canonicalCasePath = Get-ChildItem -Path $wrongCasingPath.Replace("\","\*") | Where FullName -IEQ $wrongCasingPath | Select -ExpandProperty FullName
      $src = $canonicalCasePath
    }
    catch
    {
      Write-Warning "Could not resolve file path for $src"
      continue
    }

    $srcStrip = ""

    try
    {
      $srcStrip = $src.Remove(0, $sourcesRoot.Length).Replace("\", "/")    
    }
    catch
    {
      Write-Warning "Could not resolve srcStrip"
      continue
    }

    $filepath = $srcStrip
    $indexSourceTo = "$src*$userId*$repository*$branch*$filepath"
    $urlVerbose = "$gitHubUrl/$userId/$repository/$branch/$filepath"
    
    foreach ($subModule_InfoArray in $subModules)
    {
      $subModule_FolderPath = $subModule_InfoArray[0] 
      $subModule_UserName = $subModule_InfoArray[1] 		
      $subModule_RepoName = $subModule_InfoArray[2]
      $subModule_Branch = $subModule_InfoArray[3]
      
      $bool_fpContainsRepo = $filepath -like "$subModule_FolderPath/*"
      
      if ($bool_fpContainsRepo)
      {
        $filepath = $filepath -replace "$subModule_FolderPath/"
        Write-Verbose "Submodule: '$filepath' url will be corrected to repo named '$subModule_RepoName'"
        $indexSourceTo = "$src*$subModule_UserName*$subModule_RepoName*$subModule_Branch*$filepath"
        $urlVerbose = "$gitHubUrl/$subModule_UserName/$subModule_RepoName/$subModule_Branch/$filepath"
        break;
      }		
    }
	
    Add-Content -value $indexSourceTo -path $streamPath
    Write-Verbose "Indexing source to $urlVerbose"
  }
}

###############################################################
# START
###############################################################
if ([String]::IsNullOrEmpty($gitHubUrl)) {
    $gitHubUrl = "https://raw.githubusercontent.com/";
}

# Check the debugging tools path
$dbgToolsPath = CheckDebuggingToolsPath $dbgToolsPath

$pdbs = Get-ChildItem $symbolsFolder -Filter *.pdb -Recurse
foreach ($pdb in $pdbs) {
  Write-Verbose "Indexing $($pdb.FullName) ..."

  $streamContent = [System.IO.Path]::GetTempFileName()

  try {
    # fill the PDB stream file
    WriteStreamHeader $streamContent
    WriteStreamVariables $streamContent
    $success = WriteStreamSources $streamContent $pdb.FullName
    if($success -eq "failed") {
        continue
    }
    
    Add-Content -value "SRCSRV: end ------------------------------------------------" -path $streamContent
    
    # Save stream to the pdb file
    $pdbstrPath = "{0}pdbstr.exe" -f $dbgToolsPath
    $pdbFullName = $pdb.FullName
    # write stream info to the pdb file
      
    Write-Verbose "Saving the generated stream into the PDB file..."
    . $pdbstrPath -w -s:srcsrv "-p:$pdbFullName" "-i:$streamContent"
        
    Write-Verbose "Done."
  } finally {
    Remove-Item $streamContent
  }
}
