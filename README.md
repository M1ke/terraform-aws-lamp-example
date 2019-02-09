# PHPUK AWS Example LAMP setup

## Pre-requisites

Install the following locally:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html#install-tool-pip)
* [Packer](https://www.packer.io/intro/getting-started/install.html#precompiled-binaries)
* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

In all cases ensure these are accessible in your `$PATH`, i.e. typing `type aws`, `type packer` or `type terraform` in a terminal should show the path to the relevant executable.

## Configuring AWS on your local environment

_Mention about getting root keys, why this is bad etc._

```
sudo pip3 install awscli
aws configure
```

## Deploying your application

Using the S3 console create a bucket which will be used to deploy your application. The one concern with S3 names is that they must be _globally unique_ so two accounts cannot have an S3 bucket with the same name. A good idea could be to prefix your bucket name with your name and the name of the project you are working on - this means you avoid collisions with other people on this course and with your own future projects.

For any other options ensure that the bucket is specified as private; logs or versioning is not required. Make a note of the bucket name as this will be used in a moment.

Pull the repo from `https://github.com/M1ke/aws-s3-pull-deploy`. This tool contains two Python apps, `pull-deploy.py` and `push-deploy.py`. The former will be used on the server and isn't relevant locally but you may be interested in how it works. Both tools require a config, included in the repo as `config.sample.yml`. This has the following options that must be set:

* LOCK_DIR: This directory will be used to lock deployments. The best location would be `/efs/deploy`
* BUCKET: The name of the bucket you just chose
* DOMAIN: The domain that will be created on web servers at `/var/www/your.domain.com`
* NICKNAME: A short name for your site to allow multiple sites to deploy from one bucket
* EMAIL_NOTIFY: The email address to send reports of deployments or errors to
* EMAIL_FROM: Must be the same domain as set above, e.g. "deploy@your.domain.com"
* OWNER: The owning user/group of all deployed files. On an apache setup this would often be 'www-data'
* CMD: An optional line of script to eval at the end of the deploy process, e.g. create files, load crontab

Once this is created save as `config.yml` and run `python3 push-deploy.py --show` to check the config.

To deploy a directory run:

```
python3 push-deploy.py --deploy=/path/to/directory
```

NB: this will ignore the `.git` directory but copy all other dotfiles. It will also copy the config file.

AWS load balancers carry out health checks. Ensure your application can respond with a 200 status for requests made to /aws-health-check

## Creating server images

First we need a base AMI. This stands for Amazon Machine Image and is basically a snapshot of an instance hard drive, along with system level config information. A variety of base (unmodified OS) and custom AMIs are available on AWS. Some of these are built by companies with their software installed, and some may require a license fee payment.

An AMI allows you to save a known good configuration of a server. It offers reliability without sacrificing flexibility. Using a tool called Packer we can build this AMI. Packer creates temporary instances, runs custom install scripts on them and, if successful, saves down an AMI that we can use to spin up new servers.

Run packer with:

```
packer build ami-web/server-web.json
```

Packer will report the various AWS CLI commands it issues as well as the output from install scripts. Once complete the AMI will be saved along with a date and time. If Packer fails for any reason no new AMI is created, avoiding you accidentally deploying servers based off an AMI with an unexpected configuration.

## An introduction to Terraform

AWS has a lot of moving parts required to create a robust infrastructure, but their automation tools allow you to easily manage, tweak and replicate this infrastructure.

Using a tool called Terraform we can specify a desired state for our infrastructure to be in. This uses our local AWS credentials to examine our account and make changes where required. Only resources previously managed by Terraform are checked - i.e. Terraform will not remove anything it finds in our account, though sometimes naming restrictions may mean Terraform cannot proceed (e.g. S3 buckets must have a unique name).

Before running Terraform from this project we must create a `terraform.tfvars` file. Copy the sample file (`terraform.sample.tfvars`) and set each variable as follows:

* `aws_id`: This is a numerical ID unique to every account and used in some access controls. You can find it when signed in [on your account page](https://console.aws.amazon.com/billing/home?#/account)
* `domain`: What domain do you plan to use for testing? Most likely you'll choose a subdomain of an existing domain you own. This domain will need to be managed by AWS Route53 already. If not you can register a new domain directly inside Route53 for relatively cheap
* `zone_id`: Once you decide on a domain you require the Zone ID of the root domain. E.g. if you wish to use "phpuk.some-domain.com" you need to go to the Route53 console and find this domain - the Zone ID is shown in the rightmost column by default
* `vpc_id`: Every account comes with a default Virtual Private Cloud which is a private network you control. The default VPC will be set up with subnets, routes and an internet gateway. You can find the ID from the VPC console, or create a new VPC (please ensure this has external internet access for now)

The next two configuration items are S3 Bucket names.

* `s3-load-balancer-logs`: This bucket stores access logs from your load balancer. We won't use these but it's wise to store them
* `s3-deploy`: The deploy bucket name we already used.

The variable `aws_region` is already set to `eu-west-1` which is Ireland. The Ireland region tends to get new features first out of the EU regions and has 3 availability zones, making it good for high availability. This will mean data is stored in Ireland, and could be subject to uncertainty if the UK passes data sovereignty laws after Brexit. There is a region `eu-west-2` in London however this only has 2 availability zones and receives new features much later (e.g. it received EFS only recently, many years after Ireland)

## Creating infrastructure

We first need to tell Terraform we already created part of the infrastructure earlier: our deployment S3 bucket. This is simple:

```
terraform import aws_s3_bucket.deploy BUCKET_NAME
```

Now Terraform is set up we can run:

```
terraform plan
```

This should print a list of resources it will create. At this point you'd not expect any resources to be getting destroyed. It may try and adjust your deployment S3 bucket but this will be safe. Any issues at this point are likely caused by name/resource collisions - check your S3 bucket names and that the VPC, account and Zone IDs are correct.

Assuming no issues we can run:

```
terraform apply
```

This runs the same plan as above and then asks you to type "yes" to confirm. Any other item entered will result in the apply being cancelled. Once Terraform is running _do not cancel it_ as you'll end up with infrastructure in an unknown state. The apply can take a while as some resources require multiple API calls to create and Terraform checks they are functioning correctly.

During this process servers are created which will automatically install the pull deploy tool and run a deploy. Once the load balancer detects the `/aws-health-check` responds with a 200 code it will approve the deployment. 
