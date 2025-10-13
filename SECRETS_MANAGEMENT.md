# GLI Project Secrets Management Guide

## Overview

This document describes the secrets management system for the GLI project, covering both AWS Secrets Manager and GitHub Secrets configuration.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     GLI Secrets                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐      ┌────────────────────────┐  │
│  │  AWS Secrets     │      │   GitHub Secrets       │  │
│  │  Manager         │      │                        │  │
│  ├──────────────────┤      ├────────────────────────┤  │
│  │  • Database      │      │  • AWS Credentials     │  │
│  │  • API Keys      │      │  • S3 Buckets          │  │
│  │  • Credentials   │      │  • CloudFront IDs      │  │
│  └──────────────────┘      └────────────────────────┘  │
│           ▲                          ▲                  │
│           │                          │                  │
│           └──────────────────────────┘                  │
│                     │                                   │
│            ┌────────▼────────┐                          │
│            │ GitHub Actions  │                          │
│            │   Workflows     │                          │
│            └─────────────────┘                          │
│                     │                                   │
│       ┌─────────────┼─────────────┐                     │
│       ▼             ▼             ▼                     │
│  ┌────────┐   ┌──────────┐  ┌──────────┐               │
│  │  API   │   │ Frontend │  │WebSocket │               │
│  │ Server │   │   Apps   │  │  Server  │               │
│  └────────┘   └──────────┘  └──────────┘               │
└─────────────────────────────────────────────────────────┘
```

## AWS Secrets Manager

### Created Secrets

#### Database Secrets (✅ Already Created)

**Production Database**
- Secret Name: `gli/db/production`
- ARN: `arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/production-u1ubhz`
- Endpoint: `gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com`
- Contents:
  ```json
  {
    "username": "glidbadmin",
    "password": "<password>",
    "engine": "postgres",
    "host": "gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com",
    "port": 5432,
    "dbname": "gli"
  }
  ```

**Staging Database**
- Secret Name: `gli/db/staging`
- ARN: `arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/staging-jnPMCP`
- Endpoint: `gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com`
- Contents: (Same structure as production)

### Secret Rotation

Database credentials should be rotated periodically:

```bash
# Enable automatic rotation (30 days)
aws secretsmanager rotate-secret \
  --secret-id gli/db/production \
  --rotation-lambda-arn arn:aws:lambda:ap-northeast-2:917891822317:function:SecretsManagerRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

### Accessing Secrets

**From GitHub Actions:**
```yaml
- name: Get DB credentials from Secrets Manager
  run: |
    SECRET_JSON=$(aws secretsmanager get-secret-value \
      --secret-id gli/db/production \
      --query SecretString \
      --output text)

    echo "DB_HOST=$(echo $SECRET_JSON | jq -r .host)" >> $GITHUB_ENV
    echo "DB_USER=$(echo $SECRET_JSON | jq -r .username)" >> $GITHUB_ENV
```

**From Application (Django):**
```python
import boto3
import json

def get_db_secret(environment='production'):
    client = boto3.client('secretsmanager', region_name='ap-northeast-2')
    secret = client.get_secret_value(SecretId=f'gli/db/{environment}')
    return json.loads(secret['SecretString'])

# Usage in settings.py
db_secret = get_db_secret(os.environ.get('DJANGO_ENV', 'production'))
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': db_secret['dbname'],
        'USER': db_secret['username'],
        'PASSWORD': db_secret['password'],
        'HOST': db_secret['host'],
        'PORT': db_secret['port'],
    }
}
```

## GitHub Secrets

### Organization-Level Secrets

These should be configured at `https://github.com/organizations/<org>/settings/secrets`:

- `AWS_ACCESS_KEY_ID` - IAM user for GitHub Actions
- `AWS_SECRET_ACCESS_KEY` - Corresponding secret key

### Repository-Specific Secrets

Each repository needs the following secrets configured at `https://github.com/<org>/<repo>/settings/secrets`:

#### 1. gli_api-server

**Required Secrets:**
- `AWS_ACCESS_KEY_ID` - AWS credentials
- `AWS_SECRET_ACCESS_KEY` - AWS credentials
- `SECRET_KEY_STAGING` - Django secret key for staging
- `SECRET_KEY_PRODUCTION` - Django secret key for production
- `CORS_ALLOWED_ORIGINS_STAGING` - `https://stg.glibiz.com,https://stg-admin.glibiz.com`
- `CORS_ALLOWED_ORIGINS_PRODUCTION` - `https://glibiz.com,https://admin.glibiz.com`
- `FRONTEND_BASE_URL_STAGING` - `https://stg.glibiz.com`
- `FRONTEND_BASE_URL_PRODUCTION` - `https://glibiz.com`
- `JWT_PRIVATE_KEY_STAGING` - JWT private key (RS256)
- `JWT_PUBLIC_KEY_STAGING` - JWT public key
- `JWT_PRIVATE_KEY_PRODUCTION` - JWT private key (RS256)
- `JWT_PUBLIC_KEY_PRODUCTION` - JWT public key
- `AWS_STORAGE_BUCKET_NAME_STAGING` - S3 bucket for media files
- `AWS_STORAGE_BUCKET_NAME_PRODUCTION` - S3 bucket for media files

**Note:** Database credentials are retrieved from AWS Secrets Manager

