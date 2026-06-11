# Minecraft ECS Automation Project

## Background: What Will We Do? How Will We Do It?

I was recently hired by Acme Corp as a system administrator. I heard that the previous system administrator was caught by the information security team for watching adult content on a work computer, and he was fired in less than a week. Human Resources was very ruthless. Because of that, my manager told me that the most urgent task is to restore the Minecraft server, since the employees are becoming more and more impatient.

After reviewing the previous system administrator's project, I found that many tasks were completed manually. Therefore, I decided to change the manual deployment process into an automated deployment process.

After my review, I found that the previous Minecraft server was deployed by going into the AWS Management Console, manually creating the server, configuring the network, setting up security groups, installing Java, downloading the Minecraft server, and starting the service. Running this full process manually is complicated and requires careful attention to many details. Therefore, my goal is to automate these steps.

To achieve this, I decided to use tools that can automate the deployment process, including shell scripts, Terraform, Docker, and AWS CLI. The whole process does not require going into the AWS Management Console, and it also does not require SSH access to manually install Java, download the Minecraft server, or start the service on the server.

After researching the project more deeply, this project uses the following tools and technologies.

---

## Main Technologies Used in This Project

* Docker: I use Docker to package the Minecraft server into a container image. This allows the Minecraft server to run in a consistent environment and reduces problems caused by differences between machines.

* Amazon ECR: ECR is used to store the Docker image. Since ECS Fargate needs to pull an image from a container registry, the locally built Minecraft image needs to be uploaded to ECR first.

* Terraform: After doing research, I found that Terraform can create AWS resources through code. Therefore, I use Terraform to create the ECS, EFS, NLB, security groups, and logging resources required for this project.

* Amazon ECS Fargate: ECS Fargate is used to run the Minecraft server container. Compared with EC2, this approach does not require manually managing servers or SSHing into an instance to configure the environment.

* Amazon EFS: EFS is used to store Minecraft server data. This allows the Minecraft world data to remain available even if the ECS task or container is restarted.

* Network Load Balancer: NLB is used to forward external traffic to the Minecraft server. Minecraft uses TCP port 25565 by default, so this project exposes port 25565 through the NLB.

* nmap: nmap is used to verify whether the Minecraft server has been successfully deployed. I use nmap to scan port 25565 and confirm that the server is in the `open` state.

---

## Project Deployment Logic

After deciding which tools to use for this project, the next step is to define the automation workflow.

I decided to follow the general workflow used by the previous system administrator, but replace the manual steps with automated scripts.

The automated deployment process is divided into several stages.

First, the user runs the `bootstrap_ecr.sh` script on the local computer. This script uses Terraform to create an Amazon ECR repository. ECR is used to store the Minecraft Docker image that will be built later.

Next, the user runs the `build_push.sh` script. This script uses Docker to build the Minecraft server image locally and pushes that image to the ECR repository created in the previous step.

Then, the user runs the `apply_infra.sh` script. This script uses Terraform to create the main AWS resources needed to run the Minecraft server, including ECS Fargate, EFS, Network Load Balancer, security groups, and CloudWatch Logs. ECS Fargate runs the Minecraft container, EFS stores the Minecraft data, NLB exposes port 25565, security groups control network access, and CloudWatch Logs stores the Minecraft container logs. Since this project does not SSH into the server, CloudWatch Logs is useful for checking whether the server started correctly or whether any errors occurred.

After the infrastructure is created, the user runs the `test.sh` script. This script uses nmap to scan the NLB on port 25565 and confirms whether the Minecraft server has started successfully and can be accessed externally.

Finally, the project also provides the `redeploy_test.sh` script. This script restarts the ECS service and runs nmap again to test whether the server comes back online. This step proves that the Minecraft server can recover after a restart, and because the server data is stored on EFS, the data will not be lost when the container restarts.

---

## Requirements: What Does the User Need to Configure?

Before running the automated pipeline, the user needs to prepare the local environment. This project is not deployed by manually clicking through the AWS Management Console. Instead, it uses the local terminal, shell scripts, Terraform, Docker, and AWS CLI to create AWS resources.

