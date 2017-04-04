# Install-PCoIPStdAgent.ps1
Configuration InstallPCoIPAgent
{
	param(
     	[Parameter(Mandatory=$true)]
     	[String] $sourceUrl,
    
     	[Parameter(Mandatory=$true)]
     	[PSCredential] $registrationCodeCredential
	)
	
	$downloadPath = "C:\WindowsAzure\Downloads"

    Node "localhost"
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File Download_Directory 
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = $downloadPath
        }

        Script Install_PCoIPAgent
        {
            DependsOn  = "[File]Download_Directory"
            GetScript  = { @{ Result = "Install_PCoIPAgent" } }

            TestScript = {
				if (Test-Path -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Standard Agent")  {
					return $true
				}else {
					return $false
				} 
			}

            SetScript  = {
                Write-Verbose "Starting to Install PCoIPAgent"

				#agent installer exit code 1641 require reboot machine
				Set-Variable EXIT_CODE_REBOOT 1641 -Option Constant

                $sourceUrl = $using:sourceUrl
                $installerFileName = [System.IO.Path]::GetFileName($sourceUrl)
                $destFile = $using:downloadPath + "\" + $installerFileName
                
				Write-Verbose "Downloading PCoIP Agent"
                Invoke-WebRequest $sourceUrl -OutFile $destFile

                #install the agent
				Write-Verbose "Installing PCoIP Agent"
                $ret = Start-Process -FilePath $destFile -ArgumentList "/S /nopostreboot" -PassThru -Wait

				# Check installer return code
				$rebootRequired = $False
				if ($ret.ExitCode -ne 0) {
					#exit code 1641 means requiring reboot machine after intallation is done, other non zere exit code means installation has some error
					if ($ret.ExitCode -eq $EXIT_CODE_REBOOT) {
						$rebootRequired = $True
					} else {
						$errMsg = "Failed to install PCoIP Agent. Exit Code: " + $ret.ExitCode
						Write-Verbose $errMsg
						throw $errMsg
					}
				}

                #register code is stored at the password property of PSCredential object
                $registrationCode = ($using:registrationCodeCredential).GetNetworkCredential().password
                if ($registrationCode) {
					# Insert a delay before activating license
	                cd "C:\Program Files (x86)\Teradici\PCoIP Agent"

					Write-Verbose "Activating License Code"               
 	                $ret = & .\pcoip-register-host.ps1 -RegistrationCode $registrationCode
					$isExeSucc = $?

					if ($isExeSucc) {
						Write-Verbose "succeeded to activate License Code." 
					} else {
						$retMsg = $ret | Out-String
						$errMsg = "Failed to activate License Code because " + $retMsg
						Write-Verbose  $errMsg              
						throw $errMsg
					}

					Write-Verbose "Validating License"               
 	                $ret = & .\pcoip-validate-license.ps1
					$isExeSucc = $?

					if ($isExeSucc) {
						Write-Verbose "succeeded to validate License."
					} else {
						$retMsg = $ret | Out-String
						$errMsg = "Failed to validate license because " + $retMsg
						Write-Verbose  $errMsg              
						throw $errMsg
					}
                }
               
				if ($rebootRequired) {
	                Write-Verbose "Request reboot machine."
			        # Setting the global:DSCMachineStatus = 1 tells DSC that a reboot is required
				    $global:DSCMachineStatus = 1
				} else {				
					#start service if it is not started
					$serviceName = "PCoIPAgent"
					$svc = Get-Service -Name $serviceName   

					if ($svc.StartType -eq "Disabled") {
						Set-Service -name  $serviceName -StartupType Automatic
					}
					
					if ($svc.status -eq "Paused") {
						$svc.Continue()
					}

					if ( $svc.status -eq "Stopped" )	{
						Write-Verbose "Starting PCoIP Agent Service because it is at stopped status."
						$svc.Start()
						$svc.WaitForStatus("Running", 120)
					}
				}
				
	            Write-Verbose "Finished PCoIP Agent Installation"
            }
        }
    }
}