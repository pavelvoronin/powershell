<# Task 1 -  Create local admin user on 7 computers on Jenkins multitask project
This build is parameterized. Add the following parameters:
----------------------
Type: String Parameter
Name: AD_server
Description: Name or IP Address of the remote AD_server
----------------------
Type: String Parameter
Name: AD_Admin_User
Default Value: AD admin; 
Description: Username to connect to the remote AD_server
----------------------
Type: Password Parameter
Name: AD_Password
Default Value: !TestADadmin 
Description: Password to connect to the remote AD_server
----------------------
Type: String Parameter
Name: NewLocalAdmin
Default Value:  TSadmin;
Description: Username of new local admin
----------------------
Type: Password Parameter
Name: NewLocalPassword
Default Value: !TestLocalAdmin 
Description: Password of new local admin
-----------------------
Type: String Parameter
Name: Computer
Default Value: 
Description: List of computers
-----------------------
#>
# List of computers
#$computers = @("Comp1","IE9WIN7")
$Result_log= @()
#Convert password to SecureString format
$Pwd = ConvertTo-SecureString -AsPlainText $env:AD_password -Force
$CurrentCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:AD_Admin_User, $Pwd
echo $env:AD_Admin_User
#Connect to AD_Server and execute script on ScriptBlock

Foreach ($computer in $env:Computers) {
   $users = $null
   $comp = [ADSI]"WinNT://$computer"
           $users = ($comp.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
       
#Check if username exists  
       if ($users -contains $env:NewLocalAdmin) {
          $Result_log += Write-Output "Computer: $computer already contain Local admin account named: $env:NewLocalAdmin"
        } else {
             #Create the account
             $user = $comp.Create(“user”, “$env:NewLocalAdmin”)
             $user.Put(“description”, “$env:NewLocalAdmin”)
             $user.SetPassword($env:NewLocalPassword)
             $user.SetInfo()
             $user.psbase.invokeset(“AccountDisabled”, “False”)
             $user.SetInfo()
             #Add the account to the local admins group
             $group = [ADSI]"WinNT://$computer/Administrators,group"
             $group.add("WinNT://$computer/$env:NewLocalAdmin")
        }
       
                #Validate what user account has been created or not
                $users = ($comp.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
                if ($users -contains $NewLocalAdmin) {
			    	$Result_log += Write-Output "Account $env:NewLocalAdmin created on computer: $computer"
                } else {
				    $Result_log += Write-Output "Account $env:NewLocalAdmin not created on computer: $computer"
                }
         }
		
return $Result_log
$Result_log > C:\temp\log.txt
} -ArgumentList $computers,$NewLocalAdmin,$NewLocalPassword, $Result_log
$Jenkins_log > C:\log.txt