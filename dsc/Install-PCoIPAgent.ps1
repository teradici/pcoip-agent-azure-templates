# Install-PCoIPAgent.ps1
Configuration InstallPCoIPAgent
{
	param(
     	[Parameter(Mandatory=$true)]
     	[String] $pcoipAgentInstallerUrl,

     	[Parameter(Mandatory=$false)]
     	[String] $videoDriverUrl,
    
     	[Parameter(Mandatory=$true)]
     	[PSCredential] $registrationCodeCredential
	)
    
    $isSA = [string]::IsNullOrWhiteSpace($videoDriverUrl)

    $regPath = If ($isSA) {
				    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Standard Agent"
			   }
			   Else {
					"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Graphics Agent"
			   }
	
    Node "localhost"
    {
        VmUsability TheVmUsability

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

        Script InstallVideoDriver
        {
            DependsOn  = "[File]Nvidia_Download_Directory"

            GetScript  = { @{ Result = "Install_Video_Driver" } }

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
                $videoDriverUrl = $using:videoDriverUrl
                $installerFileName = [System.IO.Path]::GetFileName($videoDriverUrl)
                $destFile = "c:\WindowsAzure\NvidiaInstaller\" + $installerFileName
                Invoke-WebRequest $videoDriverUrl -OutFile $destFile

                Write-Verbose "Installing Nvidia driver"
                $ret = Start-Process -FilePath $destFile -ArgumentList "/s /noeula /noreboot" -PassThru -Wait
                Write-Verbose ("Nvidia driver exit code: "  + $ret.ExitCode)

                # treat returned code 0 and 1 as success
				if (($ret.ExitCode -ne 0) -and ($ret.ExitCode -ne 1)) {
                    $stdout = $ret.StandardOutput.ReadToEnd();
                    $stderr = $ret.StandardError.ReadToEnd();
					$errMsg = "Failed to install nvidia driver. standard output: " + $stdout + "; standard error: " + $stderr
					Write-Verbose $errMsg
					throw $errMsg
				} else {
					Write-Verbose "Request reboot machine after Installing Video Driver."
					# Setting the global:DSCMachineStatus = 1 tells DSC that a reboot is required
					$global:DSCMachineStatus = 1
				}

                Write-Verbose "Finished Nvidia driver Installation"
            }
        }

        Script Install_PCoIPAgent
        {
            DependsOn  = @("[File]Agent_Download_Directory","[Script]InstallVideoDriver")
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

                $pcoipAgentInstallerUrl = $using:pcoipAgentInstallerUrl
                $installerFileName = [System.IO.Path]::GetFileName($pcoipAgentInstallerUrl)
                $destFile = "C:\WindowsAzure\PCoIPAgentInstaller\" + $installerFileName
                
				Write-Verbose "Downloading PCoIP Agent"
                Invoke-WebRequest $pcoipAgentInstallerUrl -OutFile $destFile

                #install the agent
				Write-Verbose "Installing PCoIP Agent"
                $ret = Start-Process -FilePath $destFile -ArgumentList "/S /nopostreboot" -PassThru -Wait

				# Check installer return code
				if ($ret.ExitCode -ne 0) {
					#exit code 1641 means requiring reboot machine after intallation is done, other non zere exit code means installation has some error
					if ($ret.ExitCode -eq $EXIT_CODE_REBOOT) {
						Write-Verbose "Request reboot machine after Installing pcoip agent."
						# Setting the global:DSCMachineStatus = 1 tells DSC that a reboot is required
						$global:DSCMachineStatus = 1
					} else {
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

				# the powershell variable $? to indicate the last executing command status
				return $?
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

Configuration VmUsability
{
    Node "localhost"
    {
        DisableServerManager TheDisableServerManager
        InstallFirefox TheInstallFirefox
        AudioService TheAudioService
    }
}

Configuration DisableServerManager
{
    Node "localhost"
    {
        Registry DisableServerManager
        {
            Ensure = "Present"
            Key = "HKLM:\Software\Microsoft\ServerManager"
            ValueName = "DoNotOpenServerManagerAtLogon"
            ValueData = "1"
            ValueType = "Dword"
        }
    }
}

Configuration InstallFirefox
{
    param
    (
        [string]$VersionNumber = "latest",
        [string]$Language = "en-US",
	    [string]$OS = "win",
        [string]$MachineBits = "x86",
	    [string]$LocalPath = "$env:SystemDrive\Windows\DtlDownloads\Firefox Setup " + $versionNumber +".exe"
    )
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    xRemoteFile Downloader
    {
        Uri = "http://download.mozilla.org/?product=firefox-" + $VersionNumber +"&os="+$OS+"&lang=" + $Language 
	    DestinationPath = $LocalPath
    }
	 
    Script Install_Firefox
    {
        DependsOn = "[xRemoteFile]Downloader"
        GetScript  = { @{ Result = "Install_Firefox" } }

        TestScript = {
            $regPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Mozilla Firefox*"

			if ( Test-Path -path $regPath)  {
				return $true
			} else {
				return $false
			} 
		}

        SetScript  = {
            Write-Verbose "Installing firefox"
            $destFile = $using:LocalPath
            $ret = Start-Process -FilePath $destFile -ArgumentList "/SilentMode" -PassThru -Wait

			if ($ret.ExitCode -ne 0) {
                # retry
                $ret = Start-Process -FilePath $destFile -ArgumentList "/SilentMode" -PassThru -Wait

			    if ($ret.ExitCode -ne 0) {
				    $errMsg = "Failed to install firefox. exitcode: " + $ret.ExitCode
				    Write-Verbose $errMsg
			    } else {
                    Write-Verbose "Finished firefox Installation"
                }
			} else {
                Write-Verbose "Finished firefox Installation"
            }
        }
    }
}

Configuration AudioService
{
	$serviceName = "Audiosrv"
	$svc = Get-Service -Name $serviceName   

    Node "localhost"
    {
        Script SetAudioServiceAutomaticAndRunning
        {
            GetScript  = { @{ Result = "Audio_Service" } }

            TestScript = {
                $svc = $using:svc

                if (($svc.StartType -ne "Automatic") -or ($svc.status -ne "Running")) {
					return $false
				} else {
					return $true
				} 
			}

            SetScript  = {
                $serviceName = $using:serviceName
                $svc = $using:svc
				if ($svc.StartType -ne "Automatic") {
					$msg = "start type of " + $servicename + " is: " + $svc.StartType
					Write-Verbose $msg
					Set-Service -name  $serviceName -StartupType Automatic
					$msg = "changed start type of " + $servicename + " to: Automatic"
					Write-Verbose $msg
				}
					
				if ($svc.status -ne "Running") {
					$msg = "status of " + $servicename + " is: " + $svc.status
					Write-Verbose $msg
					Set-Service -Name $serviceName -Status Running
					$msg = "changed status of " + $servicename + " to: Running"
					Write-Verbose $msg
				}
            }
		}
	}
}