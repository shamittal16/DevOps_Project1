# Terraform Automation with GitHub Workflows

This repository is for learning and practicing Terraform in a simple and automated way. It uses GitHub Actions to automatically plan, apply, and optionally destroy infrastructure whenever Terraform files change.

## How It Works

We have two main GitHub workflows:

### Terraform Plan on Pull Request

Whenever any `.tf` file is changed and a Pull Request (PR) is opened:

- A workflow triggers to run `terraform plan`.
- This helps you review the changes that Terraform will make before merging.

### Terraform Apply on Merge

Once the PR is reviewed and merged into the `main` branch:

- Another workflow automatically triggers `terraform apply`.
- This applies the approved changes to your infrastructure.

### Optional Terraform Destroy

You can also have a workflow to destroy infrastructure when needed.

- This can be triggered manually or on specific branch actions.

## Why This Is Useful

- Automates Terraform workflows, reducing human errors.
- Ensures code changes are reviewed before affecting real infrastructure.
- Makes learning Terraform simple by practicing with real automation.

## Quick Start

1. Make sure you have Terraform installed locally.
2. Clone this repo:
   ```bash
   git clone <repo-url>
   cd <repo-name>
