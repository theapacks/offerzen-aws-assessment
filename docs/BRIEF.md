# Neal Street Technologies - Take Home Assignment:

## AWS IaC + Linux Configuration for a Dev Web

### Core Technologies

- AWS
- Terraform
- AWS Systems Manager
- GitHub Actions

### Requirements

Build a small, secure, automated dev web tier that serves a public health endpoint.

#### Task 1

- Design and implement a cloud infrastructure for a web app running on a Linux EC2 machine using Terraform
- The machine must horizontally scale based on the load
- A load balancer must distribute traffic to the EC2 instances in the auto scaling group
- Web Tier must be accesible from the public internet
- Application Tier must not be accessible from the public intenet
- Handle the management of Terraform state
- Apply tags consistently across all resources

#### Task 2

Automate the OS and application setup for the compute layer provisioned in Task 1
