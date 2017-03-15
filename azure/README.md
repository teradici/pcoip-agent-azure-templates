# Under Development

# Deploy Teradici Standard Agent on Microsoft Azure

This will deploy Teradici Standard Agent on Microsoft Azure.

### What you need before you start the deployment

1. A Microsoft Azure account
    * to create a free Azure account, goto: [https://azure.microsoft.com/en-in/free/](https://azure.microsoft.com/en-in/free/)
2. A registration code for Teradici Standard Agent
    * to obtain a registration code for Teradici Standard Agent, goto: [todo](todo)

### To deploy

1. Click the button below to deploy.

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ffwang-teradici%2Fdeploy%2Fmaster%2Fdev%2Fdomain-controller%2Fseperate%2Fazuredeploy.json">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

2. In the Microsoft Azure login page, enter your account credentials and click "Sign in" button.
3. In the next screen:
    * for Subscription: select your subscription
	* for Resource group: select "Create new", then enter a name (eg. teradici_pcoip)
	* for Location: select a location
	* for Admin User: enter a user name
	* for Admin Password: enter a password
	* for registration code: enter the registration code you obtained from Teradici
	* check the checkbox "I agree to the terms and conditions stated above" and click "Purchase" button
	* the deployment will now start, which will take about 20 minutes to complete
	
### After the deployment is complete

1. Find out the public ip address of the Standard Agent:
    * Login to [https://portal.azure.com](https://portal.azure.com) using your account credentials
	* Click "Resource groups"
	* Find the resource group whose name starts with ..., click on it
	* Click the "Public IP address" resource. You will be shown the IP Address	
2. Connect Teradici PCoIP client to the Teradici Standard Agent:
    * to download Teradici PCoIP client, goto: [http://www.teradici.com/product-finder/client-downloads](http://www.teradici.com/product-finder/client-downloads)
	* using the IP address found in the prevous step, you can now connect Teradici PCoIP client to the Teradici Standard Agent.

### What you need to do after usage

Delete the Teradici Standard Agent from your Microsoft Azure account
  * Login to [https://portal.azure.com](https://portal.azure.com) using your account credentials
  * Click "Resource groups"
  * Find the resource group name you entered during the deployment, right-click on it, then select "Delete"
  * You will be prompted to type the resource group name. Type it and click "Delete" button

<p>&nbsp;</p>
<p>&nbsp;</p>
Copyright 2017 Teradici Corporation. All Rights Reserved.

Some content is based off of the Azure Quickstart Templates, Copyright (c) Microsoft Azure. With the following license: https://github.com/Azure/azure-quickstart-templates/blob/master/LICENSE
