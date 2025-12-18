#!/bin/bash

PLAN_FILE="tfplan"
SUMMARY_FILE="tfplan_summary.txt"
TMP_JSON="plan.json"

# Step 1: Initialize Terraform
echo "Initializing Terraform..."
terraform init
if [ $? -ne 0 ]; then
    echo "Error: Terraform init failed!"
    exit 1
fi

# Step 2: Run Terraform plan and save binary tfplan
echo "Running Terraform plan..."
terraform plan -out=$PLAN_FILE
if [ $? -ne 0 ]; then
    echo "Error: Terraform plan failed!"
    exit 1
fi

# Step 3: Generate readable tfplan.txt
echo "Generating readable tfplan.txt..."
terraform show -no-color $PLAN_FILE > tfplan.txt

# Step 4: Generate summary using temporary JSON
echo "Generating tfplan_summary.txt..."
terraform show -json $PLAN_FILE > $TMP_JSON

# Count actions
CREATE=$(jq '[.resource_changes[].change.actions[] | select(.=="create")] | length' $TMP_JSON)
UPDATE=$(jq '[.resource_changes[].change.actions[] | select(.=="update")] | length' $TMP_JSON)
DELETE=$(jq '[.resource_changes[].change.actions[] | select(.=="delete")] | length' $TMP_JSON)

# Write summary header
echo "Terraform Plan Summary: Create=$CREATE, Update=$UPDATE, Delete=$DELETE" > $SUMMARY_FILE
echo "--------------------------------------------" >> $SUMMARY_FILE

# Generate tree structure
jq -r '.resource_changes[] | "\(.provider_name)/\(.type)/\(.name) (\(.change.actions | join(",")))"' $TMP_JSON \
| sort | awk '
BEGIN { FS="/"; OFS="/"; lastProv=""; lastType="" }
{
  prov=$1; type=$2; name=$3; action=$4;
  if(prov!=lastProv){ print prov; lastProv=prov; lastType=""; }
  if(type!=lastType){ print "├─ " type; lastType=type; }
  print "│  └─ " name " " action
}' >> $SUMMARY_FILE

# Step 5: Remove temporary JSON
rm -f $TMP_JSON

echo "✅ tfplan.txt and tfplan_summary.txt generated successfully!"
