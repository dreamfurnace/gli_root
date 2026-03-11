#!/usr/bin/env python3
"""
스테이징 환경 리조트 객실 타입 이미지 추가 스크립트
"""
import os
import psycopg2
from psycopg2.extras import Json, RealDictCursor
import json

# 스테이징 DB 연결 정보
DB_CONFIG = {
    'host': 'gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com',
    'database': 'gli_staging',
    'user': 'glidbadmin',
    'password': os.getenv('STAGING_DB_PASSWORD', ''),  # 환경 변수에서 가져오기
    'port': 5432
}

RESORT_ID = '36d0db85-dc1c-436c-b307-07bafb3b714c'

def main():
    if not DB_CONFIG['password']:
        print("❌ STAGING_DB_PASSWORD 환경 변수가 설정되지 않았습니다.")
        print("   export STAGING_DB_PASSWORD='your_password'")
        return

    try:
        # 데이터베이스 연결
        print(f"📡 스테이징 DB 연결 중: {DB_CONFIG['host']}")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        # 상품 조회
        cursor.execute("""
            SELECT id, name, product_type, main_image_url, image_urls, attributes
            FROM gli_content_shoppingproduct
            WHERE id = %s
        """, (RESORT_ID,))

        product = cursor.fetchone()

        if not product:
            print(f"✗ ID {RESORT_ID}에 해당하는 상품을 찾을 수 없습니다.")
            return

        print(f"✓ 찾은 상품: {product['name']}")
        print(f"  타입: {product['product_type']}")

        # 사용 가능한 이미지 목록
        available_images = product.get('image_urls', [product['main_image_url']])
        print(f"  사용 가능한 이미지: {len(available_images)}개")

        # attributes 파싱
        attributes = product['attributes'] if isinstance(product['attributes'], dict) else json.loads(product['attributes'])

        # room_types 찾기
        if 'room_types' in attributes:
            room_types = attributes['room_types']
        elif 'resort_data' in attributes and 'room_types' in attributes['resort_data']:
            room_types = attributes['resort_data']['room_types']
        else:
            print("✗ 객실 타입을 찾을 수 없습니다.")
            return

        print(f"\n객실 타입: {len(room_types)}개")

        # 이미지 추가
        updated = False
        for idx, room in enumerate(room_types):
            has_image = room.get('image_url') or room.get('image')
            print(f"  [{idx}] {room.get('name')}: 이미지 = {'✓' if has_image else '✗'}")

            if not has_image:
                img_idx = idx % len(available_images)
                selected_image = available_images[img_idx]
                room['image_url'] = selected_image
                print(f"      → 이미지 추가: {selected_image}")
                updated = True

        if updated:
            # 업데이트
            cursor.execute("""
                UPDATE gli_content_shoppingproduct
                SET attributes = %s, updated_at = NOW()
                WHERE id = %s
            """, (Json(attributes), RESORT_ID))

            conn.commit()
            print(f"\n✅ 스테이징 DB 업데이트 완료!")
        else:
            print(f"\n✓ 모든 객실에 이미지가 이미 있습니다.")

        cursor.close()
        conn.close()

    except psycopg2.Error as e:
        print(f"❌ 데이터베이스 오류: {e}")
    except Exception as e:
        print(f"❌ 오류 발생: {e}")

if __name__ == '__main__':
    main()
