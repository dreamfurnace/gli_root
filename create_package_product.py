#!/usr/bin/env python
"""
패키지 상품 생성 스크립트
"""
import os
import sys
import django

# Django 설정
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
sys.path.insert(0, '/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server')
django.setup()

from apps.gli_content.models import ShoppingCategory, ShoppingProductType, ShoppingProduct

# 패키지 카테고리 및 상품 유형 가져오기
package_cat = ShoppingCategory.objects.get(name='패키지')
package_type = ShoppingProductType.objects.get(code='package', category=package_cat)

# 기존 패키지 삭제 (중복 방지)
ShoppingProduct.objects.filter(
    name="GLI 글렌메리 골프 & 힐링 프리미엄 투어"
).delete()

# 패키지 상품 생성
package_data = {
    "subtitle": "Luxurious Wellness Journey",
    "price_description": "1인 기준 · 프리미엄 패키지 포함",
    "feature_cards": [
        {
            "icon": "sparkle",
            "title": "Healing",
            "description": "럭셔리 스파 & 웰니스"
        },
        {
            "icon": "golf",
            "title": "Golf",
            "description": "가든/밸리 36홀 라운딩"
        }
    ],
    "core_features": [
        {
            "icon": "✨",
            "title": "힐링 세션",
            "description": "전신 아로마 스파 및 발 케어 포함"
        },
        {
            "icon": "⛳",
            "title": "고품격 골프",
            "description": "말레이시아 랭킹권 가든/밸리 코스 교차 라운딩"
        },
        {
            "icon": "🥂",
            "title": "미식 경험",
            "description": "현지 한식 특식 및 로컬 야시장 푸드 투어"
        },
        {
            "icon": "🚐",
            "title": "전용 의전",
            "description": "공항 영접 및 쇼핑몰 투어 전용 차량 지원"
        }
    ],
    "service_details": {
        "included": [
            "글렌메리 호텔 Deluxe Room (4박)",
            "가든/밸리 코스 18홀 라운딩 2회 (그린피/카트피)",
            "피로 회복 스파 또는 발 마사지 세션",
            "시내 투어 및 전용 차량 의전 서비스",
            "전 일정 조식/석식 (야시장 투어 포함)"
        ],
        "not_included": [
            "국제선 왕복 항공권",
            "캐디피 및 캐디팁 (현장 결제)",
            "일부 일정 내 개별 중식"
        ]
    },
    "itinerary": [
        {
            "day": 1,
            "title": "1일 차 : 입국 및 휴식",
            "schedule": [
                {
                    "time": "15:00 ~",
                    "description": "글렌메리 호텔 체크인 및 휴식",
                    "note": "숙소 이동 (약 45분 소요)"
                }
            ]
        },
        {
            "day": 2,
            "title": "2일 차 : 본격적인 라운딩의 시작",
            "schedule": [
                {"time": "07:00~08:30", "description": "호텔 조식 및 라운딩 준비 (리조트 내 레스토랑)", "note": ""},
                {"time": "09:00~13:30", "description": "글렌메리 CC 18홀 라운딩 (가든 또는 밸리 코스)", "note": ""},
                {"time": "13:30~15:00", "description": "클럽하우스 중식 및 샤워 (현지식 또는 클럽식)", "note": ""},
                {"time": "15:00~18:00", "description": "리조트 내 자유 시간 (수영장, 스파, 휴식)", "note": ""},
                {"time": "18:30~20:30", "description": "호텔 석식 및 자유 일정 (리조트 내 디너)", "note": ""}
            ]
        },
        {
            "day": 3,
            "title": "3일 차 : 골프와 시내 투어의 조화",
            "schedule": [
                {"time": "09:00~13:30", "description": "글렌메리 CC 18홀 라운딩 (2회차 코스 교차 진행)", "note": ""},
                {"time": "14:00~15:30", "description": "쿠알라룸푸르 시내 이동 및 늦은 점심", "note": ""},
                {"time": "15:30~18:30", "description": "시내 투어 (KLCC 트윈타워, 바투 동굴 등 주요 명소)", "note": ""},
                {"time": "19:00~21:00", "description": "잘란알로 야시장 투어 및 로컬 맛집 탐방 저녁 식사", "note": ""}
            ]
        },
        {
            "day": 4,
            "title": "4일 차 : 여유로운 관광과 쇼핑",
            "schedule": [
                {"time": "09:00~12:00", "description": "리조트 조식 후 자유 시간 (개인 휴식 및 산책)", "note": ""},
                {"time": "12:00~15:00", "description": "파빌리온 쇼핑몰 방문 및 부킷 빈탕 지역 개별 중식", "note": ""},
                {"time": "15:00~18:00", "description": "푸트라자야 행정도시 및 핑크 모스크 관광", "note": ""},
                {"time": "18:30~20:30", "description": "현지 한식 특식 또는 로컬 푸드 석식", "note": ""}
            ]
        },
        {
            "day": 5,
            "title": "5일 차 : 여정의 마무리 및 귀국",
            "schedule": [
                {"time": "10:00~13:00", "description": "체크아웃 후 수리야 KLCC 쇼핑 (기념품 및 명품)", "note": ""},
                {"time": "13:00~15:00", "description": "시내 올드타운 산책 및 여유로운 카페 투어 티타임", "note": ""},
                {"time": "15:00~17:00", "description": "발 마사지 또는 전신 스파 (마지막 피로 회복)", "note": ""},
                {"time": "18:00~20:00", "description": "공항 이동 및 출국 수속 (출발 3시간 전 도착)", "note": ""},
                {"time": "23:00 ~", "description": "쿠알라룸푸르 출발 (기내박)", "note": "익일 아침 인천 공항 도착"}
            ]
        }
    ]
}

product = ShoppingProduct.objects.create(
    category=package_cat,
    product_type=package_type,
    name="GLI 글렌메리 골프 & 힐링 프리미엄 투어",
    name_en="GLI Glenmarie Golf & Healing Premium Tour",
    description="말레이시아 랭킹권 가든/밸리 코스에서의 36홀 라운딩과 럭셔리 스파 웰니스가 결합된 프리미엄 패키지입니다. 전신 아로마 스파, 현지 한식 특식, 쇼핑몰 투어, 전용 차량 의전 서비스가 포함되어 있습니다.",
    short_description="골프 라운딩과 힐링 스파가 결합된 5일 프리미엄 투어",
    price_glil=1250000,
    price_usd=935,
    unlimited_stock=True,
    stock_quantity=0,
    status='active',
    is_featured=True,
    main_image_url="https://images.unsplash.com/photo-1535131749006-b7f58c99034b?auto=format&fit=crop&q=80&w=1200",
    image_urls=[
        "https://images.unsplash.com/photo-1592910129881-8ec20239466c?auto=format&fit=crop&q=80&w=400",
        "https://images.unsplash.com/photo-1610641818989-c2051b5e2cfd?auto=format&fit=crop&q=80&w=400",
        "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&q=80&w=400"
    ],
    tags=["라운딩과휴식", "명문36홀", "럭셔리스파포함", "프라이빗의전"],
    attributes={"package_data": package_data}
)

print(f"✅ 패키지 상품 생성 완료!")
print(f"   ID: {product.id}")
print(f"   이름: {product.name}")
print(f"   가격: {product.price_glil:,} GLI-L")
print(f"   URL: http://localhost:3000/shopping/package/{product.id}")
