#!/usr/bin/env python3
"""
Django shell을 통한 리조트 데이터 업데이트
참고 파일(GLI 객실 정보 v1.1.html)과 완전히 동일한 데이터로 업데이트
"""

from apps.gli_content.models import ShoppingProduct

# 참고 파일의 정확한 데이터
resort_data = {
    "location": "몰디브, 아리 아톨 프라이빗 아일랜드",
    "rating": 5,
    "brand_story": "2018년 첫 문을 연 그랜드 아주르 리조트는, 아라비아해의 깊고 푸른 물결과 하얀 모래사장이 빚어내는 자연의 걸작 속에 자리합니다. '아주르(Azure)'라는 이름처럼 끝없이 펼쳐지는 에메랄드빛 바다와 하늘, 그리고 그 사이에서 온전한 휴식을 선사하는 프라이빗 아일랜드 리조트입니다.",
    "check_in": "오후 14:00",
    "check_out": "오전 12:00",
    "facilities": [
        {"icon": "user-check", "name": "24시간 퍼스널 버틀러"},
        {"icon": "wifi", "name": "무료 와이파이"},
        {"icon": "dumbbell", "name": "피트니스 센터"},
        {"icon": "waves", "name": "인피니티 풀 & 스파"},
        {"icon": "utensils", "name": "올 데이 다이닝"},
        {"icon": "sparkles", "name": "매일 객실 청소"},
        {"icon": "car", "name": "공항 픽업 서비스"},
        {"icon": "briefcase", "name": "비즈니스 라운지"}
    ],
    "highlights": [
        {
            "icon": "award",
            "title": "독보적인 위치",
            "description": "아리 아톨의 가장 아름다운 산호초 군락지가 펼쳐지는 프라이빗 아일랜드. 세계적인 다이빙 스팟과 해양 생태계를 바로 앞에서 만나보세요."
        },
        {
            "icon": "utensils",
            "title": "미쉐린 스타 다이닝",
            "description": "세계적인 셰프들이 선보이는 파인 다이닝부터 프라이빗 비치 디너까지, 당신만을 위한 특별한 미식 경험을 제공합니다."
        },
        {
            "icon": "shield-check",
            "title": "프라이빗 케어",
            "description": "모든 투숙객에게 24시간 전담 버틀러가 배정되어, 당신의 모든 순간을 세심하게 케어합니다."
        }
    ],
    "room_types": [
        {
            "id": "deluxe",
            "name": "디럭스 오션 룸",
            "name_en": "Deluxe Ocean Room",
            "description": "끝없이 펼쳐지는 에메랄드빛 바다 전망과 모던한 인테리어가 조화를 이루는 프리미엄 객실입니다. 넓은 테라스에서 인도양의 석양을 감상하며 특별한 휴식을 만끽하세요.",
            "size": "45㎡",
            "max_guests": {"adult": 2, "child": 1},
            "price_glil": 450000,
            "features": [
                "킹 사이즈 침대",
                "오션뷰 테라스",
                "대리석 마감 욕실"
            ],
            "amenities": {
                "bedding": [
                    "400수 이집트산 면 시트",
                    "럭셔리 베개 4종 (메모리폼, 다운, 라텍스 포함)",
                    "프리미엄 듀벳 & 블랭킷"
                ],
                "tech": [
                    "65인치 OLED 스마트 TV",
                    "보스(Bose) 사운드 시스템",
                    "무선 충전 패드",
                    "태블릿 컨트롤 객실 시스템"
                ],
                "beverage": [
                    "네스프레소 머신 & 캡슐",
                    "티 셀렉션 (TWG)",
                    "매일 리필되는 미니바"
                ],
                "bathroom": [
                    "바이레도(Byredo) 어메니티",
                    "레인 샤워 & 독립 욕조",
                    "헤어드라이어(다이슨)",
                    "욕실 전용 TV",
                    "프리미엄 목욕 가운 & 슬리퍼"
                ],
                "security": [
                    "디지털 안전 금고",
                    "현관 카메라 시스템"
                ]
            },
            "images": [
                "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=1200",
                "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1200"
            ]
        },
        {
            "id": "suite",
            "name": "아주르 가든 스위트",
            "name_en": "Azure Garden Suite",
            "description": "프라이빗 정원과 야외 다이닝 공간이 있는 넓은 스위트룸. 자연과 하나 되는 럭셔리한 공간에서 진정한 휴식을 경험하세요.",
            "size": "72㎡",
            "max_guests": {"adult": 2, "child": 2},
            "price_glil": 780000,
            "features": [
                "킹 사이즈 침대",
                "프라이빗 가든",
                "야외 다이닝 공간",
                "분리형 거실"
            ],
            "amenities": {
                "bedding": [
                    "400수 이집트산 면 시트",
                    "럭셔리 베개 6종",
                    "프리미엄 듀벳 & 블랭킷"
                ],
                "tech": [
                    "75인치 OLED 스마트 TV",
                    "방 & 거실 보스 사운드 시스템",
                    "무선 충전 패드 2개",
                    "태블릿 컨트롤 객실 시스템"
                ],
                "beverage": [
                    "네스프레소 머신 & 프리미엄 캡슐",
                    "티 셀렉션 (TWG)",
                    "매일 리필되는 프리미엄 미니바",
                    "와인 쿨러"
                ],
                "bathroom": [
                    "디올(Dior) 어메니티",
                    "레인 샤워 & 대형 욕조",
                    "헤어드라이어(다이슨)",
                    "욕실 전용 TV",
                    "프리미엄 목욕 가운 & 슬리퍼",
                    "더블 세면대"
                ],
                "security": [
                    "대형 디지털 안전 금고",
                    "현관 카메라 시스템"
                ]
            },
            "images": [
                "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=1200",
                "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200"
            ]
        },
        {
            "id": "family",
            "name": "아주르 패밀리 스위트",
            "name_en": "Azure Family Suite",
            "description": "가족 단위 투숙객을 위한 넓은 공간과 2개의 독립된 침실을 갖춘 스위트룸. 온 가족이 함께하는 특별한 추억을 만들어보세요.",
            "size": "95㎡",
            "max_guests": {"adult": 4, "child": 2},
            "price_glil": 950000,
            "features": [
                "킹 사이즈 침대 + 트윈 베드",
                "2개의 독립 침실",
                "거실 & 다이닝 공간",
                "2개의 욕실"
            ],
            "amenities": {
                "bedding": [
                    "400수 이집트산 면 시트",
                    "성인/아동 맞춤 베개 세트",
                    "프리미엄 듀벳 & 블랭킷"
                ],
                "tech": [
                    "75인치 OLED 스마트 TV 2대",
                    "보스 사운드 시스템",
                    "무선 충전 패드 2개",
                    "태블릿 컨트롤 2개",
                    "키즈 태블릿 & 게임"
                ],
                "beverage": [
                    "네스프레소 머신 & 프리미엄 캡슐",
                    "티 셀렉션 (TWG)",
                    "대형 미니바",
                    "키즈 스낵 & 음료"
                ],
                "bathroom": [
                    "에르메스(Hermès) 어메니티",
                    "레인 샤워 & 욕조 2개",
                    "헤어드라이어 2개",
                    "욕실 전용 TV",
                    "목욕 가운 & 슬리퍼 (성인/아동)",
                    "더블 세면대 2세트"
                ],
                "security": [
                    "대형 안전 금고",
                    "현관 카메라 시스템",
                    "키즈 안전 잠금장치"
                ]
            },
            "images": [
                "https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200",
                "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=1200"
            ]
        },
        {
            "id": "villa",
            "name": "로열 클리프 빌라",
            "name_en": "Royal Cliff Villa",
            "description": "절벽 위에 자리한 프라이빗 빌라로, 전용 인피니티 풀과 개인 집사 서비스가 제공됩니다. 완벽한 프라이버시 속에서 최상급 휴식을 누리세요.",
            "size": "135㎡",
            "max_guests": {"adult": 4, "child": 2},
            "price_glil": 1350000,
            "features": [
                "킹 사이즈 침대 2개",
                "프라이빗 인피니티 풀",
                "개인 집사 서비스",
                "야외 자쿠지"
            ],
            "amenities": {
                "bedding": [
                    "600수 이탈리아산 면 시트",
                    "럭셔리 베개 8종",
                    "프리미엄 듀벳 & 캐시미어 블랭킷"
                ],
                "tech": [
                    "85인치 OLED 스마트 TV 2대",
                    "뱅앤올룹슨 사운드 시스템",
                    "무선 충전 패드 4개",
                    "아이패드 프로 컨트롤 2개",
                    "홈 시어터 시스템"
                ],
                "beverage": [
                    "라마르조코 에스프레소 머신",
                    "프리미엄 티 & 커피 컬렉션",
                    "풀 스톡 미니바 & 와인 셀러",
                    "샴페인 쿨러"
                ],
                "bathroom": [
                    "라 메르(La Mer) 어메니티",
                    "레인폴 샤워 & 대형 욕조 2개",
                    "헤어드라이어(다이슨) 2개",
                    "욕실 TV 2대",
                    "프리미엄 목욕 가운 & 에르메스 슬리퍼",
                    "더블 세면대 2세트"
                ],
                "security": [
                    "대형 안전 금고",
                    "현관 카메라 시스템",
                    "24시간 보안 서비스"
                ]
            },
            "images": [
                "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200",
                "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1200"
            ]
        },
        {
            "id": "presidential",
            "name": "프레지덴셜 오버워터 빌라",
            "name_en": "Presidential Overwater Villa",
            "description": "바다 위에 떠 있는 듯한 최고급 빌라로, 360도 오션뷰와 최상의 프라이버시를 제공합니다. 전용 수영장, 스파 룸, 와인 셀러까지 갖춘 궁극의 럭셔리를 경험하세요.",
            "size": "200㎡",
            "max_guests": {"adult": 6, "child": 2},
            "price_glil": 2100000,
            "features": [
                "마스터 침실 2개",
                "전용 수영장 & 선덱",
                "24시간 개인 집사",
                "프라이빗 스파 룸"
            ],
            "amenities": {
                "bedding": [
                    "800수 이집트산 면 시트 (Frette)",
                    "템퍼페딕 매트리스",
                    "다운 & 실크 베개 컬렉션",
                    "캐시미어 & 실크 듀벳"
                ],
                "tech": [
                    "98인치 OLED 스마트 TV",
                    "뱅앤올룹슨 프리미엄 사운드 시스템",
                    "무선 충전 패드 6개",
                    "아이패드 프로 컨트롤 3개",
                    "홈 시어터 & 게임룸",
                    "수중 음향 시스템"
                ],
                "beverage": [
                    "라마르조코 에스프레소 머신",
                    "프리미엄 티 & 커피 컬렉션",
                    "풀 스톡 프리미엄 바 & 대형 와인 셀러",
                    "샴페인 & 와인 큐레이션 서비스"
                ],
                "bathroom": [
                    "라 프레리(La Prairie) 어메니티",
                    "레인폴 샤워 & 대형 욕조 3개",
                    "헤어드라이어(다이슨) 3개",
                    "욕실 TV 3대",
                    "프리미엄 목욕 가운 & 에르메스 슬리퍼",
                    "더블 세면대 3세트",
                    "프라이빗 스파 욕조"
                ],
                "security": [
                    "대형 안전 금고 2개",
                    "현관 카메라 시스템",
                    "24시간 전담 보안 요원"
                ]
            },
            "images": [
                "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=1200",
                "https://images.unsplash.com/photo-1573052905904-34ad8c27f0cc?w=1200"
            ]
        }
    ],
    "reviews": [
        {
            "id": "review-1",
            "user_name": "김*훈",
            "room_type": "디럭스 오션 룸",
            "rating": 5,
            "date": "2024.01.15",
            "comment": "꿈만 같았던 신혼여행이었습니다. 방에서 바로 보이는 바다 전망이 정말 환상적이었고, 버틀러 서비스도 완벽했어요. 매 순간이 특별했습니다.",
            "verified": True
        },
        {
            "id": "review-2",
            "user_name": "이*서",
            "room_type": "아주르 패밀리 스위트",
            "rating": 5,
            "date": "2024.01.10",
            "comment": "가족 여행으로 정말 완벽했어요. 아이들을 위한 배려도 세심했고, 객실도 넓고 쾌적했습니다. 특히 키즈 어메니티가 인상적이었어요.",
            "verified": True
        },
        {
            "id": "review-3",
            "user_name": "박*수",
            "room_type": "로열 클리프 빌라",
            "rating": 5,
            "date": "2024.01.05",
            "comment": "프라이빗 풀과 전용 집사 서비스가 정말 최고였습니다. 완벽한 프라이버시 속에서 진정한 휴식을 취할 수 있었어요. 평생 잊지 못할 경험입니다.",
            "verified": True
        },
        {
            "id": "review-4",
            "user_name": "최*진",
            "room_type": "아주르 가든 스위트",
            "rating": 5,
            "date": "2023.12.28",
            "comment": "프라이빗 가든이 있는 스위트룸이 정말 좋았습니다. 야외 공간에서의 식사도 로맨틱했고, 모든 시설이 최상급이었어요.",
            "verified": True
        }
    ],
    "average_rating": 4.9,
    "total_reviews": 1240,
    "map_embed_url": "https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3329.123!2d72.456!3d3.123!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zM8KwMDcnMjIuMCJOIDcywrAyNycyMS42IkU!5e0!3m2!1sen!2skr!4v1234567890"
}

