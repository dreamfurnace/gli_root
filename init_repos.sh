#!/bin/bash
set -e

GITHUB_ORG="dreamfurnace"

REPOS=(
  "."                        # 루트(gli_root)
  "gli_user-frontend"
  "gli_admin-frontend"
  "gli_api-server"
  "gli_ai-core"
  "gli_database"
  "gli_docs"
  "gli_infra"
  "gli_rabbitmq"
  "gli_ws-server"
)

for repo in "${REPOS[@]}"; do
  if [ "$repo" == "." ]; then
    DIR="."  # 루트
    NAME="gli_root"
  else
    DIR="$repo"
    NAME="$repo"
  fi

  echo "✅ 작업 중: $NAME"

  # GitHub에 리포 생성
  if ! gh repo view "$GITHUB_ORG/$NAME" &>/dev/null; then
    echo "📦 GitHub에 리포 생성: $GITHUB_ORG/$NAME"
    gh repo create "$GITHUB_ORG/$NAME" --public --confirm
  else
    echo "✅ GitHub에 이미 존재: $NAME"
  fi

  # 로컬 디렉토리 없으면 clone
  if [ "$DIR" != "." ] && [ ! -d "$DIR" ]; then
    echo "📥 로컬에 없어서 클론: $DIR"
    git clone git@github.com:$GITHUB_ORG/$NAME.git "$DIR"
  fi

  cd "$DIR"
  if [ ! -d ".git" ]; then
    git init
    git remote add origin git@github.com:$GITHUB_ORG/$NAME.git
  fi

  touch README.md
  git add .
  git commit -m "init" || echo "📝 커밋할 변경사항 없음"
  git branch -M main
  git push -u origin main || echo "⚠️ push 실패: 권한 또는 GitHub 설정 확인"
  cd - > /dev/null

  echo "✅ 완료: $NAME"
done

echo "🎉 루트 포함 모든 리포 생성 및 push 완료"
