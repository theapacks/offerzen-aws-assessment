# Deployment Guide

## Prerequisites

- AWS CLI configured with SSO profile `DavhanaUATAdmin`
- Terraform >= 1.12.0
- GitHub CLI (`gh`) authenticated as `theapacks`

## Architecture Overview

```
Browser → UI ALB (public, port 80) → UI ASG instances (nginx container)
Browser → Backend ALB (public, port 3011) → Backend ASG instances (Node.js container)
```

- **UI**: Static HTML served by nginx, makes client-side fetch calls to backend ALB
- **Backend**: Express.js API on port 3011
- **Deployment**: GitHub Actions builds images → pushes to ECR → triggers SSM Automation → RunCommand deploys containers on EC2 instances
- **Initial boot**: Launch template user_data installs Docker and pulls the initial container image from ECR

## Step-by-Step Deployment

### 1. Authenticate with AWS

```bash
aws sso login --profile DavhanaUATAdmin
```

### 2. Bootstrap the Terraform State Bucket

```bash
cd infra/terraform/bootstrap
terraform init
AWS_PROFILE=DavhanaUATAdmin terraform apply
```

Note the output `state_bucket_name` — you'll need it for the next step.

### 3. Create Backend Configuration

```bash
cp infra/terraform/environments/dev/backend.hcl.example infra/terraform/environments/dev/backend.hcl
```

Edit `backend.hcl` and set:
```hcl
bucket       = "<output from bootstrap>"
key          = "dev/terraform.tfstate"
region       = "eu-west-2"
encrypt      = true
use_lockfile = true
profile      = "DavhanaUATAdmin"
```

### 4. Initialize and Apply Main Infrastructure

```bash
cd infra/terraform
terraform init -backend-config=environments/dev/backend.hcl
AWS_PROFILE=DavhanaUATAdmin terraform apply -var-file=environments/dev/dev.tfvars
```

### 5. Set GitHub Actions Secrets

After `terraform apply` outputs are available:

```bash
# Set the IAM role for GitHub Actions to assume (ECR push + SSM deploy)
gh secret set AWS_ROLE_TO_ASSUME \
  --body "$(AWS_PROFILE=DavhanaUATAdmin terraform output -raw github_actions_role_arn)" \
  --repo theapacks/offerzen-aws-assessment

# Set the SSM Automation role ARN for the deploy step
gh secret set SSM_AUTOMATION_ROLE_ARN \
  --body "arn:aws:iam::830822530678:role/offerzen-aws-assessment-dev-ssm-automation" \
  --repo theapacks/offerzen-aws-assessment
```

### 6. Trigger Initial Build & Deploy

```bash
gh workflow run backend.yml --repo theapacks/offerzen-aws-assessment --ref main
gh workflow run ui.yml --repo theapacks/offerzen-aws-assessment --ref main
```

After images are pushed, update `dev.tfvars` with the deployed image tag:

```hcl
ssm_deployment = {
  image_tag = "<git-sha-from-workflow>"
}
```

Then re-apply so the launch template user_data uses the correct image tag for new instances:

```bash
AWS_PROFILE=DavhanaUATAdmin terraform apply -var-file=environments/dev/dev.tfvars
```

### 7. Verify

- UI ALB: `http://<external_alb_dns_name>` (from terraform output)
- Backend health: `http://<internal_alb_dns_name>:3011/health`

## Subsequent Deployments

Push to `main` with changes in `app/src/server/` or `app/src/client/` — GitHub Actions will automatically:
1. Build Docker image tagged with git SHA
2. Push to ECR
3. Trigger SSM Automation to deploy the new container on running instances

## Teardown

```bash
cd infra/terraform
AWS_PROFILE=DavhanaUATAdmin terraform destroy -var-file=environments/dev/dev.tfvars

cd bootstrap
AWS_PROFILE=DavhanaUATAdmin terraform destroy
```

Note: If ECR repos fail to delete, force-delete them:
```bash
AWS_PROFILE=DavhanaUATAdmin aws ecr delete-repository --repository-name offerzen-aws-assessment/dev/backend --force --region eu-west-2
AWS_PROFILE=DavhanaUATAdmin aws ecr delete-repository --repository-name offerzen-aws-assessment/dev/ui --force --region eu-west-2
```

---

## Learnings & Issues Encountered

### 1. Backend ALB must be public (not internal)

The UI is a static HTML page that makes **browser-side** `fetch()` calls directly to the backend. An internal ALB has no public DNS resolution, so the browser can't reach it. The backend ALB must be public-facing.

### 2. Port alignment is critical

The backend container listens on port **3011** (`process.env.PORT || 3011`). The ALB target group, listener, and security groups must all use 3011 — not the generic 8080.

### 3. ECR IMMUTABLE tags break CI/CD reruns

With `IMMUTABLE` tag mutability, you can't push the same tag twice. If a workflow is re-run on the same commit, it fails. Use `MUTABLE` for dev environments.

### 4. SSM Automation associations need an assume role

When using `automation_target_parameter_name` with targets, the association requires:
- An IAM role with `ssm.amazonaws.com` as trusted principal
- The `AmazonSSMAutomationRole` managed policy
- An inline policy granting `ssm:SendCommand`, `ssm:ListCommands`, `ssm:GetCommandInvocation`
- The `AutomationAssumeRole` parameter declared in the SSM document itself with `assumeRole = "{{ AutomationAssumeRole }}"`

### 5. `tag:GetResources` permission needed for SSM target resolution

When using `--targets Key=tag:Name,Values=...` with `ssm:StartAutomationExecution`, the caller needs `tag:GetResources` permission.

### 6. Chicken-and-egg: instances boot before images exist in ECR

- ASG creates instances → ALB health check fails (no container) → ASG terminates after grace period → cycle repeats
- **Solution**: Include container pull/run in the launch template `user_data` so instances self-deploy on first boot
- SSM Automation is then used for **subsequent deployments** (new image versions), not the initial one
- The `health_check_grace_period` should be 600s to allow Docker install + image pull

### 7. SSM Agent availability in private subnets

Instances in private subnets need VPC endpoints for SSM to function:
- `com.amazonaws.{region}.ssm`
- `com.amazonaws.{region}.ssmmessages`
- `com.amazonaws.{region}.ec2messages`

Plus ECR endpoints for Docker pull:
- `com.amazonaws.{region}.ecr.api`
- `com.amazonaws.{region}.ecr.dkr`
- `com.amazonaws.{region}.s3` (Gateway — for ECR layer storage)

### 8. Terraform random_password for secrets

Use `random_password` + `aws_ssm_parameter` to generate secrets at infrastructure provisioning time, avoiding manual CLI steps. Add `lifecycle { ignore_changes = [value] }` so manual rotations aren't overwritten.

### 9. SSM document ImageTag as runtime parameter

Baking the image tag into the SSM document at Terraform plan time means every deploy needs `terraform apply`. Instead, make `ImageTag` a **runtime parameter** with a default value, so the CI/CD pipeline can pass the git SHA at execution time without touching Terraform.
