param(
       # The directory path of the GitHub project
       [Parameter(Mandatory = $true)]
       [string] $symStoreFolder
)

# Function for verbose logging
function Write-VerboseLog {
    param (
        [string] $message
    )
    if ($Env:VERBOSE_SYMB_UPLOAD -eq "true") {
        Write-Host "VERBOSE: $message"
    }
}

# Setting local environment variables
Write-VerboseLog "Setting AWS environment variables..."
$Env:AWS_ACCESS_KEY_ID = $Env:AWS_SYMB_ACCESS_KEY_ID
$Env:AWS_SECRET_ACCESS_KEY = $Env:AWS_SYMB_SECRET_ACCESS_KEY
$Env:AWS_DEFAULT_REGION = "us-east-2"
Write-VerboseLog "AWS environment variables set."

# AWS S3 Copy
Write-VerboseLog "Starting AWS S3 copy..."
try {
    aws s3 cp $symStoreFolder s3://slobs-symbol.streamlabs.com/symbols --recursive --acl public-read
    if ($LastExitCode -ne 0) {
        throw "AWS S3 copy failed with exit code $LastExitCode."
    }
    Write-VerboseLog "AWS S3 copy completed successfully."
}
catch {
    Write-VerboseLog "Error: $_"
    throw
}
