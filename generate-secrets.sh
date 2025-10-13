#!/bin/bash

# GLI Project - Generate All Required Secrets
# Django Secret Keys, JWT Keys 생성

set -e

OUTPUT_DIR=".secrets"
mkdir -p "$OUTPUT_DIR"

echo "================================================"
echo "GLI Secret Keys 생성"
echo "================================================"
echo ""
echo "이 스크립트는 다음을 생성합니다:"
echo "  1. Django Secret Keys (Staging, Production)"
echo "  2. JWT Key Pairs (Staging, Production)"
echo ""
echo "생성된 키는 '$OUTPUT_DIR' 디렉토리에 저장됩니다."
echo "⚠️  이 디렉토리는 .gitignore에 포함되어 있습니다."
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

echo ""
echo "================================================"
echo "Step 1: Django Secret Keys 생성"
echo "================================================"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
  echo "❌ Python3가 설치되어 있지 않습니다"
  exit 1
fi

echo "Staging Django Secret Key 생성 중..."
DJANGO_SECRET_STAGING=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
echo "$DJANGO_SECRET_STAGING" > "$OUTPUT_DIR/django_secret_staging.txt"
echo "✅ 생성 완료: $OUTPUT_DIR/django_secret_staging.txt"

echo "Production Django Secret Key 생성 중..."
DJANGO_SECRET_PRODUCTION=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
echo "$DJANGO_SECRET_PRODUCTION" > "$OUTPUT_DIR/django_secret_production.txt"
echo "✅ 생성 완료: $OUTPUT_DIR/django_secret_production.txt"

echo ""
echo "================================================"
echo "Step 2: JWT Key Pairs 생성"
echo "================================================"

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
  echo "❌ openssl이 설치되어 있지 않습니다"
  exit 1
fi

echo "Staging JWT Keys 생성 중..."

# Generate private key
openssl genrsa -out "$OUTPUT_DIR/jwt_private_staging.pem" 2048 2>/dev/null
echo "✅ 생성 완료: $OUTPUT_DIR/jwt_private_staging.pem"

# Generate public key
openssl rsa -in "$OUTPUT_DIR/jwt_private_staging.pem" -pubout -out "$OUTPUT_DIR/jwt_public_staging.pem" 2>/dev/null
echo "✅ 생성 완료: $OUTPUT_DIR/jwt_public_staging.pem"

echo ""
echo "Production JWT Keys 생성 중..."

# Generate private key
openssl genrsa -out "$OUTPUT_DIR/jwt_private_production.pem" 2048 2>/dev/null
echo "✅ 생성 완료: $OUTPUT_DIR/jwt_private_production.pem"

# Generate public key
openssl rsa -in "$OUTPUT_DIR/jwt_private_production.pem" -pubout -out "$OUTPUT_DIR/jwt_public_production.pem" 2>/dev/null
echo "✅ 생성 완료: $OUTPUT_DIR/jwt_public_production.pem"

echo ""
echo "================================================"
echo "Step 3: Summary 파일 생성"
echo "================================================"

cat > "$OUTPUT_DIR/SECRETS_SUMMARY.md" <<EOF
# GLI Platform Secrets Summary

**생성일시**: $(date '+%Y-%m-%d %H:%M:%S')

## Django Secret Keys

### Staging
\`\`\`
$DJANGO_SECRET_STAGING
\`\`\`

### Production
\`\`\`
$DJANGO_SECRET_PRODUCTION
\`\`\`

## JWT Keys

### Staging Private Key
파일: jwt_private_staging.pem
\`\`\`
$(cat "$OUTPUT_DIR/jwt_private_staging.pem")
\`\`\`

### Staging Public Key
파일: jwt_public_staging.pem
\`\`\`
$(cat "$OUTPUT_DIR/jwt_public_staging.pem")
\`\`\`

### Production Private Key
파일: jwt_private_production.pem
\`\`\`
$(cat "$OUTPUT_DIR/jwt_private_production.pem")
\`\`\`

### Production Public Key
파일: jwt_public_production.pem
\`\`\`
$(cat "$OUTPUT_DIR/jwt_public_production.pem")
\`\`\`

## GitHub Secrets 설정 방법

### gli_api-server

Staging:
\`\`\`
SECRET_KEY_STAGING=$DJANGO_SECRET_STAGING
JWT_PRIVATE_KEY_STAGING=<jwt_private_staging.pem 내용>
JWT_PUBLIC_KEY_STAGING=<jwt_public_staging.pem 내용>
\`\`\`

Production:
\`\`\`
SECRET_KEY_PRODUCTION=$DJANGO_SECRET_PRODUCTION
JWT_PRIVATE_KEY_PRODUCTION=<jwt_private_production.pem 내용>
JWT_PUBLIC_KEY_PRODUCTION=<jwt_public_production.pem 내용>
\`\`\`

## 보안 주의사항

⚠️ 이 파일들은 절대 Git에 커밋하지 마세요!
✅ .gitignore에 .secrets/ 가 포함되어 있습니다.
✅ GitHub Secrets 설정 후 이 파일들을 안전하게 백업하세요.

---
**생성 스크립트**: generate-secrets.sh
EOF

echo "✅ 생성 완료: $OUTPUT_DIR/SECRETS_SUMMARY.md"

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ 모든 Secret Keys 생성 완료!"
echo ""
echo "생성된 파일:"
echo "  - $OUTPUT_DIR/django_secret_staging.txt"
echo "  - $OUTPUT_DIR/django_secret_production.txt"
echo "  - $OUTPUT_DIR/jwt_private_staging.pem"
echo "  - $OUTPUT_DIR/jwt_public_staging.pem"
echo "  - $OUTPUT_DIR/jwt_private_production.pem"
echo "  - $OUTPUT_DIR/jwt_public_production.pem"
echo "  - $OUTPUT_DIR/SECRETS_SUMMARY.md"
echo ""
echo "다음 단계:"
echo "  1. $OUTPUT_DIR/SECRETS_SUMMARY.md 확인"
echo "  2. GitHub Secrets 설정"
echo "  3. 안전한 곳에 백업"
echo "  4. 필요시 이 디렉토리 삭제"
echo ""
echo "⚠️  중요: 이 파일들은 절대 Git에 커밋하지 마세요!"
echo "================================================"
