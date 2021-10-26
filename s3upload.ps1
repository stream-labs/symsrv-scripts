param(
       # The directory path of the github project
       [Parameter(Mandatory = $true)]
       [string] $symStoreFolder
)

# Local environment variables, even if there are system ones with the same name, these are used for the cmd below
$Env:AWS_ACCESS_KEY_ID = $Env:AWS_SYMB_ACCESS_KEY_ID
$Env:AWS_SECRET_ACCESS_KEY = $Env:AWS_SYMB_SECRET_ACCESS_KEY
$Env:AWS_DEFAULT_REGION = "us-east-2"

aws s3 cp $symStoreFolder s3://slobs-symbol.streamlabs.com/symbols --recursive --acl public-read

if ($LastExitCode) {
	throw
}
