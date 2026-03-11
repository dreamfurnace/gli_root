#!/usr/bin/env python3
"""
스테이징 DB 패키지 상품 확인 스크립트
"""
import os
import sys

# Django 설정 전에 경로 추가
sys.path.insert(0, '/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# 스테이징 DB 연결 설정
os.environ['DATABASE_HOST'] = 'gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com'
os.environ['DATABASE_USER'] = 'glidbadmin'
os.environ['DATABASE_PASSWORD'] = 'P7xhVZTxrDLySRwzsir8LG7T'
os.environ['DATABASE_NAME'] = 'gli'
os.environ['DATABASE_PORT'] = '5432'

import django
django.setup()

from apps.gli_content.models import ShoppingCategory, ShoppingProductType, ShoppingProduct

print("🔍 스테이징 DB 패키지 상품 확인 중...\n")

# 패키지 카테고리 확인
try:
    package_cat = ShoppingCategory.objects.get(name='패키지')
    print(f"✅ 패키지 카테고리: {package_cat.id} - {package_cat.name}")
except ShoppingCategory.DoesNotExist:
    print("❌ 패키지 카테고리가 존재하지 않습니다.")
    sys.exit(1)

# 패키지 상품 유형 확인
try:
    package_type = ShoppingProductType.objects.get(code='package', category=package_cat)
    print(f"✅ 패키지 상품 유형: {package_type.id} - {package_type.name}")
except ShoppingProductType.DoesNotExist:
    print("❌ 패키지 상품 유형이 존재하지 않습니다.")
    sys.exit(1)

# 패키지 상품 조회
packages = ShoppingProduct.objects.filter(
    category=package_cat,
    product_type=package_type
)

print(f"\n📦 등록된 패키지 상품 수: {packages.count()}개\n")

if packages.count() == 0:
    print("❌ 등록된 패키지 상품이 없습니다!")
    print("\n🔧 해결 방법:")
    print("   create_package_product_staging.py 스크립트를 실행하여 패키지 상품을 생성하세요.")
else:
    for pkg in packages:
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"📦 ID: {pkg.id}")
        print(f"📝 이름: {pkg.name}")
        print(f"📝 영문명: {pkg.name_en}")
        print(f"🔖 상태: {pkg.status}")
        print(f"💰 가격: {pkg.price_glil:,} GLI-L / ${pkg.price_usd}")
        print(f"⭐ Featured: {pkg.is_featured}")
        print(f"📅 생성일: {pkg.created_at}")
        print(f"📂 카테고리: {pkg.category.name} ({pkg.category_id})")
        print(f"🏷️  상품 유형: {pkg.product_type.name} ({pkg.product_type_id})")
        print(f"🖼️  메인 이미지: {pkg.main_image_url[:60]}...")
        print(f"📸 이미지 수: {len(pkg.image_urls) if pkg.image_urls else 0}개")
        print(f"🏷️  태그: {', '.join(pkg.tags) if pkg.tags else '없음'}")

        if pkg.attributes and 'package_data' in pkg.attributes:
            pd = pkg.attributes['package_data']
            print(f"📋 부제: {pd.get('subtitle', 'N/A')}")
            print(f"🎯 핵심 특징: {len(pd.get('core_features', []))}개")
            print(f"📅 일정: {len(pd.get('itinerary', []))}일")

        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

print("\n✅ 확인 완료!")
