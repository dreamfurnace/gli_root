#!/bin/bash
# GLI 계정의 모든 해킹된 인스턴스 강제 종료 스크립트
# 2026-03-06 생성

echo "🚨 해킹된 인스턴스 강제 종료 시작..."
echo ""

# GLI AWS 계정으로 전환
source AWS_switch-to-gli.sh

# 모든 리전과 인스턴스 ID
declare -A instances
instances[us-east-1]="i-0a9e2fea468d609d8 i-0016eac292a90d1fb"
instances[us-east-2]="i-0d920003d9a7aa619"
instances[us-west-1]="i-0bf36598ae2d92b22"
instances[us-west-2]="i-0b352c11e8e970d1e i-095fdd3209cfe52f5"
instances[ap-northeast-1]="i-0c88ff4c3910686f8"
instances[ap-south-1]="i-01ac676be3c6a571f i-01e5ea13402cbfee0 i-0cc7db5fa07f46a3d i-0d8974a41d1cf9447 i-01f235147a52a3d23"
instances[ap-southeast-1]="i-0fbcb041f3b612483 i-080ded246a809a2dd i-01f13f7c119be1fb1 i-05c4e6ccee8ff48af i-07fc9150261c46f52"
instances[ap-southeast-2]="i-0107605521ea31922"
instances[eu-central-1]="i-0a0f4291efbe8d34a"
instances[eu-west-1]="i-07a6ff9ee200d4806 i-0f0ce0ab84f81752c i-0c8c8417e911391cc i-009bc7201b82cbd71 i-06a6d93317b5e69cb"
instances[eu-west-2]="i-008e8eec9ba4c250a"
instances[eu-west-3]="i-026d73dc46b963841"
instances[sa-east-1]="i-072ca0968b4cd9583"
instances[ca-central-1]="i-04d73a0295c4072de"

total_count=0
success_count=0
failed_count=0

for region in "${!instances[@]}"; do
  echo "=== 리전: $region ==="

  for instance_id in ${instances[$region]}; do
    total_count=$((total_count + 1))
    echo "  처리 중: $instance_id"

    # 1단계: 종료 보호 비활성화
    echo "    [1/2] 종료 보호 해제 중..."
    aws ec2 modify-instance-attribute \
      --region "$region" \
      --instance-id "$instance_id" \
      --no-disable-api-termination 2>&1 | grep -q "error" && echo "    ⚠️  보호 해제 실패 (이미 해제되었거나 권한 없음)" || echo "    ✅ 보호 해제 완료"

    # 2단계: 인스턴스 종료
    echo "    [2/2] 인스턴스 종료 중..."
    result=$(aws ec2 terminate-instances \
      --region "$region" \
      --instance-ids "$instance_id" \
      --output json 2>&1)

    if echo "$result" | grep -q "shutting-down\|terminated"; then
      echo "    ✅ 종료 성공!"
      success_count=$((success_count + 1))
    else
      echo "    ❌ 종료 실패: $result"
      failed_count=$((failed_count + 1))
    fi
    echo ""
  done
  echo ""
done

echo "========================================"
echo "📊 작업 완료 요약"
echo "========================================"
echo "총 인스턴스 수: $total_count"
echo "성공: $success_count"
echo "실패: $failed_count"
echo ""

if [ $failed_count -eq 0 ]; then
  echo "✅ 모든 해킹된 인스턴스가 성공적으로 종료되었습니다!"
  echo "💰 이제 더 이상 비용이 발생하지 않습니다."
else
  echo "⚠️  일부 인스턴스 종료에 실패했습니다."
  echo "   수동으로 AWS 콘솔에서 확인하세요."
fi
echo ""
echo "🔍 다음 단계:"
echo "  1. IAM 사용자 및 액세스 키 검토"
echo "  2. 보안 그룹 삭제"
echo "  3. CloudTrail 로그 분석"
echo "  4. MFA 설정 및 비밀번호 변경"
echo ""
