# Install-PCoIPGraphicsAgent.ps1
Configuration InstallPCoIPAgent
{
	param(
     	[Parameter(Mandatory=$true)]
     	[String] $gaSourceUrl,

     	[Parameter(Mandatory=$true)]
     	[String] $nvidiaSourceUrl,
    
     	[Parameter(Mandatory=$true)]
     	[PSCredential] $registrationCodeCredential
	)
	
    Node "localhost"
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File Nvidia_Download_Directory 
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = "C:\WindowsAzure\NvidiaInstaller"
        }

        File Agent_Download_Directory 
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = "C:\WindowsAzure\PCoIPAgentInstaller"
        }

        Script InstallNvidiaDriver
        {
            DependsOn  = "[File]Nvidia_Download_Directory"

            GetScript  = { @{ Result = "Install_Nvidia" } }

            TestScript = {
				if ( Test-Path -path "HKLM:\SOFTWARE\NVIDIA Corporation\Installer2\Drivers")  {
					return $true
				}else {
					return $false
				} 
			}

            SetScript  = {
                Write-Verbose "Downloading Nvidia driver"
                $nvidiaSourceUrl = $using:nvidiaSourceUrl
                $installerFileName = [System.IO.Path]::GetFileName($nvidiaSourceUrl)
                $destFile = "c:\WindowsAzure\NvidiaInstaller\" + $installerFileName
                Invoke-WebRequest $nvidiaSourceUrl -OutFile $destFile

                Write-Verbose "Installing Nvidia driver"
                $ret = Start-Process -FilePath $destFile -ArgumentList "/s" -PassThru -Wait
				if ($ret.ExitCode -ne 0) {
					$errMsg = "Failed to install nvidia driver. Exit Code: " + $ret.ExitCode
					Write-Verbose $errMsg
					throw $errMsg
				}

                Write-Verbose "Finished Nvidia driver Installation"
            }
        }

        Script Install_PCoIPAgent
        {
            DependsOn  = @("[File]Agent_Download_Directory","[Script]InstallNvidiaDriver")
            GetScript  = { @{ Result = "Install_PCoIPAgent" } }

            #TODO: Check for other agent types as well?
            TestScript = {
				if ( Test-Path -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Graphics Agent")  {
					return $true
				}else {
					return $false
				} 
			}

            SetScript  = {
                Write-Verbose "Starting to Install PCoIPAgent"

				#agent installer exit code 1641 require reboot machine
				Set-Variable EXIT_CODE_REBOOT 1641 -Option Constant

                $gaSourceUrl = $using:gaSourceUrl
                $installerFileName = [System.IO.Path]::GetFileName($gaSourceUrl)
                $destFile = "C:\WindowsAzure\PCoIPAgentInstaller\" + $installerFileName
                
				Write-Verbose "Downloading PCoIP Agent"
                Invoke-WebRequest $gaSourceUrl -OutFile $destFile

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