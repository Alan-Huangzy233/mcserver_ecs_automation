# Automated Minecraft Java Server Deployment on AWS ECS Fargate

## Background

This project automates the deployment of a Minecraft Java Edition server on AWS.

In Course Project Part 1, the Minecraft server was deployed manually on an EC2 instance. In Part 2, the deployment is converted into an automated infrastructure pipeline. Terraform provisions the AWS resources, Docker packages the Minecraft server, Amazon ECR stores the Docker image, Amazon ECS Fargate runs the container, Amazon EFS stores Minecraft server data outside the container, and a Network Load Balancer exposes the server on TCP port `25565`.

Because this implementation uses ECS Fargate instead of EC2, the public server endpoint is the Network Load Balancer DNS name instead of an EC2 instance public IP address.

The final server is verified with:

```bash
nmap -sV -Pn -p T:25565 <server_endpoint>
```

---

## Architecture

This project provisions the following AWS resources:

- Amazon ECR repository for the Minecraft Docker image
- Amazon ECS Fargate cluster, task definition, and service
- Amazon EFS file system for persistent Minecraft data
- EFS mount targets in the default VPC subnets
- Network Load Balancer listening on TCP port `25565`
- Target group for routing Minecraft traffic to the ECS task
- Security groups for ECS and EFS
- CloudWatch log group for ECS container logs

---

## Pipeline Diagram

```text
Local machine / VM
        |
        v
AWS Academy CLI credentials
        |
        v
Terraform bootstrap creates ECR
        |
        v
Docker builds Minecraft server image
        |
        v
Docker pushes image to ECR
        |
        v
Terraform provisions ECS Fargate, EFS, NLB, security groups, and logs
        |
        v
ECS Fargate runs Minecraft container
        |
        v
EFS is mounted at /data for persistent Minecraft world data
        |
        v
NLB exposes TCP 25565 to users
        |
        v
nmap verifies the Minecraft server
```

---

## Repository Structure

```text
minecraft-ecs-automation/
├── README.md
├── Dockerfile
├── docker/
│   └── entrypoint.sh
├── terraform/
│   ├── bootstrap/
│   │   ├── provider.tf
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── infra/
│       ├── provider.tf
│       ├── variables.tf
│       ├── data.tf
│       ├── security_groups.tf
│       ├── efs.tf
│       ├── ecs.tf
│       ├── nlb.tf
│       └── outputs.tf
├── scripts/
│   ├── 01_bootstrap_ecr.sh
│   ├── 02_build_push.sh
│   ├── 03_apply_infra.sh
│   ├── 04_test.sh
│   ├── 05_redeploy_test.sh
│   └── 99_destroy.sh
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## Requirements

The following tools are required on the local machine or VM:

- Git
- AWS CLI
- Terraform `>= 1.5.0`
- Docker
- nmap
- jq

The project was tested with:

```text
Terraform v1.15.5
Docker 27.5.1
Nmap 7.94SVN
jq 1.7
AWS CLI configured for us-east-1
```

---

## AWS Credentials

This project was designed for AWS Academy Learner Lab.

Start the Learner Lab, open the AWS Details section, and copy the AWS CLI credentials. Configure them locally in:

```bash
~/.aws/credentials
```

Example format:

```ini
[default]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_KEY
aws_session_token=YOUR_SESSION_TOKEN
```

Then configure the default region:

```bash
mkdir -p ~/.aws

