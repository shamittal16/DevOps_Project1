# Terraform CI/CD Automation

## Overview

This repository contains **Terraform configuration files** and **GitHub Actions workflows** to automate infrastructure management.  

Any changes to the Terraform files trigger automated workflows to **plan, preview, and apply changes**, ensuring safe and consistent infrastructure updates. Terraform state is now stored in a **remote S3 bucket** with **DynamoDB table locking** to prevent concurrent modifications. This ensures that both Apply and Destroy workflows operate on the correct state file.

---

## Repository Structure

| File / Folder | Description |
|---------------|-------------|
| `terraform/` | Folder containing all Terraform configuration files (`.tf`). |
| `terraform.yml` | GitHub Actions workflow triggered on Terraform file changes: <br>• Runs `terraform init` and `terraform plan` on Pull Requests <br>• Automatically runs `terraform apply` when changes are merged into `main`. |
| `destroy-tf.yml` | GitHub Actions workflow to manually destroy all infrastructure using `terraform destroy`, reading state from S3. |
| `generate_tfplan.sh` | Script to convert Terraform plan output into human-readable text (`tfplan.txt`) and summary (`tfplan_summary.txt`). |
| `tfplan.txt` | Full text output of the latest Terraform plan. |
| `tfplan_summary.txt` | Summary of the Terraform plan for quick review. |

---

## How It Works

### Terraform Workflow (`terraform.yml`)

**Trigger**  
- Activated when Terraform files in the `terraform/` folder are modified.  
- **Pull Requests:** Run `terraform init` + `terraform plan`.  
- **Push to `main`:** Run `terraform apply` automatically if all checks pass.  

**Remote Backend**  
- Terraform state is stored in a **S3 bucket** and **locked using a DynamoDB table**.  
- Prevents concurrent updates and ensures consistency for all Apply and Destroy runs.

**Plan Output**  
- Generates `tfplan.txt` for full plan details.  
- Generates `tfplan_summary.txt` for a quick summary of changes.  

**Automated Apply**  
- Terraform apply runs automatically **after merging changes to `main`**.  

---

### Destroy Workflow (`destroy-tf.yml`)

- Triggered manually using GitHub Actions `workflow_dispatch`.  
- Reads Terraform state from the **remote S3 backend** and respects the **DynamoDB lock**.  
- Runs `terraform destroy` to tear down all infrastructure safely.  
- Ensures that destroy operations use the **correct, up-to-date state file**, avoiding inconsistencies.  

---

### Plan Formatter (`generate_tfplan.sh`)

- Converts Terraform plan output into a **readable text format**.  
- Generates a **summary** to quickly see the number of resources to add, change, or destroy.  
- Ensures reviewers can easily understand infrastructure changes before apply.  

---

## Recommended Usage

**Contributors**  
- Edit Terraform files in the `terraform/` folder.  
- Create a Pull Request.  
- Review `tfplan_summary.txt` and CI logs.  

**Merging**  
- After PR approval and passing checks, merge into `main`.  
- Terraform apply runs automatically.  

**Destroying Infrastructure**  
- Use the `destroy-tf.yml` workflow manually for safe cleanup.  
- Since state is stored in S3 and locked via DynamoDB, the destroy workflow will operate on the **correct remote state**, preventing accidental errors.  

---

## Notes

- Terraform state is **remote in S3** with **DynamoDB locking**, avoiding conflicts during concurrent workflow runs.  
- Workflows trigger **only when Terraform files change**, preventing unnecessary runs.  
- `generate_tfplan.sh` helps create human-readable plan outputs for better visibility.  
- Always ensure that **AWS credentials are provided** in GitHub Secrets or via OIDC roles for workflows to access the backend and resources.