First, the user needs an AWS account. This can be a regular AWS account or an AWS Academy Learner Lab account. Since this project creates ECR, ECS, EFS, Network Load Balancer, security groups, and CloudWatch Logs, the user must be able to access AWS through AWS CLI.

Second, the user needs to configure AWS CLI credentials. If AWS CLI is not configured correctly, Terraform and the scripts will not have permission to create AWS resources, and the deployment pipeline will fail.

The user can verify AWS CLI access with:

```bash
aws sts get-caller-identity
```

If this command returns the AWS account ID and user ARN, then AWS CLI credentials are configured correctly.

If using AWS Academy Learner Lab, the user needs to copy the following values from the AWS Details page:

```text
AWS Access Key ID
AWS Secret Access Key
AWS Session Token
Region
```

Then run:

```bash
aws configure
```

Enter the following values:

```text
AWS Access Key ID
AWS Secret Access Key
AWS Session Token
Default region name: us-east-1
Default output format: json
```

This project uses the following AWS region by default:

```text
us-east-1
```

---


## Windows User Note

This project is mainly designed to be run from a Linux shell environment.

For Windows users, I recommend using one of the following options:

```text
Option 1: Windows Subsystem for Linux (WSL) with Ubuntu
Option 2: An Ubuntu virtual machine
Option 3: A cloud-based Ubuntu instance
```

The installation commands in this README are written for Ubuntu/Debian-based systems. If the user is running Windows directly, they should first install WSL with Ubuntu or use an Ubuntu virtual machine, then run the commands inside the Linux terminal.

This makes the script execution more consistent because the project uses Bash scripts, Terraform, Docker, AWS CLI, jq, and nmap.

## Required Tools and Installation Methods

To run this automated deployment pipeline, the user needs to install the following tools:

* AWS CLI: Used to access AWS from the command line and allow Terraform to create AWS resources.
* Terraform: Used to automatically create and manage AWS infrastructure.
* Docker: Used to build the Minecraft server Docker image.
* nmap: Used to test whether the Minecraft server's port 25565 is open.
* jq: Used by scripts to process JSON output from AWS CLI.
* Git: Used to manage the project code and push it to GitHub.

## Required Tool Versions

This project was tested with the following tool versions:

* AWS CLI: 2.x
* Terraform: 1.15.5
* Docker: 27.5.1
* nmap: 7.94SVN
* jq: 1.7
* Git: 2.45.2

* Or newest version is also acceptable

The installation method depends on the user's operating system. The commands below are for Ubuntu/Debian-based Linux systems.

### Install AWS CLI

```bash
sudo apt update
sudo apt install -y unzip curl

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Check the installation:

```bash
aws --version
```

### Install Terraform

```bash
sudo apt update
sudo apt install -y gnupg software-properties-common curl

wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y terraform
```

Check the installation:

```bash
terraform -version
```

### Install Docker

```bash
sudo apt update
sudo apt install -y docker.io

