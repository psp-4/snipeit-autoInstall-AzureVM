# Automated Installation of Snipe-IT on Azure VM using Terraform & Shell Scripting
1.  Clone this repository using

     ```
      git clone https://github.com/psp-4/snipeit-autoInstall-AzureVM
     ```
2.  Run the following commands one after the another.
     *(Before proceeding further make sure Terraform is installed in your system and Azure credentials are configured in the Command line)*
    
     ```
      terraform init
     ```
     
     ```
      terraform validate
     ```
     
     ```
      terraform plan
     ```
     
     ```
      terraform apply
     ```
3.    Then check the deployment using the `public IP` displayed at the end of Terraform execution.
