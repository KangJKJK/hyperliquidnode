#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'  # No Color

# 안내 메시지
echo -e "${YELLOW}설치 도중 문제가 발생하면 다음 명령어를 입력하고 다시 시도하세요:${NC}"
echo -e "${YELLOW}sudo rm -f /root/hlnode.sh${NC}"
echo

# 함수: 명령어 실행 및 결과 확인, 오류 발생 시 사용자에게 계속 진행할지 묻기
execute_with_prompt() {
    local message="$1"
    local command="$2"
    echo -e "${YELLOW}${message}${NC}"
    echo "Executing: $command"
    
    # 명령어 실행 및 오류 내용 캡처
    output=$(eval "$command" 2>&1)
    exit_code=$?

    # 출력 결과를 화면에 표시
    echo "$output"

    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}Error: Command failed: $command${NC}" >&2
        echo -e "${RED}Detailed Error Message:${NC}"
        echo "$output" | sed 's/^/  /'  # 상세 오류 메시지를 들여쓰기하여 출력
        echo

        # 사용자에게 계속 진행할지 묻기
        read -p "오류가 발생했습니다. 계속 진행하시겠습니까? (Y/N): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${RED}스크립트를 종료합니다.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Success: Command completed successfully.${NC}"
    fi
}

# 1. 패키지 업데이트 및 설치
execute_with_prompt "패키지 업데이트 및 필요한 패키지 설치 중..." "sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg ufw"

# 2. hlnode 사용자 생성
execute_with_prompt "hlnode 사용자를 추가합니다..." "sudo useradd -m -s /bin/bash hlnode || echo 'User hlnode already exists'"

# 3. 비밀번호 설정
echo -e "${YELLOW}hlnode 사용자의 비밀번호를 설정 중입니다. 터미널에서 비밀번호를 직접 입력해 주세요.${NC}"
echo "비밀번호 설정을 완료한 후 Enter를 눌러 계속 진행하십시오."
# 직접 비밀번호를 설정하도록 유도
sudo passwd hlnode
read -r -p "비밀번호 설정이 완료되었습니다. Enter를 눌러 계속 진행하십시오."

# hlnode를 sudo 그룹에 추가
execute_with_prompt "hlnode를 sudo 그룹에 추가합니다..." "sudo usermod -aG sudo hlnode"

# 4. hlnode 사용자로 전환 후 패키지 업데이트 및 업그레이드
echo -e "${YELLOW}패키지 목록을 업데이트하고 패키지를 업그레이드합니다...${NC}"
echo "위에서 설정한 비밀번호를 입력하세요."
sudo -u hlnode bash -c 'sudo apt-get update && sudo apt-get upgrade -y'
read -r -p "Enter를 눌러 계속 진행하십시오."

# 5. Docker 설치 및 실행
execute_with_prompt "Docker를 설치합니다..." "sudo apt-get update && sudo apt-get install -y docker.io"
execute_with_prompt "Docker 서비스를 시작하고 활성화합니다..." "sudo systemctl start docker && sudo systemctl enable docker"
docker_image="hyperliquid/hl-visor:latest"
execute_with_prompt "Docker 이미지를 다운로드합니다..." "sudo docker pull $docker_image"
execute_with_prompt "Docker 컨테이너에서 hl-visor를 실행합니다..." "sudo docker run -it --rm $docker_image"

# 6. 파일 다운로드 및 hl-visor 설정
execute_with_prompt "initial_peers.json 파일을 다운로드합니다..." "sudo -u hlnode bash -c 'curl https://binaries.hyperliquid.xyz/Testnet/initial_peers.json > ~/initial_peers.json'"
execute_with_prompt "visor.json 파일을 생성합니다..." "sudo -u hlnode bash -c 'echo \"{\\\"chain\\\": \\\"Testnet\\\"}\" > ~/visor.json'"
execute_with_prompt "non_validator_config.json 파일을 다운로드합니다..." "sudo -u hlnode bash -c 'curl https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json > ~/non_validator_config.json'"
execute_with_prompt "hl-visor를 다운로드하고 설정합니다..." "sudo -u hlnode bash -c 'curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor'"
execute_with_prompt "hl-visor를 실행 가능하게 설정합니다..." "sudo -u hlnode bash -c 'chmod a+x ~/hl-visor'"
execute_with_prompt "구성요소를 업데이트합니다..." "sudo apt-get update && sudo apt-get upgrade"

# 7. Docker 설치 및 실행
# Docker 설치 및 업데이트 여부 확인
if ! command -v docker &> /dev/null; then
    execute_with_prompt "Docker를 설치합니다..." "sudo apt-get update && sudo apt-get install -y docker.io"
else
    echo -e "${GREEN}Docker가 이미 설치되어 있습니다.${NC}"
fi
# Docker 서비스 시작 및 활성화
execute_with_prompt "Docker 서비스를 시작하고 활성화합니다..." "sudo systemctl start docker && sudo systemctl enable docker"

# 6. hl-visor 실행 (run-non-validator 서브커맨드를 사용)
execute_with_prompt "hl-visor를 시작합니다..." "sudo -u hlnode bash -c '~/hl-visor run-non-validator'"

echo -e "${YELLOW}모든 작업이 완료되었습니다. 컨트롤+A+D로 스크린을 종료해주세요.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"
