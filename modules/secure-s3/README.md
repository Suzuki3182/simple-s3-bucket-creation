# Secure AWS S3 Bucket — Terraform Module

This Terraform module provisions a secure, production-ready AWS S3 bucket with:

- 🔒 **Server-side encryption** (SSE-S3 / AES-256)
- 📦 **Versioning** enabled
- 🚫 **All public access blocked**
- 👤 **IAM bucket policy** granting read-only access to a specific IAM user ARN

---

## Prerequisites

Before you begin, make sure you have the following installed and configured:

| Tool | Version | Install |
|------|---------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.3 | `sudo apt install terraform` or download from HashiCorp |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | >= 2.x | `sudo apt install awscli` |
| AWS credentials | — | Configured via `aws configure` or environment variables |

---

## Step 1 — Configure AWS Credentials

You need valid AWS credentials with permissions to create S3 buckets and IAM policies.

### Option A — AWS CLI (recommended)

```bash
aws configure
```

You will be prompted for:

```
AWS Access Key ID [None]: <YOUR_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_SECRET_ACCESS_KEY>
Default region name [None]: us-east-1
Default output format [None]: json
```

### Option B — Environment Variables

```bash
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="us-east-1"
```

### Verify credentials are working

```bash
aws sts get-caller-identity
```

Expected output:

```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

---

## Step 2 — Navigate to the Module Directory

```bash
cd modules/secure-s3
```

---

## Step 3 — Review the Module Files

```
modules/secure-s3/
├── main.tf        # S3 bucket, encryption, versioning, public access block, bucket policy
├── variables.tf   # Input variables
├── outputs.tf     # Output values
└── README.md      # This file
```

### Input Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `bucket_name` | `string` | ✅ Yes | — | Globally unique S3 bucket name |
| `read_only_iam_user_arn` | `string` | ✅ Yes | — | IAM user ARN to grant read-only access |
| `force_destroy` | `bool` | No | `false` | Allow bucket deletion even if it contains objects |
| `tags` | `map(string)` | No | `{}` | Tags to apply to the bucket |

### Output Values

| Output | Description |
|--------|-------------|
| `bucket_id` | The bucket name / ID |
| `bucket_arn` | The bucket ARN |
| `bucket_domain_name` | The bucket domain name |
| `bucket_regional_domain_name` | The region-specific domain name |
| `bucket_region` | The AWS region the bucket resides in |

---

## Step 4 — Initialize Terraform

Download the required AWS provider plugin:

```bash
terraform init
```

Expected output:

```
Terraform has been successfully initialized!
```

---

## Step 5 — Preview the Plan

Run a dry-run to see exactly what Terraform will create **before** making any changes.

Replace the placeholder values with your own:

```bash
terraform plan \
  -var="bucket_name=my-secure-s3-bucket" \
  -var="read_only_iam_user_arn=arn:aws:iam::123456789012:user/readonly-user"
```

> 💡 **Tip:** Bucket names must be globally unique across all AWS accounts. Use a name like `mycompany-secure-data-2024`.

Expected output summary:

```
Plan: 5 to add, 0 to change, 0 to destroy.
```

The 5 resources that will be created:
1. `aws_s3_bucket` — the bucket itself
2. `aws_s3_bucket_server_side_encryption_configuration` — AES-256 encryption
3. `aws_s3_bucket_versioning` — versioning enabled
4. `aws_s3_bucket_public_access_block` — all public access blocked
5. `aws_s3_bucket_policy` — read-only IAM policy

---

## Step 6 — Apply (Create the Bucket)

When you are satisfied with the plan, apply it:

```bash
terraform apply \
  -var="bucket_name=my-secure-s3-bucket" \
  -var="read_only_iam_user_arn=arn:aws:iam::123456789012:user/readonly-user"
```

Terraform will show the plan again and prompt for confirmation:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

Type `yes` and press Enter.

### Auto-approve (skip confirmation prompt)

```bash
terraform apply \
  -var="bucket_name=my-secure-s3-bucket" \
  -var="read_only_iam_user_arn=arn:aws:iam::123456789012:user/readonly-user" \
  -auto-approve
```

### Expected output after apply

```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn                  = "arn:aws:s3:::my-secure-s3-bucket"
bucket_domain_name          = "my-secure-s3-bucket.s3.amazonaws.com"
bucket_id                   = "my-secure-s3-bucket"
bucket_region               = "us-east-1"
bucket_regional_domain_name = "my-secure-s3-bucket.s3.us-east-1.amazonaws.com"
```

---

## Step 7 — Verify the Bucket

### Check the bucket exists

```bash
aws s3 ls | grep my-secure-s3-bucket
```

### Check encryption is enabled

```bash
aws s3api get-bucket-encryption --bucket my-secure-s3-bucket
```

### Check versioning is enabled

```bash
aws s3api get-bucket-versioning --bucket my-secure-s3-bucket
```

### Check public access is blocked

```bash
aws s3api get-public-access-block --bucket my-secure-s3-bucket
```

### Check the bucket policy

```bash
aws s3api get-bucket-policy --bucket my-secure-s3-bucket | jq '.Policy | fromjson'
```

---

## Using a `terraform.tfvars` File (Optional)

Instead of passing `-var` flags every time, create a `terraform.tfvars` file:

```bash
cat > terraform.tfvars <<EOF
bucket_name            = "my-secure-s3-bucket"
read_only_iam_user_arn = "arn:aws:iam::123456789012:user/readonly-user"
force_destroy          = false
tags = {
  Environment = "production"
  Team        = "platform"
  ManagedBy   = "terraform"
}
EOF
```

Then run commands without `-var` flags:

```bash
terraform plan
terraform apply
```

> ⚠️ **Do not commit `terraform.tfvars` to version control if it contains sensitive values.** Add it to `.gitignore`.

---

## Destroying the Bucket

To remove all resources created by this module:

```bash
terraform destroy \
  -var="bucket_name=my-secure-s3-bucket" \
  -var="read_only_iam_user_arn=arn:aws:iam::123456789012:user/readonly-user"
```

> ⚠️ **Note:** If the bucket contains objects and `force_destroy = false` (the default), Terraform will fail to delete it. Either empty the bucket first or set `force_destroy = true`.

To empty the bucket before destroying:

```bash
aws s3 rm s3://my-secure-s3-bucket --recursive
terraform destroy -var="bucket_name=my-secure-s3-bucket" -var="read_only_iam_user_arn=arn:aws:iam::123456789012:user/readonly-user"
```

---

## Troubleshooting

### `BucketAlreadyExists` error

The bucket name is already taken globally. Choose a different, more unique name.

### `AccessDenied` error

Your AWS credentials lack the required permissions. Ensure your IAM user/role has at minimum:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:CreateBucket",
    "s3:PutBucketEncryption",
    "s3:PutBucketVersioning",
    "s3:PutBucketPublicAccessBlock",
    "s3:PutBucketPolicy",
    "s3:DeleteBucket",
    "s3:DeleteBucketPolicy"
  ],
  "Resource": "*"
}
```

### `InvalidClientTokenId` error

Your AWS credentials are invalid or expired. Re-run `aws configure` or refresh your session token.

### Terraform state issues

If you need to re-initialize after changing providers:

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

---

## Security Notes

- The bucket policy **only grants read-only access** (`s3:GetObject`, `s3:ListBucket`, etc.) to the specified IAM user. No write or delete permissions are granted via the bucket policy.
- All public access is blocked at the bucket level, regardless of object ACLs or other policies.
- Versioning protects against accidental deletion or overwrite of objects.
- SSE-S3 (AES-256) encrypts all objects at rest automatically.
