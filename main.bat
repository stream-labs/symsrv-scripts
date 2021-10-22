@echo on
cd %1
powershell.exe -ExecutionPolicy Bypass -Command %2

Rem main.bat 'ci' ".\main.ps1 -localSourceDir 'val' -outputFolder 'val' -repo_userId 'val' -repo_name 'val' -repo_branch 'val' -AWS_ACCESS_KEY_ID 'val' -AWS_SECRET_ACCESS_KEY 'val'

Rem  Format like this
Rem  -ignoreArray 'awss,awsi'

Rem  Format like this
Rem  -subModules 'one_UserName,one_RepoName,one_Branch;two_UserName,two_RepoName,two_Branch'