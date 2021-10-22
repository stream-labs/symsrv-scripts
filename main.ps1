param(
	# The directory path of the to the root of the github project
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
       
	# Optional, source paths to ignore
       [string[]] $ignoreArray

       )

# Not sure why yaml names the repo with the repo_userId, but if the input is formatted like this then just correct it
$repo_name = $repo_name -replace "$repo_userId/",""

# Install winsdksetup to expected dir
Write-Output ""
Write-Output "Installing debugging tools from winsdksetup..."
#Invoke-WebRequest https://go.microsoft.com/fwlink/?linkid=2173743 -OutFile winsdksetup.exe;    
#start-Process winsdksetup.exe -ArgumentList '/features OptionId.WindowsDesktopDebuggers /uninstall /q' -Wait;    
#start-Process winsdksetup.exe -ArgumentList '/features OptionId.WindowsDesktopDebuggers /q' -Wait;    
#Remove-Item -Force winsdksetup.exe;

# Copy symbols from the top of the source directory, it will search recursively for all *.pdb files
Write-Output ""
Write-Output "Copying symbols recursively from source directory..."

$symbolsFolder = "symbols_tempJ1M39VNNDF"
$dbgToolsPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Debuggers\x64"

cmd /c rmdir $symbolsFolder /s /q
cmd /c mkdir $symbolsFolder
cmd /c .\copy_all_pdbs_recursive.cmd $localSourceDir $symbolsFolder

# Compile a list of submodules to the format (subModule_UserName, subModule_RepoName, subModule_Branch)
$mainRepoUri = "https://api.github.com/repos/$repo_userId/$repo_name"
$webRequestUri = "$mainRepoUri/contents?ref=$repo_branch"
Write-Output ""
Write-Output "Compiling a list of submodules from '$webRequestUri'..."
$mainRepoContentJson = (Invoke-WebRequest $webRequestUri -UseBasicParsing | ConvertFrom-Json)

$subModules = @(@())

foreach ($subBlob in $mainRepoContentJson)
{
	if (!$subBlob.git_url.StartsWith($mainRepoUri))
	{
		$subModule_UserName = ($subBlob.url -replace "https://api.github.com/repos/*","").split('/')[0] 		
		$subModule_RepoName = $subBlob.name
		$subModule_Branch = $subBlob.sha		
		$subModules += ,@($subModule_UserName, $subModule_RepoName, $subModule_Branch)
		
		Write-Output "Found sub-module: https://github.com/$subModule_UserName/$subModule_RepoName/tree/$subModule_Branch"
	}
}

Write-Output ""
Write-Output "Launching github-sourceindexer.ps1..."

.\github-sourceindexer.ps1 -ignoreUnknown -ignore $ignoreArray -sourcesroot $localSourceDir -dbgToolsPath $dbgToolsPath -symbolsFolder $symbolsFolder -userId $repo_userId -repository $repo_name -branch $repo_branch -subModules $subModules -verbose

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