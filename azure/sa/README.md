# Deploy Teradici PCoIP Standard Agent on Microsoft Azure

### What the templates do
- The followings will be created / installed 
	* A Storage account
	* A VNet with following ports open:
	  * 3389 TCP (for RDP)
	  * 443 TCP (for https)
	  * 60443 TCP (for PCoIP diagnostics)
	  * 4172 TCP and UDP (for PCoIP sessions)
	* A network interface with a public IP address
	* A Windows Server 2016 VM
	* Teradici PCoIP Standard Agent 2.8

### Structure of the templates
- main entry point: azuredeploy.json, which invokes
	* ..\resources\storageAccount_template.json
	* ..\resources\network_template.json
	* ..\resources\nic_template.json
	* vm_template.json
	* vm_dsc_template.json, which uses
	  * Install-PCoIPStdAgent.zip

### How to use the templates
- By using https://portal.azure.com/#create/Microsoft.Template/uri/
	* encode the public URI of the file azuredeploy.json
	* append it to the following uri:
	```
    https://portal.azure.com/#create/Microsoft.Template/uri/
    ```
- By using powershell
	* simple powershell code to deploy the templates
    ```
	Add-AzureRmAccount
	$azureRGName = "resourcegroup1" #keep it short and with no special characters and no capitals
	New-AzureRmResourceGroup -Name $azureRGName -Location "West US"
	New-AzureRmResourceGroupDeployment -DeploymentName "sadeploy1" -ResourceGroupName $azureRGName -TemplateFile "azuredeploy.json"
    ```

  
<p>&nbsp;</p>
<p>&nbsp;</p>
Copyright 2017 Teradici Corporation. All Rights Reserved.