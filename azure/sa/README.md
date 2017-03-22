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
- Main entry point: azuredeploy.json, which links to
	* ..\resources\storageAccount_template.json
	* ..\resources\network_template.json
	* ..\resources\nic_template.json
	* vm_template.json
	* vm_dsc_template.json, which uses
	  * Install-PCoIPStdAgent.zip

### How to use the templates
- By using Azure portal: https://portal.azure.com/#create/Microsoft.Template/uri/
	* Encode the public URI of the file azuredeploy.json. example
	```
	URI: https://raw.githubusercontent.com/fwang-teradici/deploy/master/dev/domain-controller/seperate/azuredeploy.json
	Encoded URI: https%3A%2F%2Fraw.githubusercontent.com%2Ffwang-teradici%2Fdeploy%2Fmaster%2Fdev%2Fdomain-controller%2Fseperate%2Fazuredeploy.json
	```
	* Append the encoded URI to the Azure portal deployment URI. example
	```
    https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ffwang-teradici%2Fdeploy%2Fmaster%2Fdev%2Fdomain-controller%2Fseperate%2Fazuredeploy.json
    ```
- By using powershell
	* Simple powershell code to deploy the templates
    ```
	Add-AzureRmAccount
	$azureRGName = "resourcegroup1" #keep it short and with no special characters and no capitals
	New-AzureRmResourceGroup -Name $azureRGName -Location "West US"
	New-AzureRmResourceGroupDeployment -DeploymentName "sadeploy1" -ResourceGroupName $azureRGName -TemplateFile "azuredeploy.json"
    ```

  
<p>&nbsp;</p>
<p>&nbsp;</p>
Copyright 2017 Teradici Corporation. All Rights Reserved.