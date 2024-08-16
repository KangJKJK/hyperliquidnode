#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'  # No Color

execute_and_prompt() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    eval "$command"
    echo -e "${GREEN}Done.${NC}"
}

# 1. screen 설치
execute_and_prompt "Installing screen..." "sudo apt-get install -y screen"

# 2. hlnode 사용자 생성 및 sudo 권한 부여
execute_and_prompt "Adding user hlnode..." "sudo adduser hlnode"
execute_and_prompt "Adding hlnode to sudo group..." "sudo usermod -aG sudo hlnode"

# 3. screen 세션 생성 및 hlnode 사용자로 작업 시작
execute_and_prompt "Creating and starting a screen session for hlnode..." \
    "sudo -u hlnode bash -c 'screen -S hlnode -dm bash -c \"echo 'Screen session created; running setup tasks...'; exec bash\"'"

# 4. hlnode 사용자로 전환 후 패키지 업데이트 및 업그레이드
execute_and_prompt "Updating package lists and upgrading packages..." "sudo -u hlnode bash -c 'sudo apt-get update && sudo apt-get upgrade -y'"

# 5. 파일 다운로드 및 hl-visor 설정
execute_and_prompt "Downloading initial_peers.json..." "sudo -u hlnode bash -c 'curl https://binaries.hyperliquid.xyz/Testnet/initial_peers.json > ~/initial_peers.json'"
execute_and_prompt "Creating visor.json file..." "sudo -u hlnode bash -c 'echo \"{\\\"chain\\\": \\\"Testnet\\\"}\" > ~/visor.json'"
execute_and_prompt "Downloading non_validator_config.json..." "sudo -u hlnode bash -c 'curl https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json > ~/non_validator_config.json'"
execute_and_prompt "Downloading and setting up hl-visor..." "sudo -u hlnode bash -c 'curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor'"
execute_and_prompt "Making hl-visor executable..." "sudo -u hlnode bash -c 'chmod a+x ~/hl-visor'"

# 6. hl-visor 실행
execute_and_prompt "Starting hl-visor inside the screen session..." \
    "sudo -u hlnode bash -c 'screen -S hlnode -X stuff \"~/hl-visor\\n\"'"

echo -e "${YELLOW}모든작업이 완료되었습니다.컨트롤+A+D로 스크린을 종료해주세요${NC}"
# 스크립트 작성자: kangjk