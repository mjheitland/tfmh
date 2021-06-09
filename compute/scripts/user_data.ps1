# get parameters passed in by Terraform
$ps_region = "$TF_REGION"
$ps_instance_type = "$TF_INSTANCE_TYPE"

# create log file in c:\Windows\temp
$filePath = $env:SystemRoot + "\Temp\" + (Get-Date).ToString("yyyy-MM-dd-hh-mm") + ".log"
New-Item -Force $filePath -ItemType file
 
# log statements
Add-Content $filePath ("region: {0}`n" -f $ps_region)
Add-Content $filePath ("instance type: {0}`n" -f $ps_instance_type)
$content = Get-Content $filePath
Write-Host $content 
