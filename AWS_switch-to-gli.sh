#!/bin/bash
# GLI AWS 계정으로 빠른 전환 스크립트

echo "🔄 GLI AWS 계정으로 전환 중..."

# GLI 키 설정 (gli 프로필 사용)
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
export AWS_PROFILE=gli
export AWS_REGION=ap-northeast-2

# 전환 확인
echo "📋 현재 AWS 계정 정보:"
aws sts get-caller-identity

# 계정 확인
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
EXPECTED_ACCOUNT="917891822317"

if [ "$ACCOUNT" = "$EXPECTED_ACCOUNT" ]; then
    echo "✅ GLI 계정 ($ACCOUNT)으로 전환 완료"
    echo "   IAM 사용자: gli (ahn+gli@dreamfurnace.im)"
    echo "   권한: AdministratorAccess"
else
    echo "❌ 전환 실패 - 현재 계정: ${ACCOUNT:-없음}"
    echo "   예상 계정: $EXPECTED_ACCOUNT"
    echo "   AWS CLI 설정을 확인하세요"
fi

echo ""
echo "💡 이 터미널 세션에서 GLI AWS 서비스를 사용할 수 있습니다."
