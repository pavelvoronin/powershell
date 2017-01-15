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
#>
# List of computers
$computers = @("Win10Comp1","Win10Comp2","Win10Comp3","Win10Comp4","Win10Comp5","Win10Comp6","Win10Comp7") 
#$computers = Import-CSV C:\Computers.csv | select Computer #or we can read from CSV file
$Result_log= @()
#Convert password to SecureString format
$Pwd = ConvertTo-SecureString -AsPlainText $env:AD_password -Force
$CurrentCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:AD_admin, $Pwd

#Connect to AD_Server and execute script on ScriptBlock
$Jenkins_log = Invoke-Command -ComputerName $env:AD_server -Credential $CurrentCred -ScriptBlock { param($computers,$env:NewLocalAdmin,$env:NewLocalPassword,$Result_log)
Foreach ($computer in $computers) {
    $users = $null
    $comp = [ADSI]"WinNT://$computer"
     #Check if username exists   
        $users = ($computer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
        if ($users -contains $env:NewLocalAdmin) {
 			$Result_log += Write-Output "$computer already contain Local admin account"
        } else {
            #Create the account
            $user = $comp.Create("User","$env:NewLocalAdmin")
            $user.SetPassword("env:NewLocalPassword")
            $user.Put("Description","New Local Admin from Task1")
            $user.Put("Fullname","TestName")
            $user.SetInfo()         
            #Add the account to the local admins group
            $group = [ADSI]"WinNT://$computer/Administrators,group"
            $group.add("WinNT://$computer/$env:NewLocalAdmin")
 
                #Validate what user account has been created or not
                $users = ($computer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
                if ($users -contains $env:NewLocalAdmin) {
					$Result_log += Write-Output "Account $env:NewLocalAdmin created on $computer"
                } else {
				    $Result_log += Write-Output "Account $env:NewLocalAdmin not created on $computer"
                }
          }
		}
return $Result_log
} -ArgumentList $computers,$NewLocalAdmin,$NewLocalPassword, $Result_log
$Jenkins_log > C:\log.txt