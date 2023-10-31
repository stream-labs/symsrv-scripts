# Symbol Server Indexing and Upload

Entry point is **main.ps1**

* Installs winsdk debugger tools to default location ${env:ProgramFiles(x86)}
* Copies all *.pdb from the project folder to a single, working folder
* Runs microsoft's **symstore.exe** on the .pdb files
* Uploads output to the s3 bucket using AWS_SYMB_ACCESS_KEY_ID and AWS_SYMB_SECRET_ACCESS_KEY system env vars

**The working directory needs to able to find partner scripts at .\here**

# Examples

* *.\main.ps1 -localSourceDir 'C:\github\stream-labs\crash-handler' 
* *main.bat 'workingDir' ".\main.ps1 -localSourceDir 'C:\github\stream-labs\obs-studio'