# 기존 리조트 찾기 및 업데이트
print("=" * 60)
print("리조트 데이터 업데이트 중...")
print("=" * 60)

try:
    resort = ShoppingProduct.objects.filter(name="GLI 그랜드 아주르 리조트 & 스파").first()

    if not resort:
        print("❌ 리조트를 찾을 수 없습니다.")
        print("   이름: GLI 그랜드 아주르 리조트 & 스파")
    else:
        print(f"✅ 리조트 발견: {resort.id}")
        print(f"   기존 위치: {resort.attributes.get('resort_data', {}).get('location', 'N/A')}")

        # 데이터 업데이트
        resort.name = "GLI 그랜드 아주르 리조트 & 스파"
        resort.name_en = "GLI Grand Azure Resort & Spa"
        resort.description = "몰디브 아리 아톨의 프라이빗 아일랜드에 위치한 최고급 럭셔리 리조트입니다. 360도 오션뷰, 전용 버틀러 서비스, 미슐랭 스타 다이닝이 어우러진 완벽한 휴식을 경험하세요."
        resort.description_en = "The ultimate luxury resort located on a private island in Ari Atoll, Maldives. Experience the perfect getaway with 360° ocean views, personal butler service, and Michelin-star dining."
        resort.short_description = "몰디브 아리 아톨 프라이빗 아일랜드 5성급 럭셔리 리조트"
        resort.price_glil = 450000  # 최저가 (디럭스 오션 룸)

        # 이미지 URLs (참고 파일의 10개 갤러리 이미지)
        resort.main_image_url = "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1200"
        resort.image_urls = [
            "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=1200",
            "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200",
            "https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200",
            "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1200",
            "https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=1200",
            "https://images.unsplash.com/photo-1590490360182-c33d57733427?w=1200",
            "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200",
            "https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=1200",
            "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=1200",
            "https://images.unsplash.com/photo-1573052905904-34ad8c27f0cc?w=1200"
        ]

        # resort_data 업데이트
        resort.attributes['resort_data'] = resort_data

        resort.save()

        print(f"\n✅ 데이터 업데이트 완료!")
        print(f"   새 위치: {resort_data['location']}")
        print(f"   객실 타입: {len(resort_data['room_types'])}개")
        print(f"   - 디럭스 오션 룸: {resort_data['room_types'][0]['price_glil']:,}원")
        print(f"   - 아주르 가든 스위트: {resort_data['room_types'][1]['price_glil']:,}원")
        print(f"   - 아주르 패밀리 스위트: {resort_data['room_types'][2]['price_glil']:,}원")
        print(f"   - 로열 클리프 빌라: {resort_data['room_types'][3]['price_glil']:,}원")
        print(f"   - 프레지덴셜 오버워터 빌라: {resort_data['room_types'][4]['price_glil']:,}원")
        print(f"   갤러리 이미지: {len(resort.image_urls)}개")
        print(f"   리뷰: {resort_data['total_reviews']}개")
        print(f"\n📱 로컬 확인: http://localhost:3000/shopping/resort/{resort.id}")

except Exception as e:
    print(f"❌ 오류 발생: {e}")
    import traceback
    traceback.print_exc()

print("=" * 60)
