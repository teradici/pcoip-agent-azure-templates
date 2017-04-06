# Deploy Teradici PCoIP Graphics Agent on Microsoft Azure

### What the templates do
- The followings will be created / installed 
	* A Storage account
	* A VNet
	* A network interface with a public IP address,  with following ports open:
	  * 3389 TCP (for RDP)
	  * 443 TCP (for https)
	  * 60443 TCP (for PCoIP diagnostics)
	  * 4172 TCP and UDP (for PCoIP sessions)
	* A Windows Server 2016 VM
	* Teradici PCoIP Graphics Agent 2.8 for Windows
	* NVIDIA GRID 4.2 (369.95) Video Driver

### Structure of the templates
- Main entry point: azuredeploy.json, which links to
	* ..\resources\storage_account.json
	* ..\resources\pcoip_agent_nsg.json
	* ..\resources\virtual_network.json
	* ..\resources\network_interface_pubIP.json
	* virtual_machine.json
	* vm_install_nvidia_and_agent_dsc.json, which uses
	  * Install-NvidiaAndPCoIPGraphicsAgent.zip

### How to use the templates
- By using Azure portal: https://portal.azure.com/#create/Microsoft.Template/uri/
	* Encode the public URI of the file azuredeploy.json. example
	```
	URI: https://raw.githubusercontent.com/teradici/deployments/master/azure/ga/azuredeploy.json
	Encoded URI: https%3A%2F%2Fraw.githubusercontent.com%2Fteradici%2Fdeployments%2Fmaster%2Fazure%2Fga%2Fazuredeploy.json
	```
	* Append the encoded URI to the Azure portal deployment URI. example
	```
    https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fteradici%2Fdeployments%2Fmaster%2Fazure%2Fsa%2Fazuredeploy.json
    ```
- By using powershell
	* Simple powershell code to deploy the templates
    ```
	Add-AzureRmAccount
	$azureRGName = "graphicsAgent-rg" #keep it short and with no special characters and no capitals
	New-AzureRmResourceGroup -Name $azureRGName -Location "SOUTH CENTRAL US" # location must be one of "EAST US", "NORTH CENTRAL US", "SOUTH CENTRAL US", "SOUTHEAST ASIA", "WEST EUROPE"
	New-AzureRmResourceGroupDeployment -DeploymentName "gadeploy" -ResourceGroupName $azureRGName -TemplateFile "azuredeploy.json"
    ```

  
<p>&nbsp;</p>
<p>&nbsp;</p>
Copyright 2017 Teradici Corporation. All Rights Reserved.