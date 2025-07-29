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

  # 1. GitHub에 리포 생성
  if ! gh repo view "$GITHUB_ORG/$NAME" &>/dev/null; then
    echo "📦 GitHub에 레포 생성: $GITHUB_ORG/$NAME"
    gh repo create "$GITHUB_ORG/$NAME" --public --source="$DIR" --remote=origin --push -y || echo "⚠️ GitHub 생성 실패 또는 이미 존재"
  else
    echo "✅ GitHub에 이미 존재: $NAME"
  fi

  # 2. Git 초기화 및 푸시
  cd "$DIR"
  if [ ! -d ".git" ]; then
    git init
    git remote add origin git@github.com:$GITHUB_ORG/$NAME.git
  fi

  touch README.md
  git add .
  git commit -m "init" || echo "📝 커밋할 변경사항 없음"
  git branch -M main
  git push -u origin main
  cd - > /dev/null

  echo "✅ 완료: $NAME"
done

echo "🎉 루트 + 모든 GLI 하위 레포지토리 GitHub에 생성 및 초기 푸시 완료!"