sudo systemctl enable docker
sudo systemctl start docker
```

Add the current user to the Docker group:

```bash
sudo usermod -aG docker $USER
```

After running this command, log out and log back in, or restart the terminal session.

Check the installation:

```bash
docker --version
docker ps
```

### Install nmap

```bash
sudo apt update
sudo apt install -y nmap
```

Check the installation:

```bash
nmap --version
```

### Install jq

```bash
sudo apt update
sudo apt install -y jq
```

Check the installation:

```bash
jq --version
```

### Install Git

```bash
sudo apt update
sudo apt install -y git
```

Check the installation:

```bash
git --version
```

### Verify All Required Tools

After installing the tools, the user can verify everything with:

```bash
aws --version
terraform -version
docker --version
nmap --version
jq --version
git --version
```

If all commands show version numbers, the local environment is ready.

---

## Are Credentials or Command Line Interfaces Required?

Yes. This project requires AWS credentials and AWS CLI.

Since all AWS resources are created through scripts and Terraform, the user must configure AWS CLI credentials first. Otherwise, Terraform will fail when creating ECR, ECS, EFS, NLB, and security groups.

This project does not require the user to manually create resources in the AWS Management Console. It also does not require SSH access to the server. All operations are completed through the local terminal.

In summary, the user needs:

```text
AWS account
AWS CLI credentials
AWS CLI command line access
Terraform
Docker
nmap
jq
Git
```

Once these tools and credentials are ready, the user can run the scripts to complete the deployment.

---

## Does the User Need Environment Variables or Other Configuration?

If the user has already configured AWS credentials with `aws configure` and is using long-term credentials, then no additional environment variables are usually required.

If the user is using AWS Academy Learner Lab, the credentials are temporary, so the session token usually needs to be exported:

```bash
export AWS_SESSION_TOKEN="your-session-token"
```

If GitHub Actions is used, the following repository secrets need to be configured in the GitHub repository:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION
```

The region should be:

```text
AWS_REGION=us-east-1
```

These secrets allow the GitHub Actions runner to access AWS and run the same deployment pipeline automatically.

For local manual deployment, GitHub Actions secrets are not required as long as the local AWS CLI credentials are configured correctly.

---

## Project Structure

To make the project easier to understand, I separated the files based on their functions. The main project structure is:

```text
minecraft-ecs-automation/
├── Dockerfile
├── README.md
├── .dockerignore
├── .gitignore
├── docker/
│   └── entrypoint.sh
├── scripts/
│   ├── bootstrap_ecr.sh
│   ├── build_push.sh
│   ├── apply_infra.sh
│   ├── test.sh
│   ├── redeploy_test.sh
│   └── destroy.sh
├── terraform/
│   ├── bootstrap/
│   └── infra/
└── .github/
    └── workflows/
        └── deploy.yml
```

The `scripts/` directory stores the automation scripts that the user needs to run. The `terraform/` directory stores the Terraform configuration files. The `docker/` directory stores the entrypoint script used when the Minecraft container starts. The `.github/workflows/` directory stores the GitHub Actions workflow configuration.

---

## Pipeline Diagram

The overall automation workflow is:

```text
Local Computer
        |
        v
bootstrap_ecr.sh
Create Amazon ECR repository
        |
        v
build_push.sh
Build the Minecraft server Docker image
and push the image to ECR
        |
        v
apply_infra.sh
Use Terraform to create ECS, EFS, NLB,
security groups, and CloudWatch Logs
        |
        v
test.sh
Use nmap to test TCP port 25565 on the NLB
and confirm that the Minecraft server is running
        |
        v
redeploy_test.sh
Restart the ECS service
and use nmap again to confirm the server recovered
```

The order of this workflow is important. ECS Fargate needs to pull the Docker image from ECR, so the ECR repository must be created first. Then the Docker image can be built and pushed to ECR. After that, Terraform can create the ECS service and allow the ECS task to start the Minecraft server using that image.

In other words, the dependency order is:

```text
ECR repository
    ↓
Docker image
    ↓
ECS task definition
    ↓
ECS service
    ↓
NLB external access
    ↓
nmap test
```

---

## Commands to Run, with Explanations

First, go into the project directory:

```bash
cd minecraft-ecs-automation
```

Then verify that AWS CLI can access AWS:

```bash
aws sts get-caller-identity
aws configure get region
```

If these commands return valid results, the user can start running the automation scripts.

---

### Step 1: Create the ECR Repository

```bash
./scripts/bootstrap_ecr.sh
```

This script creates the Amazon ECR repository. ECR must be created first because ECS needs to pull the Docker image from ECR later.

After the script succeeds, it creates a local file:

```text
.ecr_uri
```

This file stores the ECR repository URL. Later scripts read this file.

---

### Step 2: Build and Push the Docker Image

```bash
./scripts/build_push.sh
```

This script uses Docker to build the Minecraft server image and then pushes the image to the ECR repository created in the previous step.

