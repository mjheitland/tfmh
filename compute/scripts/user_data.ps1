<powershell>

# get parameters passed in by Terraform
$ps_instance_type = "$TF_INSTANCE_TYPE"

# create log file in c:\Windows\temp
$filePath = $env:SystemRoot + "\Temp\" + (Get-Date).ToString("yyyy-MM-dd-hh-mm") + ".log"
New-Item -Force $filePath -ItemType file
 
# log statements
Add-Content $filePath ("instance type: {0}`n" -f $ps_instance_type)
$content = Get-Content $filePaths
Write-Host $content 

</powershell>

# execute this user data only for the first launch, not for subsequent reboots!
<persist>false</persist>
