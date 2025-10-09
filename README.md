# GLI Root Repository

이 저장소는 GLI 프로젝트의 루트 디렉토리로, 여러 하위 레포지토리들의 공통된 스크립트 및 설정 파일들을 포함합니다.

## 포함된 스크립트

- `init_repos.sh` : 모든 리포지토리를 GitHub에 생성하고 초기화
- `sync_repos.sh` : 루트만 clone했을 때 하위 레포 자동 clone
- `git-multi-pull.sh` : 모든 하위 레포 최신 pull
- `git-multi-push.sh` : 모든 하위 레포 푸시

## 하위 레포 목록

- `gli_database`
- `gli_redis`
- `gli_rabbitmq`
- `gli_websocket`
- `gli_api-server`
- `gli_user-frontend`
- `gli_admin-frontend`
