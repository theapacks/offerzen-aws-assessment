# Solution

## Promotion to Production

### 1. Bootstrap prod state

```bash
cd infra/terraform/bootstrap
AWS_PROFILE=<PROD_PROFILE> terraform init
AWS_PROFILE=<PROD_PROFILE> terraform apply -var="environment=prod" -var="aws_region=eu-west-1"
```

Create `environments/prod/backend.hcl` from the output.

### 2. Provision prod infrastructure

```bash
cd infra/terraform
terraform init -reconfigure -backend-config=environments/prod/backend.hcl
AWS_PROFILE=<PROD_PROFILE> terraform apply -var-file=environments/prod/prod.tfvars
```

> NB: `-reconfigure` is only needed if you previously initialized with a different backend (e.g. dev). On a fresh clone, `terraform init -backend-config=environments/prod/backend.hcl` is sufficient.

### 3. Set GitHub secrets for prod

```bash
gh secret set PROD_AWS_ROLE_TO_ASSUME \
  --body "arn:aws:iam::PROD_ACCOUNT_ID:role/offerzen-aws-assessment-prod-github-ecr-push" \
  --repo theapacks/offerzen-aws-assessment

gh secret set PROD_SSM_AUTOMATION_ROLE_ARN \
  --body "arn:aws:iam::PROD_ACCOUNT_ID:role/offerzen-aws-assessment-prod-ssm-automation" \
  --repo theapacks/offerzen-aws-assessment
```

### 4. Deploy to prod

Trigger a prod-specific workflow that builds fresh into the prod ECR and deploys via SSM:

```bash
gh workflow run deploy-prod.yml --field ref=main
```


### 5. Clean up

```bash
cd infra/terraform
AWS_PROFILE=<PROD_PROFILE> terraform destroy -var-file=environments/prod/prod.tfvars

cd ../bootstrap
AWS_PROFILE=<PROD_PROFILE> terraform destroy -var="environment=prod" -var="aws_region=eu-west-1"
```

## Design Trade-offs

### SSM Automation over Ansible

The requirements document stated the use of Ansible, but since I had EC2 instances that were isolated in private subnets, configuring secure remote execution became a roadblock. Standard Ansible deployments require SSH access (Port 22), which would have meant provisioning additional infrastructure—like a bastion host introducing unwanted attack surface and complexity.
Because I didn’t have deep, hands-on experience troubleshooting complex Ansible network routing in isolated environments, trying to force it to work securely was proving time consuming.

### Public backend ALB instead of reverse proxy

The UI makes browser-side fetch calls directly to the backend. The backend EC2 instances remain in private subnets (no public IPs, no direct internet access), but the ALB that fronts them is placed in public subnets so browsers can resolve its DNS. A more secure alternative is an nginx reverse proxy on the UI tier that forwards `/api` requests to an internal backend ALB — but that adds complexity for this exercise. Another option is to introduce a Cloudfront and have the outside world talk to cloudfront with no visibility of the ALB.

### VPC endpoints over NAT Gateway

Private subnets use VPC interface endpoints instead of a NAT Gateway. This is cheaper. The trade-off: instances cannot reach internet hosts (only the services with endpoints).


### User-data bootstrap over pre-baked AMIs

User-data installs Docker and pulls containers at boot time rather than baking a custom AMI with Packer or AWS AMI Builder. This keeps the workflow simpler — no separate image build pipeline, no AMI versioning, no cross-region AMI copies. The trade-off is slower instance boot times (package install + image pull on every launch) and less consistency if upstream package versions drift between launches. For a production environment with frequent scale-out events, pre-baked AMIs would reduce cold-start time significantly.

### GitHub OIDC over static IAM keys

GitHub Actions assumes an IAM role via OIDC federation. No long-lived credentials are stored as secrets. The trade-off is a more complex initial setup (OIDC provider + trust policy) but a stronger security posture.

### Terraform state handling

State is stored in S3 with versioning and encryption enabled. S3 is used for both state storage and state locking (via `use_lockfile = true`), removing the need for a separate DynamoDB table. The backend block is declared as partial (`backend "s3" {}`), with environment-specific values injected at init time via `-backend-config`. This keeps account IDs, bucket names, and regions out of source control.

Each environment gets its own state file path (`dev/terraform.tfstate`, `prod/terraform.tfstate`) in a dedicated bucket, so there is no risk of one environment's apply corrupting another's state.

The state bucket itself is bootstrapped by a separate Terraform root (`infra/terraform/bootstrap/`) that uses local state. This avoids the circular dependency of needing a remote backend to create the remote backend.

S3 native lock files (`use_lockfile = true`) prevent concurrent applies from corrupting state. 
