#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}GLI 뉴스 API CORS 테스트${NC}"
echo -e "${BLUE}gligateway.com 접근 허가 확인${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 테스트할 환경들
declare -A ENVIRONMENTS=(
    ["local"]="http://localhost:8000"
    ["staging"]="https://stg-api.glibiz.com"
    ["production"]="https://api.glibiz.com"
)

# 환경 이름 매핑
declare -A ENV_NAMES=(
    ["local"]="로컬"
    ["staging"]="스테이징"
    ["production"]="운영"
)

# 테스트할 Origin
ORIGIN="https://gligateway.com"

# 테스트 함수
test_cors() {
    local env_key=$1
    local api_url=$2
    local env_name="${ENV_NAMES[$env_key]}"
    local endpoint="/api/news/"

    echo -e "${YELLOW}[${env_name}] ${api_url}${endpoint}${NC}"
    echo -e "Origin: ${ORIGIN}\n"

    # OPTIONS 요청 (Preflight)
    echo -e "${BLUE}1. OPTIONS 요청 (Preflight Check)${NC}"
    response=$(curl -i -X OPTIONS "${api_url}${endpoint}" \
        -H "Origin: ${ORIGIN}" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: Content-Type" \
        -s)

    # CORS 헤더 확인
    if echo "$response" | grep -q "Access-Control-Allow-Origin: ${ORIGIN}"; then
        echo -e "${GREEN}✅ Access-Control-Allow-Origin: ${ORIGIN}${NC}"
    elif echo "$response" | grep -q "Access-Control-Allow-Origin: \*"; then
        echo -e "${GREEN}✅ Access-Control-Allow-Origin: * (모든 도메인 허용)${NC}"
    else
        echo -e "${RED}❌ Access-Control-Allow-Origin 헤더 없음${NC}"
        echo -e "${RED}   CORS 설정이 올바르지 않습니다!${NC}"
    fi

    if echo "$response" | grep -q "Access-Control-Allow-Credentials: true"; then
        echo -e "${GREEN}✅ Access-Control-Allow-Credentials: true${NC}"
    else
        echo -e "${YELLOW}⚠️  Access-Control-Allow-Credentials 헤더 없음${NC}"
    fi

    if echo "$response" | grep -q "Access-Control-Allow-Methods:"; then
        methods=$(echo "$response" | grep "Access-Control-Allow-Methods:" | cut -d: -f2- | tr -d '\r')
        echo -e "${GREEN}✅ Access-Control-Allow-Methods:${methods}${NC}"
    fi

    echo ""

    # GET 요청 (실제 데이터 조회)
    echo -e "${BLUE}2. GET 요청 (실제 API 호출)${NC}"
    response=$(curl -i -X GET "${api_url}${endpoint}" \
        -H "Origin: ${ORIGIN}" \
        -s)

    # HTTP 상태 코드 확인
    status_code=$(echo "$response" | grep "HTTP/" | awk '{print $2}' | head -1)

    if [ "$status_code" == "200" ]; then
        echo -e "${GREEN}✅ HTTP Status: ${status_code} (성공)${NC}"

        # JSON 데이터 개수 확인
        json_body=$(echo "$response" | sed -n '/^\[/,$p')
        if [ ! -z "$json_body" ]; then
            news_count=$(echo "$json_body" | grep -o '"id"' | wc -l)
            echo -e "${GREEN}✅ 뉴스 데이터 ${news_count}개 조회됨${NC}"
        fi
    else
        echo -e "${RED}❌ HTTP Status: ${status_code} (실패)${NC}"
        echo -e "${RED}   API 응답이 올바르지 않습니다!${NC}"
    fi

    # CORS 헤더 재확인
    if echo "$response" | grep -q "Access-Control-Allow-Origin:"; then
        origin_value=$(echo "$response" | grep "Access-Control-Allow-Origin:" | cut -d: -f2- | tr -d '\r' | xargs)
        echo -e "${GREEN}✅ Access-Control-Allow-Origin: ${origin_value}${NC}"
    else
        echo -e "${RED}❌ Access-Control-Allow-Origin 헤더 없음 (GET 요청)${NC}"
    fi

    echo -e "\n${BLUE}----------------------------------------${NC}\n"
}

# 모든 환경 테스트
for env_key in "${!ENVIRONMENTS[@]}"; do
    api_url="${ENVIRONMENTS[$env_key]}"
    test_cors "$env_key" "$api_url"
done

# 개별 뉴스 상세 조회 테스트
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}3. 뉴스 상세 조회 테스트 (샘플)${NC}"
echo -e "${BLUE}========================================${NC}\n"

# 스테이징 환경에서 첫 번째 뉴스 ID 가져오기
echo -e "${YELLOW}[스테이징] 첫 번째 뉴스 ID 조회 중...${NC}"
first_news=$(curl -s "https://stg-api.glibiz.com/api/news/" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ ! -z "$first_news" ]; then
    echo -e "${GREEN}✅ 첫 번째 뉴스 ID: ${first_news}${NC}\n"

    echo -e "${YELLOW}[스테이징] 뉴스 상세 조회 테스트${NC}"
    detail_response=$(curl -i -X GET "https://stg-api.glibiz.com/api/news/${first_news}/" \
        -H "Origin: ${ORIGIN}" \
        -s)

    status_code=$(echo "$detail_response" | grep "HTTP/" | awk '{print $2}' | head -1)

    if [ "$status_code" == "200" ]; then
        echo -e "${GREEN}✅ 뉴스 상세 조회 성공 (ID: ${first_news})${NC}"
    else
        echo -e "${RED}❌ 뉴스 상세 조회 실패 (HTTP ${status_code})${NC}"
    fi

    if echo "$detail_response" | grep -q "Access-Control-Allow-Origin:"; then
        echo -e "${GREEN}✅ CORS 헤더 포함됨${NC}"
    else
        echo -e "${RED}❌ CORS 헤더 없음${NC}"
    fi
else
    echo -e "${RED}❌ 뉴스 데이터가 없습니다. 관리자 페이지에서 뉴스를 먼저 등록해주세요.${NC}"
fi

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}테스트 완료${NC}"
echo -e "${BLUE}========================================${NC}"
