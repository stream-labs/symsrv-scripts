# $args[0] = AWS_ACCESS_KEY_ID
# $args[1] = AWS_SECRET_ACCESS_KEY
# $args[2] = local path to folder that will be uploaded

$Env:AWS_ACCESS_KEY_ID=$args[0]
$Env:AWS_SECRET_ACCESS_KEY=$args[1]
$Env:AWS_DEFAULT_REGION="us-east-2"

cmd /c echo on
aws s3 cp $args[2] s3://slobs-symbol.streamlabs.com/symbols --recursive --acl public-read

if ($LastExitCode) {
	Write-Error "AWS Upload Failed"
}
