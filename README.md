# Deploying Teradici Cloud Access Software on Microsoft Azure

Use these steps to deploy a Virtual Machine on Azure, running Windows Server 2016, and the latest (v2.8) [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software) - Standard Edition or Graphics Edition. 

All resources required to run the Teradici PCoIP Standard or Graphics agent (components of Teradici Cloud Access Software) will be created and configured in your Azure subscription under a new resource group.

Once deployed you will be able to connect to the Teradici PCoIP agent using the Teradici PCoIP client.

## Before You Begin

* Setup a Microsoft Azure account and ensure you have permissions to create new resource groups and resources. If you don't already have an account, you can sign up for a [free Microsoft Azure account](https://azure.microsoft.com/free/). 
* Use an existing or [trial](http://connect.teradici.com/cas-trial) Registration code for a Teradici PCoIP Standard or Graphics agent.
* Download and install the [Teradici PCoIP Client](http://www.teradici.com/product-finder/client-downloads).

## Deploy the PCoIP Agent

Choose whether you want to deploy a Teradici PCoIP Standard or Graphics agent and deploy it to Azure by clicking the *Deploy to Azure* button.

By clicking one of the *Deploy to Azure* buttons below you accept the terms of the Teradici Cloud Access Software [End User License Agreement](http://www.teradici.com/pdf/teradici-cloud-access-software-eula.pdf) and by clicking the *Deploy to Azure* button to deploy a Teradici PCoIP Graphics agent on a NV instance type virtual machine, you have read and agree to be bound by the [software license](http://www.nvidia.com/content/DriverDownload-March2009/licence.php?lang=us) for use of the third-party drivers.
   
#### Teradici PCoIP Standard agent

To deploy a Teradici PCoIP **Standard** agent, on a [Standard_D2_v2](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general)\* type virtual machine, click
    
<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fdevtemplatestore.blob.core.windows.net%2Ftemplates%2Fmaster%2Fdeployments%2Fazure-deploy-sa-windows2016.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>

#### Teradici PCoIP Graphics agent

To deploy a Teradici PCoIP **Graphics** agent, on a [NV6](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu)\* type virtual machine, click

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fdevtemplatestore.blob.core.windows.net%2Ftemplates%2Fmaster%2Fdeployments%2Fazure-deploy-ga-windows2016.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>


Next follow these steps:

* When prompted by the Azure portal, enter your Azure credentials.
* When presented with the Azure Custom deployment screen, set these options
    * *Subscription:* Select your subscription.
    * *Resource group:* Select *Create new*, then enter a resource group name (for example *teradici_trial*).
    * *Location:* Select a location. 
        * Note: Teradici PCoIP Graphics agent deployments require locations that support NV instance types, currently this is limited to the following locations: EAST US, NORTH CENTRAL US, SOUTH CENTRAL US, SOUTHEAST ASIA, or WEST EUROPE.
    * *Admin User:* Enter a username for your PCoIP session connection login. Do not use Admin.
    * *Admin Password:* Enter a password.
    * *Registration Code:* Enter the Registration code you received from Teradici.
* Review the Microsoft Terms and Conditions. Indicate your agreement by selecting *I agree to the terms and conditions stated above*.
* Enable *Pin to dashboard* if you wish to monitor the status of your deployment from the Azure dashboard.
* Click **Purchase**

Deployment will now start and may take up to 15 minutes to complete. You can track the status of the deployment via the Azure Notifications drop down. Regular Azure charges will apply to your Microsoft Azure account for this deployment.

\* See the [Azure Pricing Guide](https://azure.microsoft.com/pricing/details/virtual-machines/windows/) for estimated virtual machine pricing.

## Connect to the PCoIP Agent

Once deployment is complete, to connect to your deployed Teradici PCoIP agent find the IP address:
* Log in to the [Azure Portal](https://portal.azure.com/).
* Click *Resource groups*, find the resource group you created during deployment, and select it.
* Click the *Public IP address* resource (named *pcoip-agent-pip*) to obtain the IP address.

From the Teradici PCoIP client, establish a connection to the virtual machine with the Teradici PCoIP agent you deployed on Azure:
* Launch the Teradici PCoIP client and enter the IP address obtained above in the *Host Address* field, and click **Next**.
* Enter the *Admin User* and *Password* credentials created above and login to the virtual machine.
* You now have access to a PCoIP cloud-delivered desktop.

#### Known Issue(s)
* Initial, Windowed mode, connections to a newly deployed Teradici PCoIP **Graphics** agent, may result in a blank screen. To clear the blank screen, resize the window or connect in Full Screen mode.

## Delete the PCoIP Agent

When you are finished using the Teradici PCoIP agent (and in order to avoid unwanted charges), use these steps to remove the Teradici PCoIP agent (and all associated resources) from your Microsoft Azure subscription:
* Log in to the [Azure Portal](https://portal.azure.com/) and click *Resource groups*.
* Find and right-click the resource group name you created and choose **Delete**.
* Enter the resource group name when prompted and click **Delete**.

## More Information

* [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software)
* [Teradici Cloud Access Software documentation (v2.8)](https://techsupport.teradici.com/ics/support/kbanswer.asp?deptID=15164&task=knowledge&questionID=3090) which includes release notes, quick start guides, etc...
* [Teradici Technical Support](https://techsupport.teradici.com)
* [Teradici Community Forum](https://communities.teradici.com/topics/cloud+access+software.html)

## Credits

* Some content in this article is based on the Azure quick start Templates, © Microsoft Azure, licensed under the [MIT license](https://github.com/Azure/azure-quickstart-templates/blob/master/LICENSE).

<p>&nbsp;</p>
© 2017 Teradici Corporation. All Rights Reserved.
<p>&nbsp;</p>