#!/bin/bash

# XRPL EVM 최신 스냅샷 크롤러
# Polkachu 웹사이트에서 XRPL EVM 테스트넷의 최신 스냅샷 파일 이름을 크롤링합니다.
# 필요한 패키지: curl, grep, sed

# 설정
SNAPSHOT_URL="https://www.polkachu.com/testnets/xrp/snapshots"
LOG_FILE="snapshot_monitor.log"
LAST_SNAPSHOT_FILE="last_snapshot.txt"

# 로그 함수
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 디렉토리 생성
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

log_message "XRPL EVM 스냅샷 크롤러 시작"

# 웹페이지 가져오기
log_message "웹페이지 가져오는 중: $SNAPSHOT_URL"
webpage_content=$(curl -s "$SNAPSHOT_URL")

if [ -z "$webpage_content" ]; then
    log_message "오류: 웹페이지를 가져올 수 없습니다."
    exit 1
fi

# 최신 스냅샷 파일 이름 추출 (wget 명령어에서)
snapshot_filename=$(echo "$webpage_content" | grep -o 'wget -O xrp_[0-9]*\.tar\.lz4' | sed 's/wget -O //')

# 스냅샷 파일 이름이 발견되지 않은 경우
if [ -z "$snapshot_filename" ]; then
    log_message "오류: 스냅샷 파일 이름을 찾을 수 없습니다."
    exit 1
fi

# 스냅샷 URL 생성
snapshot_url="https://snapshots.polkachu.com/testnet-snapshots/xrp/$snapshot_filename"

log_message "찾은 최신 스냅샷 파일: $snapshot_filename"
log_message "다운로드 URL: $snapshot_url"

# 선택적: 스냅샷 자동 다운로드 (주석 처리되어 있음)
log_message "스냅샷 다운로드 시작..."
wget -O "$snapshot_filename" "$snapshot_url"
log_message "스냅샷 다운로드 완료: $snapshot_filename"

log_message "크롤러 작업 완료"
exit 0