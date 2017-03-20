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
            TestScript = { if ( Get-Item -path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\PCoIP Standard Agent" -ErrorAction SilentlyContinue )
                            {return $true}
                            else {return $false} }
            SetScript  = {
                Write-Output "Starting to Install PCoIPAgent"

                $sourceUrl = $using:sourceUrl
                $installerFileName = [System.IO.Path]::GetFileName($sourceUrl)
                $destFile = "C:\WindowsAzure\PCoIPAgentInstaller\" + $installerFileName
                
				Write-Output "Downloading PCoIP Agent"
                Invoke-WebRequest $sourceUrl -OutFile $destFile

                #install the agent
				Write-Output "Installing PCoIP Agent"
                Start-Process -FilePath "$destFile" -ArgumentList "/S" -Wait
                
                #register
                $registrationCode = $using:registrationCode
                if ($registrationCode) {
					Write-Output "Activating License Code"               
	                cd "C:\Program Files (x86)\Teradici\PCoIP Agent"
 	                & .\pcoip-register-host.ps1 -RegistrationCode $registrationCode
 	                & .\pcoip-validate-license.ps1
                }
                
				$serviceName = "PCoIPAgent"
				if ( (Get-Service  $serviceName).status -eq "Stopped" ) 
				{
					Write-Output "Starting PCoIP Agent Service because it is stopped."
					Start-Service $serviceName | Out-Null
				}                
				
                Write-Output "Finish PCoIP Agent Installation"
            }
        }
    }
}