After this step is complete, ECS Fargate can pull this image from ECR and run the Minecraft server container.

---

### Step 3: Create AWS Infrastructure

```bash
./scripts/apply_infra.sh
```

This script uses Terraform to create the main AWS resources, including:

```text
ECS Fargate cluster
ECS task definition
ECS service
EFS file system
EFS mount targets
Network Load Balancer
Target group
Security groups
CloudWatch Logs
```

This is the core deployment step. It creates the cloud environment where the Minecraft server actually runs.

After the script succeeds, it creates a local file:

```text
.nlb_dns
```

This file stores the DNS address of the Network Load Balancer. This address is used later for testing and connecting to the Minecraft server.

---

### Step 4: Test the Minecraft Server with nmap

```bash
./scripts/test.sh
```

This script uses nmap to scan port 25565 on the NLB and confirm that the Minecraft server can be accessed externally.

The main test command is:

```bash
nmap -sV -Pn -p T:25565 <server-address>
```

A successful result should look like:

```text
25565/tcp open  minecraft
```

This means the Minecraft server is open through the Network Load Balancer.

If the first test shows:

```text
25565/tcp filtered minecraft
```

it usually means the ECS task, Minecraft server, or NLB target is not fully ready yet. Wait 1 to 2 minutes and run the test again:

```bash
./scripts/test.sh
```

---

### Step 5: Test Restart Recovery

```bash
./scripts/redeploy_test.sh
```

This script changes the ECS service desired count from 1 to 0, and then changes it back from 0 to 1. This simulates the Minecraft server container stopping and starting again.

The purpose of this test is not to create a new architecture. Instead, it proves that the server can recover after a restart. Since the Minecraft data is stored in EFS, the data will not be lost when the container restarts.

The script also runs nmap again at the end to confirm that the server is back online.

---

## Full Command Sequence

For a full deployment, run the commands in this order:

```bash
cd minecraft-ecs-automation

./scripts/bootstrap_ecr.sh
./scripts/build_push.sh
./scripts/apply_infra.sh
./scripts/test.sh
./scripts/redeploy_test.sh
```

This order is the main automation pipeline for the project.

---

## How to Connect to the Minecraft Server

After `apply_infra.sh` succeeds, the Minecraft server address is saved in:

```text
.nlb_dns
```

The user can show the server address with:

```bash
cat .nlb_dns
```

Minecraft Java Server uses TCP port:

```text
25565
```

Therefore, the full Minecraft server address format is:

```text
<NLB-DNS-NAME>:25565
```

Example:

```text
mc-ecs-nlb-xxxxxxxx.elb.amazonaws.com:25565
```

If using the Minecraft client, enter this address in the Multiplayer server address field.

If only verifying whether the server is online, use nmap:

```bash
nmap -sV -Pn -p T:25565 $(cat .nlb_dns)
```

A successful result should show:

```text
25565/tcp open  minecraft
```

This means the Minecraft server has been successfully deployed and can be accessed through the Network Load Balancer.

---

## GitHub Actions

In addition to running the scripts locally, this project also includes a GitHub Actions workflow:

```text
.github/workflows/deploy.yml
```

The goal of this workflow is to automatically run the deployment process after a push to GitHub. It runs steps similar to the local scripts, including configuring AWS credentials, creating ECR, building and pushing the Docker image, deploying ECS/EFS/NLB, and running the nmap test.

