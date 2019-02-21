# PHPUK AWS Example LAMP setup

## Pre-requisites

Install the following locally:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html#install-tool-pip)
* [Packer](https://www.packer.io/intro/getting-started/install.html#precompiled-binaries)
* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

In all cases ensure these are accessible in your `$PATH`, i.e. typing `aws`, `packer version` or `terraform version` in a terminal should show the relevant help info or versions.

## Configuring AWS on your local environment

The **tl;dr** of the above instructions to install awscli is to run:

```
sudo pip install awscli
aws configure
```

On the configure step you will need to enter an access key and secret key. You can find those for a [root account here](https://console.aws.amazon.com/iam/home). In production you will **not** want to use root account keys. The next easiest would be a custom account with the `AdministratorAccess` policy, but for real security in a multi-user environment you would do well to [investigate IAM roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)

Once configured the easiest way to test awscli is to run:

```
aws sts get-caller-identity
```

This prints some basic information about the user making the call (i.e. the user to whom your credentials belong).

## An introduction to Terraform

AWS has a lot of moving parts required to create a robust infrastructure, but their automation tools allow you to easily manage, tweak and replicate this infrastructure.

Using Terraform we can specify a desired state for our infrastructure to be in. This uses our local AWS credentials to examine our account and make changes where required. Only resources previously managed by Terraform are checked - i.e. Terraform will not remove anything it finds in our account, though sometimes naming restrictions may mean Terraform cannot proceed (e.g. S3 buckets must have a unique name).

Before running Terraform from this project we must create a `terraform.tfvars` file. Copy the sample file (`terraform.sample.tfvars`) and set each variable as follows:

* `aws_id`: This is a numerical ID unique to every account and used in some access controls. You can find it when signed in [on your account page](https://console.aws.amazon.com/billing/home?#/account)
* `domain`: Normally this could be any domain you wanted; during the workshop you'll be best using a subdomain of my (unused) domain "1webservices.co.uk". The reason for this is that otherwise you need your domain name servers hosted on the AWS account you are using
* `zone_id`: Based on the above this is already filled in for you; if you did have your own domain already controlled by AWS Route 53 then you could use the Zone ID for that domain
* `vpc_id`: Every account comes with a default Virtual Private Cloud which is a private network you control. The default VPC will be set up with subnets, routes and an internet gateway. You can find [the ID from the VPC console](https://eu-west-1.console.aws.amazon.com/vpc/home?region=eu-west-1#vpcs:sort=VpcId)

The next two configuration items are S3 Bucket names. The one concern with S3 names is that they must be _globally unique_ so two accounts cannot have an S3 bucket with the same name. A good idea could be to prefix your bucket name with your name and the name of the project you are working on - this means you avoid collisions with other people on this course and with your own future projects.

* `s3-load-balancer-logs`: This bucket stores access logs from your load balancer. We won't use these but it's wise to store them
* `s3-deploy`: The deploy bucket name we already used.

The variable `aws_region` is already set to `eu-west-1` which is Ireland. The Ireland region tends to get new features first out of the EU regions and has 3 availability zones, making it good for high availability. This will mean data is stored in Ireland, and could be subject to uncertainty if the UK passes data sovereignty laws after Brexit. There is a region `eu-west-2` in London however this only has 2 availability zones and receives new features much later (e.g. it received EFS only recently, many years after Ireland)

__PHPUK only__ based on the above requirement to use a domain/zone controlled by my own account, you need access keys to allow that action on my account. These are filled in (prefixed by `m1ke_`) in the config file with some charaters missing - those will be provided on screen.

Unfortunately Terraform has issues using one key (mine) inline and another (yours) from your system-level AWS config. So you will need to fill in the two `aws_` access/secret key variables with the keys you configured above. To check these keys you can run `cat ~/.aws/credentials` or generate a new key (you can have up to 2 on an account) using the IAM links above.

## Deploying your application

Before we run a deploy or set up the variables for our deploy tool (below) we need a couple of AWS resources, namely an S3 bucket and SNS (Simple Notification Service) topics which we can receive notifications from. A helper is provided to pre-set these up:

```
bash apply-first
```

This should create a bucket and two SNS topics, and output your topic ARNs (you'll need them below).

Now pull the repo from `https://github.com/M1ke/aws-s3-pull-deploy`. Follow the `README.md` in that project to insert variables - some will be the same as those set above.

AWS load balancers carry out health checks. The examples in the pull deploy repository contain health check paths already. If using your own app, ensure that it can respond with a 200 status for requests made to /aws-health-check

## Creating server images

Before we create web servers we need a base AMI. This stands for Amazon Machine Image and is basically a snapshot of an instance hard drive, along with system level config information. A variety of base (unmodified OS) and custom AMIs are available on AWS. Some of these are built by companies with their software installed, and some may require a license fee payment.

An AMI allows you to save a known good configuration of a server. It offers reliability without sacrificing flexibility. Using a tool called Packer we can build this AMI. Packer creates temporary instances, runs custom install scripts on them and, if successful, saves down an AMI that we can use to spin up new servers.

Run packer with:

```
packer build ami-web/server-web.json
```

Packer will report the various AWS CLI commands it issues as well as the output from install scripts. Once complete the AMI will be saved along with a date and time. If Packer fails for any reason no new AMI is created, avoiding you accidentally deploying servers based off an AMI with an unexpected configuration.

## Creating infrastructure

Now we have an image to create servers with we can run:

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

Once the process completes we're done running Terraform and can proceed exploring what we have just created.
