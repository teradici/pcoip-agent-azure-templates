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
	$retryCount = 3
	$delay = 10
	$orderNumArray = @('1st', '2nd', '3rd')

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
            Ensure          = If ($isSA) {"Absent"} Else {"Present"} 
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

				$orderNumArray = $using:orderNumArray
				$retryCount = $using:retryCount

				for ($idx = 1; $idx -le $retryCount; $idx++) {
					Write-Verbose ('It is the {0} try downloading video driver from {1} ...' -f $orderNumArray[$idx -1], $videoDriverUrl)
					Try{
						Invoke-WebRequest $videoDriverUrl -OutFile $destFile -UseBasicParsing -PassThru  -ErrorAction Stop
						break
					}Catch{
						$errMsg = "Attempt {0} of {1} to download video driver failed. Error Infomation: {2} " -f $idx, $retryCount, $_.Exception.Message 
						Write-Verbose $errMsg
						if ($idx -ne $retryCount) {
							Start-Sleep -s $using:delay
						} else {
							throw $errMsg
						}
					}
				}

				for ($idx = 1; $idx -le $retryCount; $idx++) {
					Write-Verbose ('It is the {0} try installing Nvidia driver...' -f $orderNumArray[$idx -1])

	                $ret = Start-Process -FilePath $destFile -ArgumentList "/s /noeula /noreboot" -PassThru -Wait
					
					# treat exit code 0 or 1 as success
					if (($ret.ExitCode -eq 0) -or ($ret.ExitCode -eq 1)) {
						Write-Verbose "Request reboot machine after Installing Video Driver."
						# Setting the global:DSCMachineStatus = 1 tells DSC that a reboot is required
						$global:DSCMachineStatus = 1
						Write-Verbose "Finished Nvidia driver Installation"
						break
					} else {
						$errMsg = "Attempt {0} of {1} to install nvidia driver failed. Exit Code: {2} ." -f  $idx, $retryCount,  $ret.ExitCode
						Write-Verbose $errMsg
						if ($idx -ne $retryCount) {
							Start-Sleep -s $using:delay
						} else {
							throw $errMsg
						}
					}
				}
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
                
				$orderNumArray = $using:orderNumArray
				$retryCount = $using:retryCount

				for ($idx = 1; $idx -le $retryCount; $idx++) {
					Write-Verbose ('It is the {0} try downloading PCoIP Agent installer from {1} ...' -f $orderNumArray[$idx -1], $pcoipAgentInstallerUrl)
					Try{
						Invoke-WebRequest $pcoipAgentInstallerUrl -OutFile $destFile -UseBasicParsing -PassThru -ErrorAction Stop
						break
					} Catch {
						$errMsg = "Attempt {0} of {1} to download PCoIP Agent installer failed. Error Infomation: {2} " -f $idx, $retryCount, $_.Exception.Message 
						Write-Verbose $errMsg
						if ($idx -ne $retryCount) {
							Start-Sleep -s $using:delay
						} else {
							throw $errMsg
						}
					}
				}

                #install the agent
				for ($idx = 1; $idx -le $retryCount; $idx++) {
					Write-Verbose ('It is the {0} try intalling PCoIP Agent...' -f $orderNumArray[$idx -1])

					$ret = Start-Process -FilePath $destFile -ArgumentList "/S /nopostreboot" -PassThru -Wait

					if (($ret.ExitCode -eq 0) -or ($ret.ExitCode -eq $EXIT_CODE_REBOOT)) {
						if ($ret.ExitCode -eq $EXIT_CODE_REBOOT) {
							Write-Verbose "Request reboot machine after Installing pcoip agent."
							# Setting the global:DSCMachineStatus = 1 tells DSC that a reboot is required
							$global:DSCMachineStatus = 1
						}
						Write-Verbose "Finished PCoIP Agent Installation"
						break
					} else {
						$errMsg = "Attempt {0} of [1} to install PCoIP Agent failed. Exit Code: {2}." -f $idx, $retryCount, $ret.ExitCode
						Write-Verbose $errMsg
						if ($idx -ne $retryCount) {
							Start-Sleep -s $using:delay
						} else {
							throw $errMsg
						}
					}
				}
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

					$retryCount = $using:retryCount
					$orderNumArray = $using:orderNumArray

					for ($idx = 1; $idx -le $retryCount; $idx++) {
						Write-Verbose ('It is the {0} try activating license code.' -f $orderNumArray[$idx -1])
						$ret = & .\pcoip-register-host.ps1 -RegistrationCode $registrationCode
						$isExeSucc = $?
						
						if ($isExeSucc) {
							#only do validation when command pcoip-register-host.ps1 passed
							Write-Verbose ('It is the {0} try validating license code.' -f $orderNumArray[$idx -1])
		 	                $ret = & .\pcoip-validate-license.ps1
							$isExeSucc = $?
						}

						if ($isExeSucc) {
							Write-Verbose "succeeded to validate License Code." 
							break
						} else {
							$retMsg = $ret | Out-String
							$errMsg = "Attempt {0} of {1} to validate license code failed. Error Message: {2} " -f $idx, $retryCount, $retMsg
							Write-Verbose  $errMsg     

							if ($idx -ne $retryCount) {
								Start-Sleep -s $using:delay
							} else {
								throw $errMsg
							}		
						}
					}
                }              
            }
        }

        Script StartPcoIPService
        {
            DependsOn  = @("[Script]Register")

            GetScript  = { return 'Start PcoIP Service'}

            TestScript = { 
				$serviceName = "PCoIPAgent"

				$svc = Get-Service -Name $serviceName   
            
				return $svc.Status -eq "Running"
            }

            SetScript  = {
				$serviceName = "PCoIPAgent"
				$svc = Get-Service -Name $serviceName   

				if ($svc.StartType -ne "Automatic") {
					$msg = "try setting {0} Service start type to automatic." -f $serviceName
					Write-Verbose $msg

					Set-Service -name  $serviceName -StartupType Automatic

					$status = If ($?) {"succeeded"} Else {"failed"}
					$msg = "{0} to change start type of {1} service to Automatic." -f $status, $serviceName
					Write-Verbose $msg
				}
					
				if ($svc.status -eq "Paused") {
					Write-Verbose "try resuming PCoIPAgent Service ."					
					try{
						$svc.Continue()
						Write-Verbose "succeeded to resume PCoIPAgent service."
					}catch{
						throw "failed to resume PCoIP Agent Service."
					}
				}

				if ( $svc.status -eq "Stopped" )	{
					Write-Verbose "Starting PCoIP Agent Service ..."
					try{
						$svc.Start()
						$svc.WaitForStatus("Running", 120)
					}catch{
						throw "failed to start PCoIP Agent Service"
					}
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
            Write-Verbose "Will install firefox"
            $destFile = $using:LocalPath

			$retryCount = 3
			$delay = 10
			$orderNumArray = @('1st', '2nd', '3rd')

			for ($idx = 1; $idx -le $retryCount; $idx++) {
				Write-Verbose ('It is the {0} try installing firefox ...' -f $orderNumArray[$idx -1])

	            $ret = Start-Process -FilePath $destFile -ArgumentList "/SilentMode" -PassThru -Wait

				if ($ret.ExitCode -eq 0) {
                    Write-Verbose "Finished firefox Installation."
					break
				} else {
				    $errMsg = "Attempt {0} of {1} to install firefox failed. Exit Code: {2}" -f $idx, $retryCount, $ret.ExitCode
				    Write-Verbose $errMsg
					if ($idx -ne $retryCount) {
						Start-Sleep -s $delay
					}
				}
			}
        }
    }
}

