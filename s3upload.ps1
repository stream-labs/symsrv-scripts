param(
       # The directory path of the GitHub project
       [Parameter(Mandatory = $true)]
       [string] $symStoreFolder
)

# Local environment variables, even if there are system ones with the same name, these are used for the cmd below
Write-Host "S3Upload: Setting AWS environment variables..."
$Env:AWS_ACCESS_KEY_ID = $Env:AWS_SYMB_ACCESS_KEY_ID
$Env:AWS_SECRET_ACCESS_KEY = $Env:AWS_SYMB_SECRET_ACCESS_KEY
$Env:AWS_DEFAULT_REGION = "us-east-2"
Write-Host "S3Upload: AWS environment variables set."

# AWS S3 Copy with debug option
Write-Host "S3Upload: Starting AWS S3 copy..."
try {
    aws s3 cp $symStoreFolder s3://slobs-symbol.streamlabs.com/symbols --recursive --acl public-read --debug

    if ($LastExitCode -ne 0) {
        throw "AWS S3 copy failed with exit code $LastExitCode."
    }
    Write-Host "S3Upload: AWS S3 copy completed successfully."
}
catch {
    Write-Host "S3Upload: Error: $_"
    throw
}
