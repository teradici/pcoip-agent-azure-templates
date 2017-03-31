# Under Development

# How to Deploy Teradici PCoIP Standard Agent on Microsoft Azure

The following procedure will create a new Resource Group with a Storage Account, a VNet, and a Microsoft Windows Server 2016 VM (with Teradici PCoIP Standard Agent installed) in your Microsoft Azure account.

### What you need before starting the deployment

- A Microsoft Azure account
    * To create a free Microsoft Azure account, go to [https://azure.microsoft.com/free/](https://azure.microsoft.com/free/)
	* If you are using an existing Microsoft Azure account, make sure you have permissions to create new resource groups and resources.
- A Registration Code for Teradici PCoIP Standard Agent
    * To obtain a Registration Code for Teradici PCoIP Standard Agent, go to [todo](todo)
- Teradici PCoIP Client
    * To download Teradici PCoIP Client, go to [http://www.teradici.com/product-finder/client-downloads](http://www.teradici.com/product-finder/client-downloads)	

### To deploy

- Click the following button to deploy:

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fteradici%2Fdeployments%2Fmaster%2Fazure%2Fsa%2Fazuredeploy.json">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

- In the Microsoft Azure login page, enter your account credentials and click **Sign in** button.
- In the next screen:
    * For Subscription: Select your subscription
	* For Resource group: Select **Create new**, then enter a name (for example, teradici_pcoip)
	* For Location: Select a location
	* For Admin User: Enter a user name (Note: the user name cannot be 'Admin'; the user name and password will be used later to establish the PCoIP session)
	* For Admin Password: Enter a password
	* For Registration Code: Enter the Registration Code you obtained from Teradici
	* Check the checkbox **I agree to the terms and conditions stated above** and click **Purchase** (Note: You will be charged by Microsoft to your Azure account for this deployment. For more information, go to [https://azure.microsoft.com/pricing/](https://azure.microsoft.com/pricing/)
- The deployment will now start, which will take about 15 minutes to complete.
	
### After the deployment is complete

- Find out the public IP address of the Teradici PCoIP Standard Agent:
    * Log in to [https://portal.azure.com](https://portal.azure.com) using your account credentials.
	* Click **Resource groups**.
	* Find the resource group with the name you entered during the deployment, click on it.
	* Click the **Public IP address** resource. You will be shown the IP Address.
- Connect Teradici PCoIP Client to the Teradici PCoIP Standard Agent:
	* Using the IP address found in the previous step, you can now connect Teradici PCoIP Client to the Teradici PCoIP Standard Agent.

### What you need to do after usage

- Delete the Teradici PCoIP Standard Agent deployment from your Microsoft Azure account (Note: You will be continued to be charged by Microsoft to your Azure account otherwise):
    * Log in to [https://portal.azure.com](https://portal.azure.com) using your account credentials.
    * Click **Resource groups**.
    * Find the resource group name you entered during the deployment, right-click on it, then select **Delete**.
    * You will be prompted to type the resource group name. Type it and click **Delete**.

### Additional information
  * [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software)
  * [*Teradici PCoIP Standard Agent Administrators' Guide*](http://www.teradici.com/web-help/ter1505006/2.7/)
  * [Teradici Community Forum](https://communities.teradici.com/)
  
### Credit
  * Some content of this artcle is based off of the Azure Quickstart Templates, copyright (c) Microsoft Azure, with the following license: https://github.com/Azure/azure-quickstart-templates/blob/master/LICENSE

  
<p>&nbsp;</p>
<p>&nbsp;</p>
Copyright 2017 Teradici Corporation. All Rights Reserved.