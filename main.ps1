param(
       # The directory path of the github project
       [Parameter(Mandatory = $true)]
       [string] $localSourceDir,
       
       # This is where the final files, which will then be uploaded to s3, will be written to
       [Parameter(Mandatory = $true)]
       [string] $outputFolder,
       
       # The name of user that owns the github repository
       [Parameter(Mandatory = $true)]
       [string] $repo_userId,
       
       # The name of the repository
       [Parameter(Mandatory = $true)]
       [string] $repo_name,
       
       # The repository branch
       [Parameter(Mandatory = $true)]
       [string] $repo_branch,
       
       # AWS Access Key to symbols bucket
       [Parameter(Mandatory = $true)]
       [string] $AWS_ACCESS_KEY_ID,
       
       # AWS Secret Key to symbols bucket
       [Parameter(Mandatory = $true)]
       [string] $AWS_SECRET_ACCESS_KEY,
       
       # Source paths to ignore, format input like this "name,name,name"
       [string[]] $ignoreArray,
       
       # An array of arrays of strings "one_UserName,one_RepoName,one_Branch;two_UserName,two_RepoName,two_Branch"
       [string[][]] $subModules
)

$subModules_ArrayArray = @(@())

if ($subModules -ne $null)
{
       $subModules = $subModules.split(";")

       foreach ($rawArray in $subModules)
       {
              $rawArray = $rawArray.split(",")
              $subModules_ArrayArray += ,$rawArray
       }

       Write-Output $subModules_ArrayArray[0]
}

# Not sure why yaml names the repo with the repo_userId, but if the input is formatted like this then just correct it
$repo_name = $repo_name -replace "$repo_userId/",""

# Copy symbols from the top of the source directory, it will search recursively for all *.pdb files
Write-Output ""
Write-Output "Copying symbols recursively from source directory..."

$symbolsFolder = "symbols_tempJ1M39VNNDF"
$dbgToolsPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Debuggers\x64"

cmd /c rmdir $symbolsFolder /s /q
cmd /c mkdir $symbolsFolder
cmd /c .\copy_all_pdbs_recursive.cmd $localSourceDir $symbolsFolder

# Edit the pdb's with http addresses
Write-Output ""
Write-Output "Launching github-sourceindexer.ps1..."

.\github-sourceindexer.ps1 -ignoreUnknown -ignore $ignoreArray -sourcesroot $localSourceDir -dbgToolsPath $dbgToolsPath -symbolsFolder $symbolsFolder -userId $repo_userId -repository $repo_name -branch $repo_branch -subModules $subModules_ArrayArray -verbose

# Run symstore on all of the .pdb's
Write-Output ""
Write-Output "Running symstore on all of the .pdb's..."

cmd /c rmdir $outputFolder /s /q
cmd /c mkdir $outputFolder
cmd /c "${env:ProgramFiles(x86)}\Windows Kits\10\Debuggers\x64\symstore.exe" add /compress /r /f $symbolsFolder /s $outputFolder /t SLOBS

# Upload to aws
Write-Output ""
Write-Output "Upload to aws..."
.\s3upload.ps1 $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $symbolsFolder

# Cleanup
Write-Output ""
Write-Output "Cleanup after symbol script..."
cmd /c rmdir $outputFolder /s /q
cmd /c rmdir $symbolsFolder /s /q

Write-Output ""
Write-Output "Symbol script finish."