#### 2. gli_user-frontend

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `STG_S3_BUCKET` - Example: `stg-gli-user-frontend`
- `PROD_S3_BUCKET` - Example: `gli-user-frontend`
- `STG_CLOUDFRONT_DISTRIBUTION_ID` - CloudFront distribution ID
- `PROD_CLOUDFRONT_DISTRIBUTION_ID` - CloudFront distribution ID

#### 3. gli_admin-frontend

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `STG_ADMIN_S3_BUCKET` - Example: `stg-gli-admin-frontend`
- `PROD_ADMIN_S3_BUCKET` - Example: `gli-admin-frontend`
- `STG_ADMIN_CF_DISTRIBUTION_ID` - CloudFront distribution ID
- `PROD_ADMIN_CF_DISTRIBUTION_ID` - CloudFront distribution ID

#### 4. gli_websocket

**Required Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

#### 5. gli_database, gli_rabbitmq, gli_redis

These repositories may not need GitHub Actions workflows currently, but AWS credentials should be configured for future use.

### Setting Up GitHub Secrets

**Via GitHub CLI:**
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Set secrets for a repository
gh secret set AWS_ACCESS_KEY_ID --repo <org>/<repo>
gh secret set AWS_SECRET_ACCESS_KEY --repo <org>/<repo>

# Set secrets for multiple repositories
REPOS=(
  "gli_api-server"
  "gli_user-frontend"
  "gli_admin-frontend"
  "gli_websocket"
)

for repo in "${REPOS[@]}"; do
  gh secret set AWS_ACCESS_KEY_ID --repo <org>/$repo
  gh secret set AWS_SECRET_ACCESS_KEY --repo <org>/$repo
done
```

**Via Web UI:**
1. Navigate to repository Settings
2. Click "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Enter name and value
5. Click "Add secret"

### Generating JWT Keys

**For API Server:**
```bash
# Generate RS256 key pair
ssh-keygen -t rsa -b 4096 -m PEM -f jwt-key
openssl rsa -in jwt-key -pubout -outform PEM -out jwt-key.pub

# Private key (add to GitHub Secrets as JWT_PRIVATE_KEY_*)
cat jwt-key

# Public key (add to GitHub Secrets as JWT_PUBLIC_KEY_*)
cat jwt-key.pub

# Clean up
rm jwt-key jwt-key.pub
```

## AWS IAM Permissions

### GitHub Actions IAM User

Create a dedicated IAM user for GitHub Actions with the following policies:

**Policy: GitHubActionsECRPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

**Policy: GitHubActionsECSPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RegisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:RunTask",
        "ecs:DescribeTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::917891822317:role/ecsTaskExecutionRole"
    }
  ]
}
```

**Policy: GitHubActionsS3CloudFrontPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::*gli*frontend*",
        "arn:aws:s3:::*gli*frontend*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "*"
    }
  ]
}
```

**Policy: GitHubActionsSecretsManagerPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/*"
    }
  ]
}
```

### Creating the IAM User

```bash
# Create IAM user
aws iam create-user --user-name gli-github-actions

# Attach policies
aws iam attach-user-policy --user-name gli-github-actions --policy-arn <ECR_POLICY_ARN>
aws iam attach-user-policy --user-name gli-github-actions --policy-arn <ECS_POLICY_ARN>
aws iam attach-user-policy --user-name gli-github-actions --policy-arn <S3_CLOUDFRONT_POLICY_ARN>
aws iam attach-user-policy --user-name gli-github-actions --policy-arn <SECRETS_MANAGER_POLICY_ARN>

# Create access key
aws iam create-access-key --user-name gli-github-actions
```

## Security Best Practices

1. **Never commit secrets to Git**
   - Use `.gitignore` to exclude environment files
   - Review commits before pushing
   - Use git-secrets or similar tools

2. **Rotate secrets regularly**
   - Database passwords: Every 90 days
   - API keys: Every 180 days
   - AWS access keys: Every 180 days

3. **Use principle of least privilege**
   - Grant only necessary permissions
   - Use separate IAM users/roles for different purposes

4. **Monitor secret access**
   - Enable AWS CloudTrail for Secrets Manager
   - Review access logs regularly
   - Set up alerts for unauthorized access

5. **Encrypt secrets at rest**
   - AWS Secrets Manager uses AWS KMS by default
   - Use encrypted EBS volumes for applications

6. **Use environment-specific secrets**
   - Never use production secrets in staging/dev
   - Keep environments completely isolated

## Troubleshooting

### Secret Not Found Error

```bash
# List all secrets
aws secretsmanager list-secrets --region ap-northeast-2

# Get specific secret
aws secretsmanager get-secret-value --secret-id gli/db/production
```

### GitHub Actions Can't Access Secrets

1. Verify secret is configured in repository settings
2. Check secret name matches exactly (case-sensitive)
3. Verify workflow has correct permissions
4. Check if organization-level secrets are properly shared

### AWS Permissions Issues

```bash
# Test IAM permissions
aws sts get-caller-identity
aws secretsmanager list-secrets --region ap-northeast-2
aws ecr describe-repositories --region ap-northeast-2
```

## Checklist for New Secrets

When adding a new secret:

- [ ] Determine if secret should be in AWS Secrets Manager or GitHub Secrets
- [ ] Create secret with appropriate naming convention
- [ ] Document secret in this guide
- [ ] Update IAM policies if needed
- [ ] Update application code to use the secret
- [ ] Test secret access in all environments
- [ ] Update GitHub Actions workflows if needed
- [ ] Add to secrets inventory (stored securely, not in Git)

## Contact

For secrets management issues or questions, contact the DevOps team.
