# Deploy Teradici Cloud Access Software on Azure

**Important!** This method of deploying Cloud Access Software on Azure is deprecated and is no-longer being maintained. To deploy Cloud Access Software on Azure please use [Teradici Cloud Access Manager]("https://github.com/teradici/deploy") or for more customized deployments, consult Teradici Cloud Access Software documentation for install and usage instructions:
* [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software)
* [Teradici Community Forum](https://communities.teradici.com/topics/cloud+access+software.html)
* [Teradici Technical Support](https://techsupport.teradici.com)

## Deployment Steps

Use these steps to deploy a virtual machine on Azure, running Windows Server 2016, and the latest version (2.9.0) of the [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software) - Standard Edition or Graphics Edition. 

All resources required to run the Teradici PCoIP Standard or Graphics Agent (components of Teradici Cloud Access Software) will be created and configured in your Azure subscription under a new resource group.

Once deployed, you will be able to connect to the PCoIP agent using the Teradici PCoIP Software Client.

### Before You Begin

* Set up a Microsoft Azure account and ensure you have permissions to create new resource groups and resources. If you don't already have an account, you can sign up for a [free Microsoft Azure account](https://azure.microsoft.com/free/). 
* Use an existing or [trial](http://connect.teradici.com/cas-trial) registration code for a Teradici PCoIP Standard or Graphics Agent.
* Download and install the [Teradici PCoIP Software Client](http://www.teradici.com/product-finder/client-downloads).

### Deploy the PCoIP Agent

Choose whether you want to deploy a Teradici PCoIP Standard or Graphics Agent and deploy it to Azure by clicking the *Deploy to Azure* button.

**Note:** By clicking one of the following *Deploy to Azure* buttons, you accept the terms of the Teradici Cloud Access Software [End User License Agreement](http://www.teradici.com/pdf/teradici-cloud-access-software-eula.pdf). By clicking the *Deploy to Azure* button to deploy a Teradici PCoIP Graphics Agent on a NV instance type virtual machine, you have read and agree to be bound by the [software license](http://www.nvidia.com/content/DriverDownload-March2009/licence.php?lang=us) for use of the third-party drivers.
   
#### Teradici PCoIP Standard Agent

To deploy a PCoIP **Standard** Agent on a [Standard_D2_v2](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general)<sup>[1]</sup> type virtual machine, click:
    
<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fteradici%2Fpcoip-agent-azure-templates%2Fmaster%2Fazure-deploy-sa.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>

#### Teradici PCoIP Graphics Agent

To deploy a PCoIP **Graphics** Agent on a [NV6](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu)<sup>[1]</sup> type virtual machine, click:

<a target="_blank" href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fteradici%2Fpcoip-agent-azure-templates%2Fmaster%2Fazure-deploy-ga.json"><img src="http://azuredeploy.net/deploybutton.png"/></a>


**Next, follow these steps:**

1. When prompted by the Azure portal, enter your Azure credentials.
2. When presented with the Azure Custom deployment screen, set these options:
    * *Subscription:* Select your subscription.
    * *Resource group:* Select **Create new**, then enter a resource group name (for example, *teradici_trial*).
    * *Location:* Select a location. 
        * **Note**: PCoIP **Graphics** Agent deployments require locations that support NV instance types. Currently, this is limited to the following locations: EAST US, NORTH CENTRAL US, SOUTH CENTRAL US, SOUTHEAST ASIA, or WEST EUROPE.
    * *Operating System:* Select operating system you want to use from dropdown.
    * *User Name:* Enter a user name<sup>[2]</sup> for the virtual machine, this will be used for your PCoIP session connection login.
    * *Password:* Enter a password<sup>[2]</sup> for the virtual machine.
    * *Registration Code:* Enter the registration code you received from Teradici.
* Review the Microsoft Terms and Conditions. Indicate your agreement by selecting **I agree to the terms and conditions stated above**.
* Enable **Pin to dashboard** if you wish to monitor the status of your deployment from the Azure dashboard.
* Click **Purchase**.

Deployment will now start and may take up to 15 minutes to complete. You can track the status of the deployment via the Azure Notifications drop-down.   **Note:** Regular Azure charges<sup>[1]</sup>  will apply to your Microsoft Azure account for this deployment.

Deployments may fail for various reasons. Should a failure occur, delete the resource group you created (via the Azure portal) and reattempt the deployment. 
**Note:** Only single agent deployments to a newly created resource group are currently supported.

##### Footnotes

 <sup>[1]</sup> See the [Azure Pricing Guide](https://azure.microsoft.com/pricing/details/virtual-machines/windows/) for estimated virtual machine pricing.

 <sup>[2]</sup> See [FAQs about Windows Virtual Machines](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq) or [FAQs about Linux Virtual Machines](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/faq) for Azure username and password requirements.

## Connect to the PCoIP Agent

**To connect to your recently deployed PCoIP agent, find your virtual machine’s IP address:**
1. Log in to the [Azure Portal](https://portal.azure.com/).
2. Click **Resource groups**, find the resource group you created during deployment, and select it.
3. Click the public IP address resource (named **pcoip-agent-pip**) to obtain the IP address.

**To establish a connection to the virtual machine with the PCoIP agent you deployed on Azure:**
1.	Launch the PCoIP Software Client.
2.	In the *Host Address* field, enter the IP address obtained above and click **Next**.
3.	Enter the user name and password for the virtual machine, and click **Login**.

You now have access to a PCoIP cloud-delivered desktop.

#### Known Issue(s)
* Initial windowed mode connections to a newly deployed PCoIP **Graphics** Agent may result in a blank screen. To clear the blank screen, resize the window or connect in full-screen mode.
* Reset password does not work from Azure portal for Linux agent if you have a capital letter in your user name. 
* Currently Graphic Agent is not supported on Linux due to driver issues on RHEL 7.4. Please check back in later time. 

## Common error codes for Linux Deployment 
100 -- Adding the Teradici repository failed.

101 -- Installing PCoIP Agent failed.

102 -- Registering PCoIP Agent license code failed.

103 -- Downloading Nvidia driver failed.

104 -- Installing Nvidia driver failed.

105 -- Unknown Agent Type.

Please contact Teradici support if you see other error codes.

## Delete the PCoIP Agent

When you are finished using the PCoIP agent, and in order to avoid unwanted charges, you may want to delete the PCoIP agent and all associated resources from your Microsoft Azure subscription.

**To remove the PCoIP agent and all associated resources:**
1. Log in to the [Azure Portal](https://portal.azure.com/) and click **Resource groups**.
2. Find and right-click the resource group name you created and choose **Delete**.
3. Enter the resource group name when prompted and click **Delete**.


## Additional Resources
If you have suggestions for improvements or issues with the deployment scripts, open a discussion in the [Teradici Community Forum](https://communities.teradici.com/topics/cloud+access+software.html). Alternatively, visit [Teradici Technical Support](https://techsupport.teradici.com).

For additional information about Teradici Cloud Access Software, visit [Teradici Cloud Access Software](http://www.teradici.com/products-and-solutions/pcoip-products/cloud-access-software) or refer to the [Teradici Cloud Access Software 2.9.0 documentation](https://techsupport.teradici.com/link/portal/15134/15164/Article/3110/Cloud-Access-Software-2-9-Beta-Components).


## Credits

Some content in this article is based on the Azure quick start templates, © Microsoft Azure, licensed under the [MIT license](https://github.com/Azure/azure-quickstart-templates/blob/master/LICENSE).

<p>&nbsp;</p>
© 2017 Teradici Corporation. All Rights Reserved.
<p>&nbsp;</p>