# Knowledge Pipeline Deployment

This directory contains infrastructure as code (Terraform) and deployment automation (GitHub Actions) for the Knowledge Pipeline system.

## Directory Structure

```
deployment/
├── terraform/           # Terraform infrastructure code
│   ├── main.tf         # Main configuration
│   ├── variables.tf    # Input variables
│   ├── terraform.tfvars.example  # Example variables
│   └── modules/        # Terraform modules
│       ├── vpc/        # VPC and networking
│       ├── ecs/        # ECS cluster
│       ├── efs/        # EFS for ChromaDB persistence
│       ├── alb/        # Application Load Balancer
│       ├── ecs-service/  # ECS service configuration
│       ├── secrets/    # Secrets Manager
│       └── cloudwatch/ # Monitoring and alarms
└── github-actions/     # GitHub Actions workflows (in .github/workflows/)
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **GitHub Secrets** configured:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `API_KEY` (for application authentication)

## Quick Start

### 1. Configure Terraform Variables

Copy the example variables file and customize:

```bash
cd deployment/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Infrastructure Changes

```bash
terraform plan
```

### 4. Apply Infrastructure

```bash
terraform apply
```

### 5. Verify Deployment

After Terraform completes, you'll receive outputs including:
- ALB DNS name
- ECS cluster name
- EFS file system ID

Test the application:

```bash
curl http://<alb-dns-name>/health
```

## Infrastructure Components

### VPC Configuration

- **CIDR Block**: 10.0.0.0/16 (configurable)
- **Availability Zones**: 2 (configurable)
- **Public Subnets**: For ALB and NAT Gateways
- **Private Subnets**: For ECS tasks and EFS
- **NAT Gateways**: For outbound internet access from private subnets

### ECS Cluster

- **Compute**: AWS Fargate (serverless)
- **Capacity Providers**: FARGATE and FARGATE_SPOT
- **Auto-scaling**: Enabled based on CPU/Memory/Request metrics

### EFS File System

- **Purpose**: Persistent storage for ChromaDB data
- **Encryption**: Enabled at rest
- **Lifecycle Policy**: Transition to IA after 30 days
- **Mount Points**: In all private subnets for high availability

### Application Load Balancer

- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Listeners**: HTTP (80) and HTTPS (443, if certificate provided)
- **Health Checks**: `/health` endpoint
- **SSL/TLS**: TLS 1.2+ (when certificate configured)

### Monitoring

- **CloudWatch Logs**: Centralized logging for all containers
- **CloudWatch Metrics**: CPU, memory, request metrics
- **Alarms**: High CPU, high memory, unhealthy hosts
- **SNS Notifications**: Email alerts for critical issues

## GitHub Actions Workflows

### Terraform Deploy (`terraform-deploy.yml`)

Automatically deploys infrastructure changes:

**Triggers:**
- Push to `main` branch (terraform files changed)
- Pull requests (plan only)
- Manual workflow dispatch

**Steps:**
1. Terraform format check
2. Terraform init
3. Terraform validate
4. Terraform plan (always)
5. Terraform apply (only on main branch)

### Application Deploy (`application-deploy.yml`)

Builds and deploys the application:

**Triggers:**
- Push to `main` branch (application code changed)
- Manual workflow dispatch

**Steps:**
1. Build Docker image
2. Push to Amazon ECR
3. Update ECS task definition
4. Deploy to ECS cluster
5. Wait for service stability

## Cost Optimization

### Estimated Monthly Costs (us-east-1)

| Resource | Estimated Cost |
|----------|---------------|
| ECS Fargate (2 tasks, 1 vCPU, 2GB) | ~$50 |
| Application Load Balancer | ~$20 |
| NAT Gateways (2) | ~$65 |
| EFS Storage (10GB) | ~$3 |
| CloudWatch Logs (5GB) | ~$2.50 |
| **Total** | **~$140/month** |

### Cost Reduction Strategies

1. **Use FARGATE_SPOT**: Up to 70% savings on compute
2. **Single NAT Gateway**: Reduce from $65 to $32.50 (reduces HA)
3. **EFS Lifecycle**: Automatically transition to IA storage
4. **CloudWatch Log Retention**: Set to 7-30 days instead of indefinite
5. **Auto-scaling**: Scale down during off-peak hours

## Security Best Practices

### Network Security

- Private subnets for application containers
- Security groups with least-privilege access
- VPC endpoints for AWS service access (reduces NAT costs)

### Data Security

- EFS encryption at rest
- Secrets stored in AWS Secrets Manager
- SSL/TLS in transit
- IAM roles with minimal permissions

### Application Security

- Container security scanning (integrate Trivy/Snyk)
- Regular base image updates
- API authentication required
- Rate limiting enabled

## Troubleshooting

### ECS Tasks Failing to Start

Check CloudWatch logs:
```bash
aws logs tail /aws/ecs/knowledge-pipeline-dev --follow
```

### ALB Health Checks Failing

Verify container is listening on correct port:
```bash
aws ecs describe-tasks --cluster <cluster> --tasks <task-id>
```

### EFS Mount Issues

Check security group rules and mount targets:
```bash
aws efs describe-mount-targets --file-system-id <fs-id>
```

### Terraform State Locked

If Terraform state is locked, you may need to force unlock:
```bash
terraform force-unlock <lock-id>
```

## Backup and Disaster Recovery

### Backup Strategy

1. **EFS Data**: Daily backups using AWS Backup
2. **Terraform State**: Stored in S3 with versioning
3. **Container Images**: Retained in ECR with lifecycle policies
4. **Secrets**: Backed up in Secrets Manager

### Recovery Procedures

1. **Infrastructure Recovery**: Run `terraform apply`
2. **Data Recovery**: Restore from EFS backup
3. **Application Recovery**: Redeploy from last known good image

### Recovery Time Objectives

- **RTO**: 1 hour (infrastructure + application)
- **RPO**: 24 hours (daily EFS backups)

## Monitoring and Alerting

### Key Metrics to Monitor

- **ECS Service**: CPU, Memory, Running Task Count
- **ALB**: Request Count, Target Response Time, HTTP Errors
- **EFS**: Throughput, IOPS, Client Connections
- **Application**: Query Latency, Search Accuracy, Error Rate

### Alarm Thresholds

- **CPU > 80%**: Scale up or investigate performance issues
- **Memory > 80%**: Scale up or investigate memory leaks
- **Unhealthy Hosts > 0**: Application health issues
- **5xx Errors > 5%**: Application errors requiring investigation

## Updating Infrastructure

### Making Changes

1. Update Terraform code in `deployment/terraform/`
2. Create pull request
3. Review Terraform plan in PR comments
4. Merge to main branch
5. GitHub Actions automatically applies changes

### Rolling Back

If deployment fails:

```bash
# Revert to previous task definition
aws ecs update-service \
  --cluster <cluster> \
  --service <service> \
  --task-definition <previous-task-def>
```

Or revert Terraform changes:

```bash
git revert <commit-sha>
git push origin main
```

## Environment Configuration

### Development Environment

- Minimal resources (1 task, smaller instance)
- Lower costs
- Relaxed monitoring

### Staging Environment

- Production-like configuration
- Full monitoring enabled
- Used for final testing

### Production Environment

- High availability (multi-AZ)
- Auto-scaling enabled
- Strict monitoring and alerting
- Regular backups

## Additional Resources

- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ChromaDB Documentation](https://docs.trychroma.com/)

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review Terraform outputs
3. Consult this README
4. Open a GitHub issue
