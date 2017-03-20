# Under Development

# Deploy Teradici PCoIP Standard Agent on Microsoft Azure

This will create a new Resource Group with a Storage Account, a VNet and a Microsoft Windows Server 2016 VM (with Teradici PCoIP Standard Agent installed) in your Microsoft Azure account

### What you need before you start the deployment

- A Microsoft Azure account
    * To create a free Microsoft Azure account, goto [https://azure.microsoft.com/en-in/free/](https://azure.microsoft.com/en-in/free/)
	* If you are using an existing Microsoft Azure account, make sure you have write permission
- A registration code for Teradici PCoIP Standard Agent
    * To obtain a registration code for Teradici PCoIP Standard Agent, goto [todo](todo)
- Teradici PCoIP Client
    * To download Teradici PCoIP Client, goto [http://www.teradici.com/product-finder/client-downloads](http://www.teradici.com/product-finder/client-downloads)	

### To deploy

- Click the button below to deploy

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ffwang-teradici%2Fdeploy%2Fmaster%2Fdev%2Fdomain-controller%2Fseperate%2Fazuredeploy.json">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

- In the Microsoft Azure login page, enter your account credentials and click "Sign in" button
- In the next screen
    * For Subscription: select your subscription
	* For Resource group: select "Create new", then enter a name (eg. teradici_pcoip)
	* For Location: select a location
	* For Admin User: enter a user name (note: the user name cannot be "Admin"; the user name and password will be used later to establish the PCoIP session)
	* For Admin Password: enter a password
	* For registration code: enter the registration code you obtained from Teradici
	* Check the checkbox "I agree to the terms and conditions stated above" and click "Purchase" button
	* The deployment will now start, which will take about 20 minutes to complete
	
### After the deployment is complete

- Find out the public ip address of the Teradici PCoIP Standard Agent
    * Login to [https://portal.azure.com](https://portal.azure.com) using your account credentials
	* Click "Resource groups"
	* Find the resource group whose name starts with ..., click on it
	* Click the "Public IP address" resource. You will be shown the IP Address	
- Connect Teradici PCoIP Client to the Teradici PCoIP Standard Agent
	* Using the IP address found in the prevous step, you can now connect Teradici PCoIP Client to the Teradici PCoIP Standard Agent.

### What you need to do after usage

- Delete the Teradici PCoIP Standard Agent deployment from your Microsoft Azure account
    * Login to [https://portal.azure.com](https://portal.azure.com) using your account credentials
    * Click "Resource groups"
    * Find the resource group name you entered during the deployment, right-click on it, then select "Delete"
    * You will be prompted to type the resource group name. Type it and click "Delete" button

### Additional information
  * [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software)
  * [Teradici PCoIP Standard Agent Admin Guide](http://www.teradici.com/web-help/ter1505006/2.6/)
  * [Reradici Community Forum](https://communities.teradici.com/)
  
### Credit
  * Some content is based off of the Azure Quickstart Templates, Copyright (c) Microsoft Azure. With the following license: https://github.com/Azure/azure-quickstart-templates/blob/master/LICENSE

  
<p>&nbsp;</p>
<p>&nbsp;</p>
Copyright 2017 Teradici Corporation. All Rights Reserved.