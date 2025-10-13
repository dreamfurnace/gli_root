#!/bin/bash

# GLI Project - CloudFront Distributions Setup Script
# Frontend용 CloudFront Distribution 생성

set -e

REGION="ap-northeast-2"
ACM_CERT_ARN="arn:aws:acm:us-east-1:917891822317:certificate/8a143395-150a-40cf-b9e7-aacbbd3d2caf"
HOSTED_ZONE_ID="Z0419507IHNIDPFGXUPL"

echo "================================================"
echo "GLI CloudFront Distributions Setup"
echo "================================================"
echo ""
echo "⚠️  중요: CloudFront는 필수입니다!"
echo "   사용자가 웹사이트에 접속하려면 CloudFront가 필요합니다."
echo ""
echo "생성할 CloudFront Distributions:"
echo "  1. Staging User Frontend (stg.glibiz.com)"
echo "  2. Staging Admin Dashboard (stg-admin.glibiz.com)"
echo "  3. Production User Frontend (glibiz.com, www.glibiz.com)"
echo "  4. Production Admin Dashboard (admin.glibiz.com)"
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

# Function to create CloudFront OAI
create_oai() {
  local comment=$1

  OAI_ID=$(aws cloudfront create-cloud-front-origin-access-identity \
    --cloud-front-origin-access-identity-config \
      CallerReference="gli-oai-$(date +%s)",Comment="$comment" \
    --query 'CloudFrontOriginAccessIdentity.Id' \
    --output text)

  echo "$OAI_ID"
}

