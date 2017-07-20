# Install-PCoIPAgent.ps1
Configuration InstallPCoIPAgent
{
	param(
     	[Parameter(Mandatory=$true)]
     	[String] $pcoipAgentInstallerUrl,

     	[Parameter(Mandatory=$false)]
     	[String] $videoDriverUrl,
    
     	[Parameter(Mandatory=$true)]
     	[PSCredential] $registrationCodeCredential,

        [Parameter(Mandatory=$false)]
        [String]$gitLocation,

        [Parameter(Mandatory=$false)]
        [String]$sumoCollectorID,

        [Parameter(Mandatory=$false)]
     	[PSCredential] $domainJoinCredential,

        [Parameter(Mandatory=$false)]
		[string]$domainGroupToJoin
	)
    
    $isSA = [string]::IsNullOrWhiteSpace($videoDriverUrl)

    $regPath = If ($isSA) {
				    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Standard Agent"
			   }
			   Else {
					"HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Graphics Agent"
			   }
	$retryCount = 3
	$delay = 10 # seconds
	$orderNumArray = @('1st', '2nd', '3rd')

	$agentInstallerDLDirectory = "C:\WindowsAzure\PCoIPAgentInstaller"

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
            DestinationPath = $agentInstallerDLDirectory
        }

        File Nvidia_Download_Directory 
        {
            Ensure          = If ($isSA) {"Absent"} Else {"Present"} 
            Type            = "Directory"
            DestinationPath = "C:\WindowsAzure\NvidiaInstaller"
        }

        File Sumo_Download_Directory 
        {
            Ensure          = "Present"
            Type            = "Directory"
            DestinationPath = "C:\sumo"
        }

        # Aim to install the collector first and start the log collection before any 
        # other applications are installed.
        Script Install_SumoCollector
        {
            DependsOn  = "[File]Sumo_Download_Directory"
            GetScript  = { @{ Result = "Install_SumoCollector" } }

            TestScript = { 
                return (Test-Path "C:\sumo\sumo.conf" -PathType leaf) -or (!$using:sumoCollectorID)
                }

            SetScript  = {
                Write-Verbose "Install_SumoCollector"

                $installerFileName = "SumoCollector_windows-x64_19_182-25.exe"
                $uninstallerRegistryID = "7857-4527-9352-4688"  # This will need to change for every installer version change!

                $sumo_package = "https://teradeploy.blob.core.windows.net/binaries/$installerFileName"
                $sumo_config = "$using:gitLocation/sumo.conf"
                $sumo_collector_json = "$using:gitLocation/sumo-agent-vm.json"
                $dest = "C:\sumo"
                Invoke-WebRequest -UseBasicParsing -Uri $sumo_config -PassThru -OutFile "$dest\sumo.conf"
                Invoke-WebRequest -UseBasicParsing -Uri $sumo_collector_json -PassThru -OutFile "$dest\sumo-agent-vm.json"
                #
                #Insert unique ID
                $collectorID = "$using:sumoCollectorID"
                (Get-Content -Path "$dest\sumo.conf").Replace("collectorID", $collectorID) | Set-Content -Path "$dest\sumo.conf"
                
                Invoke-WebRequest $sumo_package -OutFile "$dest\$installerFileName"
                
                #install the collector
                $command = "$dest\$installerFileName -console -q"
                Invoke-Expression $command

				# Wait for collector to be installed before exiting this configuration.
				$retryCount = 1800
				while ($retryCount -gt 0)
				{
					$readyToConfigure = ( Get-Item "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$uninstallerRegistryID"  -ErrorAction SilentlyContinue )

					if ($readyToConfigure)
					{
						break   #success
					}
					else
					{
    					Start-Sleep -s 1;
						$retryCount = $retryCount - 1;
						if ( $retryCount -eq 0)
						{
							throw "Sumo collector not installed in time."
						}
						else
						{
							Write-Host "Waiting for Sumo collector to be installed"
						}
					}
				}
            }
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
                $destFile = $using:agentInstallerDLDirectory + '\' + $installerFileName

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
						$errMsg = "Attempt {0} of {1} to install PCoIP Agent failed. Exit Code: {2}." -f $idx, $retryCount, $ret.ExitCode
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
					# Insert a delay before registering
	                cd "C:\Program Files (x86)\Teradici\PCoIP Agent"

					$retryCount = $using:retryCount
					$orderNumArray = $using:orderNumArray

					for ($idx = 1; $idx -le $retryCount; $idx++) {
						Write-Verbose ('It is the {0} try registering the registration code.' -f $orderNumArray[$idx -1])
						$ret = & .\pcoip-register-host.ps1 -RegistrationCode $registrationCode
						$isExeSucc = $?
						
						if ($isExeSucc) {
							#only do validation when command pcoip-register-host.ps1 passed
							Write-Verbose ('It is the {0} try registering the registration code.' -f $orderNumArray[$idx -1])
		 	                $ret = & .\pcoip-validate-license.ps1
							$isExeSucc = $?
						}

						if ($isExeSucc) {
							Write-Verbose "Succeeded to register the registration code." 
							break
						} else {
							$retMsg = $ret | Out-String
							$errMsg = "Attempt {0} of {1} to register the registration code failed. Error Message: {2} " -f $idx, $retryCount, $retMsg
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


        Script JoinDomainGroup
        {
            DependsOn  = @("[File]Agent_Download_Directory")

            GetScript  = { return 'Join a Domain Group'}

            TestScript = { 
				if( -not $using:domainGroupToJoin )
				{
					Write-Host "No Domain group to join."
					return $true
				}
				Test-Path "$using:agentInstallerDLDirectory\domainGroupJoinFile.txt"
            }

            SetScript  = {
				#TODO: Handle OU's and GroupScope like in this article: https://gallery.technet.microsoft.com/scriptcenter/PowerShell-Bulk-AD-Group-4d873f35

				$domainGroupToJoin = $using:domainGroupToJoin
				$machineToJoin = $env:computername

				if( -not ((gwmi win32_computersystem).partofdomain))
				{
					Write-Host "$machineToJoin is not part of a domain so is not joining domain group $domainGroupToJoin."
				}
				else
				{
					$domain = (gwmi win32_computersystem).domain
					$domainInfo = (Get-WMIObject Win32_NTDomain) | Where-Object {$_.DnsForestName -eq $domain} | Select -First 1
					$dcname = ($domainInfo.DomainControllerName -replace "\\", "")

					#create a PSSession with the domain controller that we used to login
					$psSession = New-PSSession -ComputerName $dcname -Credential $using:domainJoinCredential

					Invoke-Command -Session $psSession -ArgumentList $domainGroupToJoin, $machineToJoin `
					-ScriptBlock {
						$domainGroupToJoin = $args[0]
						$machineToJoin = $args[1]

						# Make the AD group for machines if needed
						try
                        {
                            Get-ADGroup $domainGroupToJoin -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Host "Domain Group `"$domainGroupToJoin`" not found. Creating."

							New-ADGroup -name $domainGroupToJoin -GroupScope Global
						}

						# Add-ADGroupMember uses the SAM account name for the computer which has a trailing '$'
						Add-ADGroupMember -Identity $domainGroupToJoin -Members ($machineToJoin + "$")
					}
				}
					
				#make placeholder file so this is only run once
				New-Item "$using:agentInstallerDLDirectory\domainGroupJoinFile.txt" -type file
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