If using GitHub Actions, the following repository secrets must be configured first:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION
```

---

## Extra Credit Features

This project includes several extra credit features.

First, this project uses a Docker image. The Minecraft server is packaged into a container image through the Dockerfile and uploaded to Amazon ECR.

Related files include:

```text
Dockerfile
docker/entrypoint.sh
scripts/build_push.sh
```

Second, this project uses ECS Fargate instead of EC2. Because of this, the user does not need to SSH into a server to install Java, download the Minecraft server, or start the service manually.

Related files include:

```text
terraform/infra/ecs.tf
```

Third, this project uses EFS to store Minecraft data outside the container. EFS is mounted into the container at:

```text
/data
```

This means that even if the ECS task or container restarts, the Minecraft world data can still be preserved.

Related files include:

```text
terraform/infra/efs.tf
terraform/infra/ecs.tf
```

Finally, this project includes a GitHub Actions workflow. This workflow can run the deployment pipeline automatically when code is pushed.

Related files include:

```text
.github/workflows/deploy.yml
```

---

## Cleanup

After testing the project, the user can run:

```bash
./scripts/destroy.sh
```

This script deletes the AWS resources managed by Terraform, including ECS, EFS, NLB, ECR, security groups, and CloudWatch Logs.

Do not run this script before recording the demo because it will delete the deployed Minecraft server.

Also, if some resources were created by GitHub Actions but the Terraform state was not saved locally, `destroy.sh` may not be able to delete those resources. In that case, the user needs to clean up the remaining resources manually with AWS CLI.

---

## Demo Recording Suggestions

When recording the video demo, the user can show the following commands:

```bash
cd minecraft-ecs-automation

git remote -v
git status --short
git log --oneline -1

aws sts get-caller-identity
aws configure get region

terraform -version
docker --version
nmap --version
jq --version
git --version

ls
ls scripts
ls terraform
ls .github/workflows

./scripts/bootstrap_ecr.sh
./scripts/build_push.sh
./scripts/apply_infra.sh
./scripts/test.sh
./scripts/redeploy_test.sh
```

During the recording, explain that the whole process is completed through the terminal, shell scripts, Terraform, and AWS CLI. The AWS Management Console is not used, and there is no SSH access to any server.

At the end, the most important output to show is the nmap result:

```text
25565/tcp open  minecraft
```

This result shows that the Minecraft server has been successfully deployed and can be accessed externally.

---

## Summary

The goal of this project is to change the manual Minecraft server deployment process into an automated deployment process.

By using Docker, Amazon ECR, Terraform, ECS Fargate, EFS, Network Load Balancer, and nmap, this project can automatically build the Minecraft server image, create AWS resources, start the service, test the port, and verify restart recovery.

The whole process does not require the AWS Management Console, and it does not require SSH access to manually install or start the server.

## References / Sources

During this project, I used official documentation and technical references to understand how each tool and AWS service should be configured.

- Terraform AWS Provider Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs  
  I used this documentation to understand how to define AWS resources with Terraform.

- Terraform `aws_ecs_service`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service  
  I used this resource to create and manage the ECS service.

- Terraform `aws_ecs_task_definition`: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition  
  I used this resource to define how the Minecraft container should run on ECS.

- Amazon ECS Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html  

- AWS Fargate Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html  

- Amazon ECR Documentation: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html  
  I used this documentation to understand how ECR stores Docker images for ECS.

- Amazon ECR Docker Push Documentation: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html  
  I used this documentation to understand how to authenticate Docker with ECR and push images.

- Docker Documentation: https://docs.docker.com/  

- Dockerfile Reference: https://docs.docker.com/reference/dockerfile/  
  I used this reference when writing the Dockerfile for the Minecraft server.

- Amazon EFS Documentation: https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html  
  I used this documentation to understand how EFS provides persistent file storage.

- Amazon ECS EFS Volumes Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html  
  I used this documentation to understand how to mount EFS into an ECS task.

- Network Load Balancer Documentation: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html  

- Amazon ECS Logging and Monitoring: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-logging-monitoring.html  
  I used this documentation to understand how ECS task logs can be stored and monitored.

- ECS Logs to CloudWatch Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specify-log-config.html  
  I used this documentation to configure container logs with CloudWatch Logs.

- AWS CLI Documentation: https://docs.aws.amazon.com/cli/  

- AWS CLI Configuration Documentation: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html  

- Nmap Reference Guide: https://nmap.org/book/man.html  

- GitHub Actions Documentation: https://docs.github.com/en/actions  
  I used this documentation to create the optional GitHub Actions deployment workflow.

- GitHub Actions Secrets Documentation: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions  