# Function to update S3 bucket policy for OAI
update_s3_bucket_policy() {
  local bucket=$1
  local oai_id=$2
  local canonical_user_id=$(aws cloudfront get-cloud-front-origin-access-identity \
    --id "$oai_id" \
    --query 'CloudFrontOriginAccessIdentity.S3CanonicalUserId' \
    --output text)

  cat > /tmp/bucket-policy-$bucket.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOAI",
      "Effect": "Allow",
      "Principal": {
        "CanonicalUser": "$canonical_user_id"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$bucket/*"
    }
  ]
}
EOF

  aws s3api put-bucket-policy \
    --bucket "$bucket" \
    --policy file:///tmp/bucket-policy-$bucket.json

  echo "✅ Updated S3 bucket policy for $bucket"
}

echo ""
echo "================================================"
echo "Step 1: Staging User Frontend CloudFront"
echo "================================================"

BUCKET="gli-user-frontend-staging"
DOMAIN="stg.glibiz.com"

echo "Creating OAI for $BUCKET..."
OAI_ID=$(create_oai "GLI Staging User Frontend OAI")
echo "OAI ID: $OAI_ID"

echo "Updating S3 bucket policy..."
update_s3_bucket_policy "$BUCKET" "$OAI_ID"

echo "Creating CloudFront distribution..."

cat > /tmp/cf-config-stg-user.json <<EOF
{
  "CallerReference": "gli-stg-user-$(date +%s)",
  "Comment": "GLI Staging User Frontend",
  "Aliases": {
    "Quantity": 1,
    "Items": ["$DOMAIN"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET",
        "DomainName": "$BUCKET.s3.ap-northeast-2.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "Enabled": true,
  "ViewerCertificate": {
    "ACMCertificateArn": "$ACM_CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "PriceClass": "PriceClass_100",
  "HttpVersion": "http2and3"
}
EOF

DIST_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cf-config-stg-user.json \
  --query 'Distribution.Id' \
  --output text)

DIST_DOMAIN=$(aws cloudfront get-distribution \
  --id "$DIST_ID" \
  --query 'Distribution.DomainName' \
  --output text)

echo "✅ Created CloudFront Distribution"
echo "   ID: $DIST_ID"
echo "   Domain: $DIST_DOMAIN"

# Create Route53 record
echo "Creating Route53 record for $DOMAIN..."

cat > /tmp/route53-cf-stg-user.json <<EOF
{
  "Comment": "CloudFront for Staging User Frontend",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$DIST_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/route53-cf-stg-user.json > /dev/null

echo "✅ Created Route53 record: $DOMAIN"
echo ""

echo "================================================"
echo "Step 2: Staging Admin Dashboard CloudFront"
echo "================================================"

BUCKET="gli-admin-frontend-staging"
DOMAIN="stg-admin.glibiz.com"

echo "Creating OAI for $BUCKET..."
OAI_ID=$(create_oai "GLI Staging Admin Dashboard OAI")
echo "OAI ID: $OAI_ID"

echo "Updating S3 bucket policy..."
update_s3_bucket_policy "$BUCKET" "$OAI_ID"

echo "Creating CloudFront distribution..."

cat > /tmp/cf-config-stg-admin.json <<EOF
{
  "CallerReference": "gli-stg-admin-$(date +%s)",
  "Comment": "GLI Staging Admin Dashboard",
  "Aliases": {
    "Quantity": 1,
    "Items": ["$DOMAIN"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET",
        "DomainName": "$BUCKET.s3.ap-northeast-2.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "Enabled": true,
  "ViewerCertificate": {
    "ACMCertificateArn": "$ACM_CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "PriceClass": "PriceClass_100",
  "HttpVersion": "http2and3"
}
EOF

DIST_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cf-config-stg-admin.json \
  --query 'Distribution.Id' \
  --output text)

DIST_DOMAIN=$(aws cloudfront get-distribution \
  --id "$DIST_ID" \
  --query 'Distribution.DomainName' \
  --output text)

echo "✅ Created CloudFront Distribution"
echo "   ID: $DIST_ID"
echo "   Domain: $DIST_DOMAIN"

# Create Route53 record
echo "Creating Route53 record for $DOMAIN..."

cat > /tmp/route53-cf-stg-admin.json <<EOF
{
  "Comment": "CloudFront for Staging Admin Dashboard",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$DIST_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/route53-cf-stg-admin.json > /dev/null

echo "✅ Created Route53 record: $DOMAIN"
echo ""

echo "================================================"
echo "Step 3: Production User Frontend CloudFront"
echo "================================================"

BUCKET="gli-user-frontend-production"
DOMAINS=("glibiz.com" "www.glibiz.com")

echo "Creating OAI for $BUCKET..."
OAI_ID=$(create_oai "GLI Production User Frontend OAI")
echo "OAI ID: $OAI_ID"

echo "Updating S3 bucket policy..."
update_s3_bucket_policy "$BUCKET" "$OAI_ID"

echo "Creating CloudFront distribution..."

cat > /tmp/cf-config-prod-user.json <<EOF
{
  "CallerReference": "gli-prod-user-$(date +%s)",
  "Comment": "GLI Production User Frontend",
  "Aliases": {
    "Quantity": 2,
    "Items": ["glibiz.com", "www.glibiz.com"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET",
        "DomainName": "$BUCKET.s3.ap-northeast-2.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "Enabled": true,
  "ViewerCertificate": {
    "ACMCertificateArn": "$ACM_CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "PriceClass": "PriceClass_All",
  "HttpVersion": "http2and3"
}
EOF

DIST_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cf-config-prod-user.json \
  --query 'Distribution.Id' \
  --output text)

DIST_DOMAIN=$(aws cloudfront get-distribution \
  --id "$DIST_ID" \
  --query 'Distribution.DomainName' \
  --output text)

echo "✅ Created CloudFront Distribution"
echo "   ID: $DIST_ID"
echo "   Domain: $DIST_DOMAIN"

# Create Route53 records
echo "Creating Route53 records..."

cat > /tmp/route53-cf-prod-user.json <<EOF
{
  "Comment": "CloudFront for Production User Frontend",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "glibiz.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$DIST_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.glibiz.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$DIST_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/route53-cf-prod-user.json > /dev/null

echo "✅ Created Route53 records: glibiz.com, www.glibiz.com"
echo ""

echo "================================================"
echo "Step 4: Production Admin Dashboard CloudFront"
echo "================================================"

BUCKET="gli-admin-frontend-production"
DOMAIN="admin.glibiz.com"

echo "Creating OAI for $BUCKET..."
OAI_ID=$(create_oai "GLI Production Admin Dashboard OAI")
echo "OAI ID: $OAI_ID"

echo "Updating S3 bucket policy..."
update_s3_bucket_policy "$BUCKET" "$OAI_ID"

echo "Creating CloudFront distribution..."

cat > /tmp/cf-config-prod-admin.json <<EOF
{
  "CallerReference": "gli-prod-admin-$(date +%s)",
  "Comment": "GLI Production Admin Dashboard",
  "Aliases": {
    "Quantity": 1,
    "Items": ["$DOMAIN"]
  },
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET",
        "DomainName": "$BUCKET.s3.ap-northeast-2.amazonaws.com",
        "S3OriginConfig": {
          "OriginAccessIdentity": "origin-access-identity/cloudfront/$OAI_ID"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/index.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "Enabled": true,
  "ViewerCertificate": {
    "ACMCertificateArn": "$ACM_CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "PriceClass": "PriceClass_All",
  "HttpVersion": "http2and3"
}
EOF

DIST_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cf-config-prod-admin.json \
  --query 'Distribution.Id' \
  --output text)

DIST_DOMAIN=$(aws cloudfront get-distribution \
  --id "$DIST_ID" \
  --query 'Distribution.DomainName' \
  --output text)

echo "✅ Created CloudFront Distribution"
echo "   ID: $DIST_ID"
echo "   Domain: $DIST_DOMAIN"

# Create Route53 record
echo "Creating Route53 record for $DOMAIN..."

cat > /tmp/route53-cf-prod-admin.json <<EOF
{
  "Comment": "CloudFront for Production Admin Dashboard",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$DIST_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/route53-cf-prod-admin.json > /dev/null

echo "✅ Created Route53 record: $DOMAIN"
echo ""

echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ 모든 CloudFront Distributions 생성 완료!"
echo ""
echo "⚠️  중요: CloudFront 배포는 15-20분 소요됩니다"
echo ""
echo "생성된 도메인:"
echo "  Staging:"
echo "    - https://stg.glibiz.com"
echo "    - https://stg-admin.glibiz.com"
echo ""
echo "  Production:"
echo "    - https://glibiz.com"
echo "    - https://www.glibiz.com"
echo "    - https://admin.glibiz.com"
echo ""
echo "다음 단계:"
echo "  1. CloudFront 배포 완료 대기 (15-20분)"
echo "  2. Frontend 코드 배포"
echo "  3. 도메인 접속 테스트"
echo ""
echo "CloudFront 배포 상태 확인:"
echo "  aws cloudfront list-distributions --query 'DistributionList.Items[*].{Id:Id,Status:Status,Domain:DomainName}' --output table"
echo ""
echo "================================================"