Configuration AudioService
{
    Node "localhost"
    {
		$serviceName = "Audiosrv"

        Script SetAudioServiceAutomaticAndRunning
        {
            GetScript  = { @{ Result = "Audio_Service" } }

            TestScript = {
				$serviceName = $using:serviceName 
				$svc = Get-Service -Name $serviceName   

				return $svc.Status -eq "Running"
			}

            SetScript  = {
				$serviceName = $using:serviceName 
				$svc = Get-Service -Name $serviceName   

				if ($svc.StartType -ne "Automatic") {
					$msg = "start type of " + $servicename + " is: " + $svc.StartType
					Write-Verbose $msg
					Set-Service -name  $serviceName -StartupType Automatic
					if ($?) {
						$msg = "changed start type of " + $servicename + " to: Automatic"
					} else {
						$msg = "falied to change start type of " + $servicename + " to: Automatic"
					}
					Write-Verbose $msg
				}
					
				if ($svc.status -ne "Running") {
					$msg = "status of " + $servicename + " is: " + $svc.status
					Write-Verbose $msg
					Set-Service -Name $serviceName -Status Running
					if ($?) {
						$msg = "changed status of " + $servicename + " to: Running"
					} else {
						$msg = "falied to change status of " + $servicename + " to: Running"
					}

					Write-Verbose $msg
				}
            }
		}
	}
}