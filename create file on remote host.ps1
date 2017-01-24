# Ensure the build fails if there is a problem.
# The build will fail if there are any errors on the remote machine too!
$ErrorActionPreference = 'Stop'

# Create a password variable using the stored password from the Jenkins Global Passwords
$Computer = "192.168.1.19"
$SecurePassword = "pass worrld" | ConvertTo-SecureString -AsPlainText -Force

# If remoting to a machine with domain credentials, use "DOMAIN\YourUserName"
# If remoting to a machine on a workgroup, use "\YourUserName"
$User = "\Administrator"

# Create a PSCredential Object using the a hardcorded username and and $SecurePassword variable

$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword

# Build an object to store variables to send remotley
$objForRemote = @{}

# Add build paramters to the object
$objForRemote.FileName = "test.txt"
$objForRemote.FileContent = "hello world"

# (Optional) I like to output the $objForRemote variable so I can confirm by looking at the Jenkins Console Output of the build I set my parameters correctly.
Write-Output $objForRemote

# Invoke a command on the remote machine, sending $objForRemote to the ArgumentList paramater.
# It depends on the type of job you are executing on the remote machine as to if you want to use "-ErrorAction Stop" on your Invoke-Command.
Invoke-Command -ComputerName $Computer -Credential $cred -ArgumentList $objForRemote -ScriptBlock {
    # Get the arguments passed to the remote session into the same variable name for ease of use
    $objForRemote = $args[0]
    
    # Create Temp Directory
    if (-not(Test-Path -Path 'C:\temp'))
    {
        New-Item -Path 'C:\temp' -ItemType directory
    }

    # Using the environment variables exposed by the Jenkins job 
    Set-Content -Path "C:\temp\$($objForRemote.FileName).txt" -Value $objForRemote.FileContent
}