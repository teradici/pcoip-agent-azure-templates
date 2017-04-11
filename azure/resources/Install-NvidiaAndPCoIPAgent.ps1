# Install-PCoIPGraphicsAgent.ps1
Configuration InstallPCoIPAgent
{
	param(
     	[Parameter(Mandatory=$true)]
     	[String] $agentSourceUrl,

     	[Parameter(Mandatory=$false)]
     	[String] $nvidiaSourceUrl,
    
     	[Parameter(Mandatory=$true)]
     	[PSCredential] $registrationCodeCredential
	)
    
    $isSA = $nvidiaSourceUrl -eq $null
        $regPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Graphics Agent"

    if ($isSA) {
        $regPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Standard Agent"
    }
	
    Node "localhost"
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File Agent_Download_Directory 
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = "C:\WindowsAzure\PCoIPAgentInstaller"
        }

        File Nvidia_Download_Directory 
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = "C:\WindowsAzure\NvidiaInstaller"
        }

        Script InstallNvidiaDriver
        {
            DependsOn  = "[File]Nvidia_Download_Directory"

            GetScript  = { @{ Result = "Install_Nvidia" } }

            TestScript = {
                $isSA = $using:isSA

                if ($isSA -or (Test-Path -path "HKLM:\SOFTWARE\NVIDIA Corporation\Installer2\Drivers")) {
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
                $regPath = $using:regPath
				if ( Test-Path -path $regPath)  {
					return $true
				}else {
					return $false
				} 
			}

            SetScript  = {
                Write-Verbose "Starting to Install PCoIPAgent"

				#agent installer exit code 1641 require reboot machine
				Set-Variable EXIT_CODE_REBOOT 1641 -Option Constant

                $agentSourceUrl = $using:agentSourceUrl
                $installerFileName = [System.IO.Path]::GetFileName($agentSourceUrl)
                $destFile = "C:\WindowsAzure\PCoIPAgentInstaller\" + $installerFileName
                
				Write-Verbose "Downloading PCoIP Agent"
                Invoke-WebRequest $agentSourceUrl -OutFile $destFile

                #install the agent
				Write-Verbose "Installing PCoIP Agent"
                $ret = Start-Process -FilePath $destFile -ArgumentList "/S" -PassThru -Wait

				# Check installer return code
				if ($ret.ExitCode -ne 0) {
					#exit code 1641 means requiring reboot machine after intallation is done, other non zere exit code means installation has some error
					if ($ret.ExitCode -ne $EXIT_CODE_REBOOT) {
						$errMsg = "Failed to install PCoIP Agent. Exit Code: " + $ret.ExitCode
						Write-Verbose $errMsg
						throw $errMsg
					}
				}

				
	            Write-Verbose "Finished PCoIP Agent Installation"
            }
        }

        Script Register
        {
            DependsOn  = @("[Script]Install_PCoIPAgent")

            GetScript  = { return 'registration'}
            
            TestScript = { 
                cd "C:\Program Files (x86)\Teradici\PCoIP Agent"
 	            $ret = & .\pcoip-validate-license.ps1
				$isExeSucc = $?

				if ($isExeSucc) {
					return $true
				}

                return $false
            }

            SetScript  = {
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
        }
    }
}