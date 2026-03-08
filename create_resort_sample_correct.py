#!/usr/bin/env python3
"""
참고 파일과 완전히 동일한 GLI 그랜드 아주르 리조트 & 스파 샘플 데이터 생성 스크립트
"""

import os
import sys

# 환경 변수 로드
from pathlib import Path
from dotenv import load_dotenv

# .env.development 파일 로드
env_path = Path('/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server/.env.development')
load_dotenv(env_path)

# Django 설정
sys.path.append('/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

import django
django.setup()

from apps.gli_content.models import ShoppingProduct, ShoppingCategory, ShoppingProductType

# 카테고리 및 상품 유형 ID
CATEGORY_ID = "d624364e-e997-430d-91ef-3ef0171a11fc"  # 리조트&호텔 예약
PRODUCT_TYPE_ID = "e944fd87-4736-462e-8db8-9f8ae09a387f"  # 리조트

# 참고 파일과 완전히 동일한 리조트 데이터
resort_data = {
    "location": "몰디브, 아리 아톨 프라이빗 아일랜드",
    "rating": 5,
    "brand_story": "2018년 첫 문을 연 그랜드 아주르 리조트는 몰디브 최고의 지속 가능성 럭셔리 리조트로 자리 잡았습니다. 섬 고유의 식생을 그대로 보존하여 자연과 건축물이 하나가 되도록 설계되었습니다.",
    "check_in": "오후 14:00",
    "check_out": "오전 12:00",
    "facilities": [
        {"icon": "user-check", "name": "24시간 퍼스널 버틀러"},
        {"icon": "cigarette-off", "name": "금연 객실"},
        {"icon": "coffee", "name": "커피숍"},
        {"icon": "palmtree", "name": "정원"},
        {"icon": "car", "name": "무료 주차"},
        {"icon": "wifi", "name": "무료 와이파이"},
        {"icon": "waves", "name": "야외 수영장"},
        {"icon": "utensils", "name": "레스토랑"}
    ],
    "highlights": [
        {
            "icon": "award",
            "title": "독보적인 위치",
            "description": "아리 아톨의 가장 아름다운 산호초 군락지에 위치하여 객실에서 바로 스노클링이 가능합니다."
        },
        {
            "icon": "utensils",
            "title": "미쉐린 스타 다이닝",
            "description": "세계적인 셰프들이 선보이는 5개의 레스토랑에서 매일 다른 미식 경험을 제공합니다."
        },
        {
            "icon": "shield-check",
            "title": "프라이빗 케어",
            "description": "모든 투숙객에게 24시간 전담 버틀러 서비스를 제공하여 완벽한 프라이버시를 보장합니다."
        }
    ],
    "map_embed_url": "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d15911.660144577237!2d72.8443!3d3.5937!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x24b59ec011d17d5d%3A0x6b4034b172d76550!2sMaldives!5e0!3m2!1sen!2skr!4v1700000000000!5m2!1sen!2skr",
    "room_types": [
        {
            "id": "deluxe",
            "name": "디럭스 오션 룸",
            "name_en": "Deluxe Ocean Room",
            "description": "끝없이 펼쳐지는 에메랄드빛 바다를 한눈에 담을 수 있는 실속형 럭셔리 객실입니다.",
            "capacity": {"adult": 2, "child": 1},
            "price_glil": 450000,
            "features": ["킹 사이즈 침대", "오션뷰 테라스", "대리석 마감 욕실"],
            "amenities": {
                "bedding": ["400수 이집트산 면 시트", "맞춤형 베개 메뉴(6종)", "구스다운 이불"],
                "tech": ["65인치 OLED 스마트 TV", "블루투스 스피커", "통합 제어 태블릿"],
                "beverage": ["네스프레소 머신 & 캡슐", "고급 티 셀렉션", "데일리 생수 제공"],
                "bathroom": ["바이레도(Byredo) 어메니티", "이탈리아산 대리석 욕조", "순면 가운 & 슬리퍼"],
                "security": ["디지털 안전 금고", "24시간 보안 시스템"]
            },
            "image": "https://images.unsplash.com/photo-1618773928121-c32242e63f39?q=80&w=1200"
        },
        {
            "id": "suite",
            "name": "아주르 가든 스위트",
            "name_en": "Azure Garden Suite",
            "description": "프라이빗한 정원과 거실 공간이 분리되어 독립성을 강조한 스위트룸입니다.",
            "capacity": {"adult": 2, "child": 2},
            "price_glil": 780000,
            "features": ["거실 및 침실 분리", "전용 가든 테라스", "프리미엄 아일랜드 욕조"],
            "amenities": {
                "bedding": ["600수 프리미엄 리넨", "구스다운 필로우 세트", "숙면 유도 아로마 키트"],
                "tech": ["Bose 서라운드 사운드 시스템", "AI 음성인식 객실 제어", "듀얼 스마트 TV"],
                "beverage": ["개별 와인 셀러", "프리미엄 미니바(매일 리필)", "수공예 다기 세트"],
                "bathroom": ["딥티크(Diptyque) 풀 세트", "대형 아일랜드 스파 욕조", "더블 세면대 & 파우더룸"],
                "security": ["생체인식 금고", "전용 버틀러 호출 벨"]
            },
            "image": "https://images.unsplash.com/photo-1590490360182-c33d57733427?q=80&w=1200"
        },
        {
            "id": "family",
            "name": "아주르 패밀리 스위트",
            "name_en": "Azure Family Suite",
            "description": "가족 단위 여행객을 위한 넓은 공간과 아이들을 위한 특별한 어메니티가 준비된 패밀리 럭셔리 공간입니다.",
            "capacity": {"adult": 4, "child": 2},
            "price_glil": 950000,
            "features": ["2베드룸 + 2욕실", "커스텀 키즈 존", "오션뷰 파티오"],
            "amenities": {
                "bedding": ["패밀리 사이즈 킹 베드 2개", "키즈 전용 캐릭터 침구", "추가 엑스트라 베드 가능"],
                "tech": ["게이밍 콘솔(PS5/Switch 선택 가능)", "키즈 안심 채널 스트리밍", "멀티 충전 스테이션"],
                "beverage": ["키즈 전용 간식 바", "유기농 주스 & 우유", "이유식 가열기(요청 시)"],
                "bathroom": ["키즈 전용 저자극 어메니티", "유아용 발판 & 변기 커버", "패밀리 사이즈 대형 욕조"],
                "security": ["가구 모서리 보호 처리", "동선 최적화 안전 조명"]
            },
            "image": "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?q=80&w=1200"
        },
        {
            "id": "villa",
            "name": "로열 클리프 빌라",
            "name_en": "Royal Cliff Villa",
            "description": "절벽 끝에 위치해 최고의 프라이버시와 파노라마 뷰를 보장하는 최상급 빌라입니다.",
            "capacity": {"adult": 4, "child": 0},
            "price_glil": 1350000,
            "features": ["개별 전용 인피니티 풀", "2베드룸 구성", "야외 레인 샤워 시설"],
            "amenities": {
                "bedding": ["800수 최고급 실크 리넨", "천연 라텍스 매트리스", "실크 아이 마스크"],
                "tech": ["프라이빗 야외 시네마 시설", "뱅앤올룹슨(B&O) 오디오", "전구역 무선 스마트 제어"],
                "beverage": ["빈티지 와인 셀러", "인빌라 커피 바 스테이션", "프라이빗 칵테일 바"],
                "bathroom": ["에르메스(Hermès) 바디 케어", "야외 프라이빗 레인 샤워", "히노끼 스파 공간"],
                "security": ["최첨단 지능형 보안 시스템", "전담 보안 요원 호출 서비스"]
            },
            "image": "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=1200"
        },
        {
            "id": "presidential",
            "name": "프레지덴셜 오버워터 빌라",
            "name_en": "Presidential Overwater Villa",
            "description": "수면 위에 떠 있는 리조트 최고의 정점. 바닥의 통유리를 통해 바다를 감상할 수 있는 궁극의 빌라입니다.",
            "capacity": {"adult": 6, "child": 2},
            "price_glil": 2100000,
            "features": ["워터 슬라이드 포함 개인 풀", "360도 오션 파노라마", "전용 영화 상영실"],
            "amenities": {
                "bedding": ["1000수 맞춤 제작 침구", "숙면 전문가의 컨설팅 서비스", "전동 조절식 모션 베드"],
                "tech": ["개별 전용 영화 상영실", "통유리 바닥 인터랙티브 디스플레이", "최첨단 헬스케어 시스템"],
                "beverage": ["그랑 크뤼 급 와인 셀러", "전문 바리스타 기기", "상시 전담 셰프 대기"],
                "bathroom": ["커스텀 향수 제조 어메니티", "순금 마감 수전 & 금박 욕조", "바다 직결 야외 자쿠지"],
                "security": ["최상위 등 보안 구역 지정", "안면 인식 출입 시스템"]
            },
            "image": "https://images.unsplash.com/photo-1439066615861-d1af74d74000?q=80&w=1200"
        }
    ],
    "reviews": [
        {
            "id": "review-1",
            "user_name": "김*훈",
            "room_type": "디럭스 오션 룸",
            "rating": 5,
            "date": "2024.01.15",
            "comment": "꿈만 같았던 신혼여행이었습니다. 버틀러 서비스가 정말 완벽했어요.",
            "verified": True
        },
        {
            "id": "review-2",
            "user_name": "이*영",
            "room_type": "아주르 패밀리 스위트",
            "rating": 5,
            "date": "2024.02.10",
            "comment": "가족 여행으로 다녀왔는데 아이들이 너무 좋아했습니다. 조식이 압권이네요.",
            "verified": True
        },
        {
            "id": "review-3",
            "user_name": "박*민",
            "room_type": "로열 클리프 빌라",
            "rating": 5,
            "date": "2024.03.05",
            "comment": "프라이버시가 완벽하게 보장되는 공간이었습니다. 인피니티 풀에서의 시간이 최고였어요.",
            "verified": True
        }
    ],
    "average_rating": 4.9,
    "total_reviews": 1240
}

def create_resort_sample():
    """리조트 샘플 데이터 생성"""

    # 카테고리 및 상품 유형 확인
    try:
        category = ShoppingCategory.objects.get(id=CATEGORY_ID)
        product_type = ShoppingProductType.objects.get(id=PRODUCT_TYPE_ID)
    except Exception as e:
        print(f"❌ 카테고리 또는 상품 유형을 찾을 수 없습니다: {e}")
        return

    # 기존 샘플 데이터 삭제
    existing = ShoppingProduct.objects.filter(name="GLI 그랜드 아주르 리조트 & 스파").first()
    if existing:
        print(f"⚠️  기존 샘플 데이터 삭제 중... (ID: {existing.id})")
        existing.delete()

    # 리조트 상품 생성
    try:
        resort = ShoppingProduct.objects.create(
            category=category,
            product_type=product_type,
            name="GLI 그랜드 아주르 리조트 & 스파",
            name_en="GLI Grand Azure Resort & Spa",
            description="GLI 그랜드 아주르 리조트는 단순한 숙박을 넘어, 자연의 순수함과 현대적인 기술이 조화를 이루는 궁극의 휴양 공간을 지향합니다.",
            description_en="GLI Grand Azure Resort goes beyond simple accommodation, aiming to create the ultimate resort space where the purity of nature harmonizes with modern technology.",
            short_description="몰디브 아리 아톨 프라이빗 아일랜드의 5성급 럭셔리 리조트",
            price_glil=450000,  # 최저가 (디럭스 오션 룸)
            stock_quantity=50,
            unlimited_stock=True,
            status='active',
            is_featured=True,
            main_image_url="https://images.unsplash.com/photo-1571896349842-33c89424de2d?q=80&w=2000",
            image_urls=[
                "https://images.unsplash.com/photo-1571896349842-33c89424de2d?q=80&w=1200",
                "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?q=80&w=1200",
                "https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=1200",
                "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?q=80&w=1200",
                "https://images.unsplash.com/photo-1535827841776-24afc1e255ac?q=80&w=1200",
                "https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?q=80&w=1200",
                "https://images.unsplash.com/photo-1578683010236-d716f9a3f261?q=80&w=1200",
                "https://images.unsplash.com/photo-1540541338287-41700207dee6?q=80&w=1200",
                "https://images.unsplash.com/photo-1444201983204-c43cbd584d93?q=80&w=1200",
                "https://images.unsplash.com/photo-1510798831971-661eb04b3739?q=80&w=1200"
            ],
            attributes={
                "resort_data": resort_data
            }
        )

        print(f"✅ 참고 파일과 동일한 리조트 샘플 데이터가 생성되었습니다!")
        print(f"   ID: {resort.id}")
        print(f"   이름: {resort.name}")
        print(f"   위치: {resort_data['location']}")
        print(f"   카테고리: {category.name}")
        print(f"   상품 유형: {product_type.name}")
        print(f"   가격: {resort.price_glil:,.0f} GLI-L")
        print(f"   객실 타입: {len(resort_data['room_types'])}개")
        print(f"   갤러리 이미지: {len(resort.image_urls)}개")
        print(f"\n📱 로컬 확인: http://localhost:3000/shopping/resort/{resort.id}")
        print(f"🔧 관리자: http://localhost:3001/shopping/management")

        return resort

    except Exception as e:
        print(f"❌ 리조트 생성 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return None

if __name__ == "__main__":
    print("=" * 60)
    print("GLI 그랜드 아주르 리조트 & 스파 샘플 데이터 생성")
    print("(참고 파일과 완전히 동일한 데이터)")
    print("=" * 60)
    create_resort_sample()
