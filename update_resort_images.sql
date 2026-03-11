-- 아주르 리조트 객실 타입 이미지 업데이트
UPDATE gli_content_shoppingproduct
SET attributes = jsonb_set(
    attributes,
    '{resort_data,room_types}',
    (
        SELECT jsonb_agg(
            CASE
                WHEN room->>'name' = '아주르 가든 스위트' THEN
                    jsonb_set(room, '{image_url}', '"https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200"')
                WHEN room->>'name' = '아주르 패밀리 스위트' THEN
                    jsonb_set(room, '{image_url}', '"https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=1200"')
                WHEN room->>'name' = '로열 클리프 빌라' THEN
                    jsonb_set(room, '{image_url}', '"https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=1200"')
                WHEN room->>'name' = '프레지덴셜 오버워터 빌라' THEN
                    jsonb_set(room, '{image_url}', '"https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=1200"')
                ELSE room
            END
        )
        FROM jsonb_array_elements(attributes->'resort_data'->'room_types') AS room
    )
),
updated_at = NOW()
WHERE id = '36d0db85-dc1c-436c-b307-07bafb3b714c';
