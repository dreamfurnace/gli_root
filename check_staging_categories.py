#!/usr/bin/env python3
"""
스테이징 환경의 카테고리 및 상품 유형 확인 스크립트
"""

import os
import sys
import django

# Django 설정 (staging 환경)
sys.path.append('/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
os.environ.setdefault('DJANGO_ENV', 'staging')
django.setup()

from apps.gli_content.models import ShoppingCategory, ShoppingProductType

print("=" * 60)
print("스테이징 환경 카테고리 및 상품 유형 확인")
print("=" * 60)

print("\n📋 카테고리 목록:")
categories = ShoppingCategory.objects.all().order_by('order')
for cat in categories:
    print(f"  {cat.icon} {cat.name} (ID: {cat.id})")

print("\n📦 상품 유형 목록:")
product_types = ShoppingProductType.objects.all().select_related('category').order_by('category__order', 'order')
for pt in product_types:
    print(f"  [{pt.category.name}] {pt.name} (ID: {pt.id}, Code: {pt.code})")
