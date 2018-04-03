# Jenkins and Terraform demo

## Install terraform into Jenkins host

```
$ sudo apt install -y unzip

$ wget https://releases.hashicorp.com/terraform/0.11.5/terraform_0.11.5_linux_amd64.zip

$ unzip terraform_0.11.5_linux_amd64.zip
$ sudo mv terraform /usr/local/bin/
```

## How can we handle tfstate file?
TF State file is important to keep construction of infrastructure.
