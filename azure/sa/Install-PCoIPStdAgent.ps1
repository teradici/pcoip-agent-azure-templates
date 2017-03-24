# Install-PCoIPStdAgent.ps1
Configuration InstallPCoIPAgent
{
	param(
     	[Parameter(Mandatory=$true)]
     	[String] $sourceUrl,
    
     	[Parameter(Mandatory=$false)]
     	[String] $registrationCode     	
	)
	
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
            DestinationPath = "C:\WindowsAzure\PCoIPAgentInstaller"
        }

        Script Install_PCoIPAgent
        {
            DependsOn  = "[File]Download_Directory"
            GetScript  = { @{ Result = "Install_PCoIPAgent" } }

            #TODO: Check for other agent types as well?
            TestScript = {
				if ( Get-Item -path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Standard Agent" -ErrorAction SilentlyContinue )  {
					return $true
				}else {
					return $false
				} 
			}

            SetScript  = {
                Write-Verbose "Starting to Install PCoIPAgent"

                $sourceUrl = $using:sourceUrl
                $installerFileName = [System.IO.Path]::GetFileName($sourceUrl)
                $destFile = "C:\WindowsAzure\PCoIPAgentInstaller\" + $installerFileName
                
				Write-Verbose "Downloading PCoIP Agent"
                Invoke-WebRequest $sourceUrl -OutFile $destFile
				#verify md5

                #install the agent
				Write-Verbose "Installing PCoIP Agent"
                $ret = Start-Process -FilePath $destFile -ArgumentList "/S /nopostreboot" -PassThru -Wait

				# Check installer return code
				$rebootRequired = $False
				if ($ret.ExitCode -ne 0) {
					if ($ret.ExitCode -eq 1641) {
						# Reboot is required.
						$rebootRequired = $True
					} else {
						$errMsg = "Failed to install PCoIP Agent. Exit Code: " + $ret.ExitCode
						Write-Verbose $errMsg
						throw $errMsg
					}
				}

                #register
                $registrationCode = $using:registrationCode
                if ($registrationCode) {
					# Insert a delay before activating license
					Start-Sleep -Seconds (5)

	                cd "C:\Program Files (x86)\Teradici\PCoIP Agent"

					Write-Verbose "Activating License Code"               
 	                & .\pcoip-register-host.ps1 -RegistrationCode $registrationCode
					if (-not $?) {
						$errMsg = "Failed to activate License Code."
						Write-Verbose  $errMsg              
						throw $errMsg
					}

					Write-Verbose "Validating License"               
 	                & .\pcoip-validate-license.ps1
					if (-not $?) {
						$errMsg = "Failed to validate license."
						Write-Verbose  $errMsg              
						throw $errMsg
					}
                }
               
				# Insert a delay before the reboot machine / start service
				Start-Sleep -Seconds (10)

				if ($rebootRequired) {
	                Write-Verbose "Request reboot machine."
			        # Setting the global:DSCMachineStatus = 1 tells DSC that a reboot is required
				    $global:DSCMachineStatus = 1
				} else {				
					#start service if it is not started
					$serviceName = "PCoIPAgent"
					if ( (Get-Service  $serviceName).status -eq "Stopped" )	{
						Write-Verbose "Starting PCoIP Agent Service because it is at stopped status."
						Start-Service $serviceName
					}
				}
				
	            Write-Verbose "Finished PCoIP Agent Installation"
            }
        }
    }
}