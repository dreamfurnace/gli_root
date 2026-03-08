#!/usr/bin/env python
"""
3개의 테스트 회원 계정 생성 및 GLIB 토큰 할당 스크립트

회원 정보:
1. 오용성 (youngseong0204) : 340,220 GLIB, PW: 640204
2. 이형희 (leehyunghee0801) : 136,000 GLIB, PW: 690801
3. 김경아 (keyungah0109) : 476,000 GLIB, PW: 700109
"""

import os
import sys
import django
from decimal import Decimal

# Django 설정 초기화
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'gli_api-server'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.solana_auth.models import SolanaUser
from apps.common.models import UserTokenBalance

# 회원 정보 정의
TEST_USERS = [
    {
        'username': 'youngseong0204',
        'password': '640204!@#$',
        'email': 'youngseong0204@glibiz.com',
        'first_name': '용성',
        'last_name': '오',
        'glib_balance': Decimal('340220.00000000'),
    },
    {
        'username': 'leehyunghee0801',
        'password': '690801!@#$',
        'email': 'leehyunghee0801@glibiz.com',
        'first_name': '형희',
        'last_name': '이',
        'glib_balance': Decimal('136000.00000000'),
    },
    {
        'username': 'keyungah0109',
        'password': '700109!@#$',
        'email': 'keyungah0109@glibiz.com',
        'first_name': '경아',
        'last_name': '김',
        'glib_balance': Decimal('476000.00000000'),
    },
]


def create_test_users():
    """테스트 회원 생성 및 GLIB 토큰 할당"""

    print("=" * 80)
    print("GLI 테스트 회원 생성 스크립트")
    print("=" * 80)
    print()

    created_count = 0
    updated_count = 0

    for user_data in TEST_USERS:
        username = user_data['username']
        glib_balance = user_data['glib_balance']

        try:
            # 기존 사용자 확인
            user, created = SolanaUser.objects.get_or_create(
                username=username,
                defaults={
                    'email': user_data['email'],
                    'first_name': user_data['first_name'],
                    'last_name': user_data['last_name'],
                    'is_active': True,
                    'membership_level': 'premium',
                    'membership_tier': 'PREMIUM',
                }
            )

            if created:
                # 비밀번호 설정 (해시화)
                user.set_password(user_data['password'])
                user.save()
                print(f"✅ 새 회원 생성: {username}")
                created_count += 1
            else:
                # 기존 회원의 비밀번호 업데이트
                user.set_password(user_data['password'])
                user.save()
                print(f"ℹ️  기존 회원 발견: {username} (비밀번호 업데이트)")
                updated_count += 1

            # GLIB 토큰 잔액 생성 또는 업데이트
            token_balance, balance_created = UserTokenBalance.objects.get_or_create(
                user=user,
                defaults={
                    'glib_balance': glib_balance,
                    'glil_balance': Decimal('0.00000000'),
                }
            )

            if not balance_created:
                # 기존 잔액이 있으면 업데이트
                token_balance.glib_balance = glib_balance
                token_balance.save()
                print(f"   💰 GLIB 토큰 업데이트: {glib_balance:,.8f} GLIB")
            else:
                print(f"   💰 GLIB 토큰 할당: {glib_balance:,.8f} GLIB")

            print(f"   📧 이메일: {user.email}")
            print(f"   🔑 비밀번호: {user_data['password']}")
            print()

        except Exception as e:
            print(f"❌ 오류 발생 ({username}): {str(e)}")
            print()
            continue

    print("=" * 80)
    print(f"완료: 신규 생성 {created_count}명, 업데이트 {updated_count}명")
    print("=" * 80)
    print()

    # 생성된 회원 목록 확인
    print("📋 생성된 회원 목록:")
    print("-" * 80)
    for user_data in TEST_USERS:
        username = user_data['username']
        try:
            user = SolanaUser.objects.get(username=username)
            token_balance = UserTokenBalance.objects.get(user=user)

            print(f"👤 {user.last_name}{user.first_name} ({username})")
            print(f"   💰 GLIB: {token_balance.glib_balance:,.8f}")
            print(f"   💎 GLIL: {token_balance.glil_balance:,.8f}")
            print(f"   📧 이메일: {user.email}")
            print(f"   🎫 등급: {user.membership_tier}")
            print(f"   ✅ 활성화: {user.is_active}")
            print()
        except SolanaUser.DoesNotExist:
            print(f"❌ {username} - 회원을 찾을 수 없습니다.")
        except UserTokenBalance.DoesNotExist:
            print(f"❌ {username} - 토큰 잔액 정보가 없습니다.")

    print("=" * 80)
    print("✨ 모든 작업이 완료되었습니다!")
    print("🌐 로컬: http://localhost:3000/login")
    print("🌐 스테이징: https://stg.glibiz.com/login")
    print("=" * 80)


if __name__ == '__main__':
    create_test_users()
