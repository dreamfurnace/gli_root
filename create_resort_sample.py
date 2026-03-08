#!/usr/bin/env python3
"""
GLI 그랜드 아주르 리조트 & 스파 샘플 데이터 생성 스크립트
"""

import os
import sys
import django

# Django 설정
sys.path.append('/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.gli_content.models import ShoppingProduct, ShoppingCategory, ShoppingProductType

# 카테고리 및 상품 유형 ID
CATEGORY_ID = "d624364e-e997-430d-91ef-3ef0171a11fc"  # 리조트&호텔 예약
PRODUCT_TYPE_ID = "e944fd87-4736-462e-8db8-9f8ae09a387f"  # 리조트

# 리조트 데이터
resort_data = {
    "location": "제주도 서귀포시 중문관광로 72번길 35",
    "rating": 5,
    "brand_story": "GLI 그랜드 아주르 리조트 & 스파는 제주의 아름다운 해안선을 따라 자리한 럭셔리 리조트입니다. 최상의 서비스와 현대적인 시설, 그리고 자연과 조화를 이루는 공간에서 잊지 못할 추억을 만들어보세요.",
    "check_in": "15:00",
    "check_out": "11:00",
    "facilities": [
        "무료 Wi-Fi",
        "수영장",
        "피트니스 센터",
        "스파 & 사우나",
        "레스토랑 & 바",
        "24시간 룸서비스",
        "발렛 파킹",
        "비즈니스 센터",
        "키즈 클럽",
        "해변 접근"
    ],
    "highlights": [
        "🌊 오션뷰 객실에서 바라보는 환상적인 일출",
        "🍽️ 미슐랭 스타 셰프가 선보이는 파인 다이닝",
        "💆 전통 한국식 스파 & 웰니스 프로그램",
        "🏖️ 프라이빗 비치 & 인피니티 풀",
        "🎯 맞춤형 컨시어지 서비스"
    ],
    "map_embed_url": "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3329.123!2d126.456!3d33.123!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zMzPCsDA3JzIyLjAiTiAxMjbCsDI3JzIxLjYiRQ!5e0!3m2!1sen!2skr!4v1234567890",
    "room_types": [
        {
            "id": "room-1",
            "name": "디럭스 오션 룸",
            "name_en": "Deluxe Ocean Room",
            "description": "넓은 창으로 펼쳐지는 탁 트인 바다 전망과 모던한 인테리어가 조화를 이루는 객실입니다.",
            "size": "42㎡",
            "max_guests": 2,
            "price_glil": 350000,
            "amenities": [
                "킹사이즈 베드",
                "오션뷰 발코니",
                "대리석 욕실",
                "레인 샤워 & 욕조",
                "무료 미니바",
                "Nespresso 커피머신",
                "55인치 스마트 TV"
            ],
            "images": [
                "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=800",
                "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800"
            ]
        },
        {
            "id": "room-2",
            "name": "아주르 가든 스위트",
            "name_en": "Azure Garden Suite",
            "description": "프라이빗 가든과 야외 테라스가 있는 넓은 스위트룸으로, 편안한 휴식을 원하시는 분들께 완벽한 선택입니다.",
            "size": "68㎡",
            "max_guests": 3,
            "price_glil": 550000,
            "amenities": [
                "킹사이즈 베드",
                "프라이빗 가든",
                "야외 테라스",
                "분리형 거실",
                "대형 욕조",
                "워크인 샤워",
                "무료 미니바",
                "65인치 스마트 TV"
            ],
            "images": [
                "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=800",
                "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800"
            ]
        },
        {
            "id": "room-3",
            "name": "아주르 패밀리 스위트",
            "name_en": "Azure Family Suite",
            "description": "가족 단위 투숙객을 위한 넓은 공간과 2개의 독립된 침실을 갖춘 스위트룸입니다.",
            "size": "85㎡",
            "max_guests": 4,
            "price_glil": 750000,
            "amenities": [
                "킹사이즈 베드 + 트윈 베드",
                "2개의 독립 침실",
                "거실 & 식사 공간",
                "2개의 욕실",
                "키즈 어메니티",
                "발코니",
                "무료 미니바",
                "75인치 스마트 TV"
            ],
            "images": [
                "https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=800",
                "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=800"
            ]
        },
        {
            "id": "room-4",
            "name": "로열 클리프 빌라",
            "name_en": "Royal Cliff Villa",
            "description": "절벽 위에 자리한 프라이빗 빌라로, 전용 수영장과 개인 집사 서비스가 제공됩니다.",
            "size": "120㎡",
            "max_guests": 4,
            "price_glil": 1200000,
            "amenities": [
                "킹사이즈 베드 2개",
                "프라이빗 인피니티 풀",
                "개인 집사 서비스",
                "야외 자쿠지",
                "전용 바비큐 시설",
                "프라이빗 가든",
                "고급 욕실 어메니티",
                "85인치 스마트 TV"
            ],
            "images": [
                "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800",
                "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800"
            ]
        },
        {
            "id": "room-5",
            "name": "프레지덴셜 오버워터 빌라",
            "name_en": "Presidential Overwater Villa",
            "description": "바다 위에 떠 있는 듯한 최고급 빌라로, 360도 오션뷰와 최상의 프라이버시를 제공합니다.",
            "size": "180㎡",
            "max_guests": 6,
            "price_glil": 2500000,
            "amenities": [
                "마스터 침실 2개",
                "전용 수영장 & 선덱",
                "24시간 개인 집사",
                "프라이빗 스파 룸",
                "와인 셀러",
                "야외 다이닝 공간",
                "럭셔리 욕실 2개",
                "홈 시어터 시스템"
            ],
            "images": [
                "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800",
                "https://images.unsplash.com/photo-1573052905904-34ad8c27f0cc?w=800"
            ]
        }
    ],
    "reviews": [
        {
            "id": "review-1",
            "user_name": "김지훈",
            "rating": 5,
            "date": "2024-02-15",
            "comment": "완벽한 휴가였습니다. 오션뷰가 정말 환상적이고 직원분들의 서비스도 최고였어요.",
            "verified": True
        },
        {
            "id": "review-2",
            "user_name": "이서연",
            "rating": 5,
            "date": "2024-02-10",
            "comment": "가족과 함께 묵었는데 아이들도 너무 좋아했습니다. 특히 키즈 클럽이 인상적이었어요.",
            "verified": True
        },
        {
            "id": "review-3",
            "user_name": "박민수",
            "rating": 5,
            "date": "2024-02-05",
            "comment": "신혼여행으로 다녀왔는데 평생 잊지 못할 추억이 되었습니다. 스파도 정말 좋았어요!",
            "verified": True
        },
        {
            "id": "review-4",
            "user_name": "최유진",
            "rating": 4,
            "date": "2024-01-28",
            "comment": "시설과 서비스 모두 훌륭했습니다. 다만 성수기라 사람이 많아서 조금 아쉬웠어요.",
            "verified": True
        }
    ],
    "average_rating": 4.8,
    "total_reviews": 1247
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

    # 리조트 상품 생성
    try:
        resort = ShoppingProduct.objects.create(
            category=category,
            product_type=product_type,
            name="GLI 그랜드 아주르 리조트 & 스파",
            name_en="GLI Grand Azure Resort & Spa",
            description="제주의 아름다운 해안선을 따라 자리한 5성급 럭셔리 리조트입니다. 최상의 서비스와 현대적인 시설, 그리고 자연과 조화를 이루는 공간에서 잊지 못할 추억을 만들어보세요.",
            description_en="A 5-star luxury resort located along Jeju's beautiful coastline. Create unforgettable memories with world-class service, modern facilities, and spaces that harmonize with nature.",
            short_description="제주 중문의 5성급 럭셔리 오션뷰 리조트",
            price_glil=350000,  # 최저가 (디럭스 오션 룸)
            stock_quantity=50,
            unlimited_stock=True,
            status='active',
            is_featured=True,
            main_image_url="https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1200",
            image_urls=[
                "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1200",
                "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200",
                "https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200",
                "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1200",
                "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=1200",
                "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=1200"
            ],
            attributes={
                "resort_data": resort_data
            }
        )

        print(f"✅ 리조트 샘플 데이터가 생성되었습니다!")
        print(f"   ID: {resort.id}")
        print(f"   이름: {resort.name}")
        print(f"   카테고리: {category.name}")
        print(f"   상품 유형: {product_type.name}")
        print(f"   가격: {resort.price_glil:,.0f} GLI-L")
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
    print("=" * 60)
    create_resort_sample()
