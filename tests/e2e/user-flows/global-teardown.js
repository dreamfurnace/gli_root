async function globalTeardown(config) {
  // 테스트 완료 후 정리 작업
  console.log('E2E 테스트 완료. 정리 작업을 수행합니다.')

  // 필요시 테스트 데이터 정리
  // 예: 테스트용 사용자 삭제, 업로드된 파일 정리 등

  console.log('정리 작업 완료.')
}

module.exports = globalTeardown