cat > ~/.aws/config <<'AWS_CONFIG'
[default]
region=us-east-1
output=json
AWS_CONFIG
```

Verify the AWS credentials:

```bash
aws sts get-caller-identity
```

Do not commit AWS credentials to GitHub.

---

## How to Run the Deployment Locally

Clone the repository:

```bash
git clone <your-repository-url>
cd minecraft-ecs-automation
```

### 1. Create the ECR repository

```bash
./scripts/01_bootstrap_ecr.sh
```

This script initializes Terraform in `terraform/bootstrap`, creates the ECR repository, and saves the ECR URI to `.ecr_uri`.

### 2. Build and push the Docker image

```bash
./scripts/02_build_push.sh
```

This script logs in to Amazon ECR, builds the Minecraft Docker image, tags it, and pushes it to ECR as `latest`.

### 3. Provision ECS, EFS, and NLB infrastructure

```bash
./scripts/03_apply_infra.sh
```

This script uses Terraform to create the ECS Fargate service, EFS storage, Network Load Balancer, target group, listener, security groups, and CloudWatch log group.

At the end, it prints the Minecraft server address, for example:

```text
mc-ecs-nlb-xxxxxxxx.elb.us-east-1.amazonaws.com:25565
```

### 4. Verify the server with nmap

```bash
./scripts/04_test.sh
```

This script checks the ECS service status and runs:

```bash
nmap -sV -Pn -p T:25565 <nlb_dns_name>
```

Expected successful result:

```text
25565/tcp open  minecraft Minecraft 26.1.2
```

---

## How to Connect to the Minecraft Server

Use the Network Load Balancer DNS name and port `25565`.

Example:

```text
mc-ecs-nlb-xxxxxxxx.elb.us-east-1.amazonaws.com:25565
```

In Minecraft Java Edition:

1. Open Multiplayer.
2. Select Direct Connection or Add Server.
3. Enter the server address shown by Terraform.
4. Connect to the server.

If the Minecraft client is not available, use the required nmap verification:

```bash
nmap -sV -Pn -p T:25565 <nlb_dns_name>
```

---

## Docker Image

The Docker image uses Java 25 because the current Minecraft server JAR requires a newer Java runtime.

The container:

- Downloads the Minecraft Java server JAR
- Creates `/data` as the Minecraft working directory
- Accepts the Minecraft EULA
- Creates `server.properties` if it does not already exist
- Starts the Minecraft server on TCP port `25565`

The container entrypoint also handles shutdown signals. When the container receives `SIGTERM` or `SIGINT`, it sends the `stop` command to the Minecraft server so that the server can save the world before exiting.

---

## Persistent Storage with EFS

Minecraft is a stateful application because world data must survive restarts. In this project, the ECS task mounts Amazon EFS at:

```text
/data
```

The following Minecraft data is stored on EFS instead of inside the container image:

- `world/`
- `server.properties`
- `eula.txt`
- `logs/`
- Minecraft runtime data

This satisfies the extra-credit requirement to store ECS container data outside the container.

---

## ECS Restart Test

The project includes a controlled restart script:

```bash
./scripts/05_redeploy_test.sh
```

Because Minecraft is a stateful single-server application and the world data is stored on EFS, this script does not use a parallel rolling deployment. Instead, it performs a controlled scale-down and scale-up:

```text
desired count 1 -> 0
wait for tasks to stop
desired count 0 -> 1
wait for the task to run again
run nmap against the same NLB endpoint
```

This avoids two Minecraft containers writing to the same world data at the same time.

A successful restart test ends with:

```text
25565/tcp open  minecraft Minecraft 26.1.2
```

---

## Network Load Balancer

The Minecraft server runs inside an ECS Fargate task. ECS task IP addresses are not stable, so this project exposes the server through a Network Load Balancer.

The NLB listens on TCP port `25565` and forwards traffic to the ECS task.

Cross-zone load balancing is enabled so that the NLB can route traffic to the healthy Minecraft task even when DNS resolves to different NLB IP addresses.

---

## GitHub Actions

This repository includes a GitHub Actions workflow at:

```text
.github/workflows/deploy.yml
```

The workflow is configured to run on push to `main` or `master`, and it can also be started manually with `workflow_dispatch`.

The workflow performs these steps:

1. Check out the repository
2. Configure AWS credentials
3. Install required tools
4. Set up Terraform
5. Verify AWS identity
6. Bootstrap ECR
7. Build and push the Docker image
8. Deploy ECS, EFS, and NLB infrastructure
9. Test the Minecraft server with nmap

Required GitHub Actions secrets:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION
```

For AWS Academy Learner Lab, the session token expires. If the lab session is restarted or the credentials expire, the GitHub Actions secrets must be updated.

Important note: this class project uses local Terraform state. If infrastructure has already been created locally, running the full GitHub Actions deployment in a separate runner may conflict with existing resources unless the state is managed remotely or the existing local deployment is destroyed first.

---

## Cleanup

A cleanup script is included:

```bash
./scripts/99_destroy.sh
```

This script destroys the ECS/EFS/NLB infrastructure and then destroys the ECR repository.

Do not run this script before grading unless the deployment no longer needs to be verified.

---

## Security Notes

- AWS credentials are not stored in the repository.
- `.gitignore` excludes Terraform state files, local generated files, and credential-like files.
- The Minecraft port `25565` is public because users need to connect from the internet.
- EFS only allows NFS traffic from the ECS task security group.
- The ECS task uses the AWS Academy LabRole.

---

## Sources

- Minecraft Java Server Download: https://www.minecraft.net/en-us/download/server
- Minecraft EULA: https://www.minecraft.net/en-us/eula
- Terraform AWS Provider Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Amazon ECS Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html
- Amazon ECR Documentation: https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html
- Amazon EFS with ECS Documentation: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html
- Network Load Balancer Documentation: https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html
- GitHub Actions Documentation: https://docs.github.com/en/actions
- GitHub Markdown Documentation: https://docs.github.com/en/get-started/writing-on-github

