# Claude Code Instructions

## 언어 설정 (Language Configuration)
**항상 한국어로 응답하세요. Always respond in Korean.**
- 모든 설명, 답변, 코드 주석은 한국어로 작성
- 기술 용어는 필요시 영어 병기 가능 (예: "컴포넌트(Component)")
- 코드 자체는 영어로 작성하되, 주석과 설명은 한국어로 작성

## 🚨 중요: GLI 서비스 관리 규칙 (CRITICAL: GLI Service Management Rules)

### **절대 준수사항 (MANDATORY RULES)**

1. **서비스 실행은 반드시 정해진 재시작 스크립트 사용**
   ```bash
   # ✅ 올바른 방법 (CORRECT)
   cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root
   ./restart-api-server.sh --bf          # Django API (포트 8000)
   ./restart-user-frontend.sh --bf       # User Frontend (포트 3000)
   ./restart-admin-frontend.sh --bf      # Admin Frontend (포트 3001)

   # ❌ 잘못된 방법 (INCORRECT) - 절대 사용 금지
   npm run dev                           # 포트가 임의로 변경됨
   python manage.py runserver           # 환경 변수 및 로깅 설정 누락
   ```

2. **포트 구성 (절대 변경 금지)**
   - Django API: **8000**
   - User Frontend: **3000**
   - Admin Frontend: **3001**
   - PostgreSQL: **5433**
   - Redis: **6379**
   - WebSocket: **8080**

3. **작업 전 필수 확인사항**
   - 서비스 실행 전 `LOCAL_SERVICES_GUIDE.md` 참조 필수
   - 포트 충돌 시 기존 프로세스 종료: `pkill -9 -f gli_`
   - 환경 변수 자동 로드 확인 (재시작 스크립트에 포함)

4. **서비스 상태 확인**
   ```bash
   # Health Check
   curl http://localhost:8000/api/common/health/

   # 프로세스 확인
   pgrep -f gli_ | wc -l

   # 포트 확인
   lsof -i :8000 -i :3000 -i :3001
   ```

### **왜 이런 규칙이 필요한가?**
- 재시작 스크립트는 환경 변수, 로깅, PID 관리를 자동 처리
- 임의 실행 시 포트 충돌 및 설정 누락으로 디버깅 시간 낭비
- 팀 개발 환경의 일관성 유지

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
