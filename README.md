# Symbol/Source Server Indexing and Upload

Either **main.ps1** or **main.bat** can be used as the entry point<br>
The purpose of the optional batch script is to allow for "-script" in azure-pipelines.yml

- **Debuggers tools from winsdk needs to be installed to default location ${env:ProgramFiles(x86)}**
- **The working directory needs to be local in order for the scripts to find each other at .\here**

*This script needs to be run after project compilation, when the .pdb's and output files are still in the local directory*

How the script works:

* Copies all *.pdb from the project folder to a single, working folder
* Edits the pdb's to use http paths for source file locations, using a slightly modified [github-sourceindexer.ps1](https://github.com/Haemoglobin/GitHub-Source-Indexer) script
* Runs microsoft's **symstore.exe** on the .pdb files
* Uploads the output of **symstore.exe** to the s3 bucket used as the symbol server

Review **main.ps1** for a list of parameters to start everything.
