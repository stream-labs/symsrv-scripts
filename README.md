# Symbol/Source Server Indexing and Upload

Entry point is **main.ps1**

* Installs winsdk debugger tools to default location ${env:ProgramFiles(x86)}
* Copies all *.pdb from the project folder to a single, working folder
* Edits the pdb's to use http paths using a modified [github-sourceindexer.ps1](https://github.com/Haemoglobin/GitHub-Source-Indexer) script
* Runs microsoft's **symstore.exe** on the .pdb files
* Uploads output to the s3 bucket using AWS_SYMB_ACCESS_KEY_ID and AWS_SYMB_SECRET_ACCESS_KEY system env vars

**The working directory needs to able to find partner scripts at .\here**

# Examples

* *.\main.ps1 -localSourceDir 'C:\github\stream-labs\crash-handler' -repo_userId 'stream-labs' -repo_name 'crash-handler' -repo_branch '912ad9e2e475d0dfd77b6433f5a63621059d4101' -ignoreArray 'awss,awsi'*
* *.\main.ps1 -localSourceDir 'C:\github\stream-labs\obs-studio-node' -repo_userId 'stream-labs' -repo_name 'obs-studio-node' -repo_branch '40bb496b50fa634fbc5f5d6bd3b6b42a0e2a9826' -subModules 'stream-labs,lib-streamlabs-ipc,stream-labs'*
* *main.bat 'workingDir' ".\main.ps1 -localSourceDir 'C:\github\stream-labs\obs-studio' -repo_userId 'stream-labs' -repo_name 'obs-studio-node' -repo_branch '41d1f33c2288bfdad8515841999f6d780295ac0f' -subModules 'plugins/enc-amf,stream-labs,obs-amd-encoder,streamlabs'"*

The submodules parameter needs to know four things. The path it's located at within the project, the username that the repo belongs to, the name of the repo, and the branch used by the project. The version used at compilation time will be deduced by the script, so provide the name of the main branch such as 'master', 'head', 'streamlabs', etc.