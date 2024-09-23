#!/bin/bash

# 컬러 정의
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export NC='\033[0m'  # No Color

# 안내 메시지
echo -e "${YELLOW}하이퍼리퀴드 노드 설치 스크립트를 시작합니다.${NC}"

# 1. root/hl 폴더가 존재하면 삭제
if [ -d "/root/hl" ]; then
    echo "root/hl 폴더가 존재합니다. 삭제 중..."
    rm -rf /root/hl
    echo "폴더가 성공적으로 삭제되었습니다."
else
    echo "root/hl 폴더가 존재하지 않습니다."
fi

# 2. 패키지 업데이트 및 설치
echo -e "${YELLOW}패키지 업데이트 및 필요한 패키지 설치 중...${NC}"
sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg ufw build-essential gawk bison

# 3. hlnode 사용자 생성
echo -e "${YELLOW}hlnode 사용자를 추가합니다...${NC}"
sudo useradd -m -s /bin/bash hlnode || echo 'User hlnode already exists'

# 4. 비밀번호 설정
echo -e "${YELLOW}hlnode 사용자의 비밀번호를 설정 중입니다. 터미널에서 비밀번호를 직접 입력해 주세요.${NC}"
echo "비밀번호 설정을 완료한 후 Enter를 눌러 계속 진행하십시오."
sudo passwd hlnode
read -r -p "비밀번호 설정이 완료되었습니다. Enter를 눌러 계속 진행하십시오."

# 5. hlnode를 sudo 그룹에 추가
echo -e "${YELLOW}hlnode를 sudo 그룹에 추가합니다...${NC}"
sudo usermod -aG sudo hlnode

# 6. hlnode 사용자로 전환 후 패키지 업데이트 및 업그레이드
echo -e "${YELLOW}패키지 목록을 업데이트하고 패키지를 업그레이드합니다...${NC}"
echo "위에서 설정한 비밀번호를 입력하세요."
sudo -u hlnode bash -c 'sudo apt-get update && sudo apt-get upgrade -y'
read -r -p "Enter를 눌러 계속 진행하십시오."

# 7. GLIBC 업그레이드
echo -e "${YELLOW}GLIBC 업그레이드를 시작합니다...${NC}"
echo -e "${YELLOW}GLIBC 소스 다운로드 및 압축 해제 중...${NC}"
wget https://ftp.gnu.org/gnu/libc/glibc-2.39.tar.gz && tar -xvf glibc-2.39.tar.gz
echo -e "${YELLOW}GLIBC 컴파일 및 설치 중...${NC}"
cd glibc-2.39 && mkdir build && cd build && ../configure --prefix=/opt/glibc-2.39 && make && sudo make install
echo -e "${YELLOW}GLIBC 설치가 완료되었습니다. 새로운 GLIBC를 사용하기 위해 환경 변수를 설정합니다.${NC}"
echo "export LD_LIBRARY_PATH=/opt/glibc-2.39/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
source ~/.bashrc

# 8. 파일 다운로드 및 hl-visor 설정
echo -e "${YELLOW}initial_peers.json 파일을 다운로드합니다...${NC}"
curl -o ~/initial_peers.json https://binaries.hyperliquid.xyz/Testnet/initial_peers.json
echo -e "${YELLOW}visor.json 파일을 생성합니다...${NC}"
echo "{\"chain\": \"Testnet\"}" > ~/visor.json
echo -e "${YELLOW}non_validator_config.json 파일을 다운로드합니다...${NC}"
curl https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json > ~/non_validator_config.json
echo -e "${YELLOW}hl-visor를 다운로드하고 권한을 부여합니다...${NC}"
curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor

# 9. 사용자에게 노드정보를 입력받기
echo -e "${YELLOW}노드정보를 구성중입니다...${NC}"
read -p "프라이빗 키를 입력하세요: " PRIVATE_KEY
read -p "노드 이름을 입력하세요: " NAME
read -p "노드 설명을 입력하세요(아무말이나 작성하셔도 됩니다.): " DESCRIPTION
IP_ADDRESS=$(curl -s ifconfig.me)
echo -e "${GREEN}당신의 현재 IP주소는 다음과 같습니다: $IP_ADDRESS${NC}"

# 10. JSON 형식으로 node_config.json 파일에 저장
echo "{\"key\": \"$PRIVATE_KEY\"}" > ~/hl/hyperliquid_data/node_config.json
~/hl-node --chain Testnet send-signed-action "{\"type\": \"CValidatorAction\", \"register\": {\"profile\": {\"node_ip\": {\"Ip\": \"$IP_ADDRESS\"}, \"name\": \"$NAME\", \"description\": \"$DESCRIPTION\"}}}}" "$PRIVATE_KEY"

# 11. UFW 설치 및 포트 개방
echo -e "${YELLOW}UFW 설치 중...${NC}"
sudo apt-get install -y ufw
echo -e "${YELLOW}필요한 포트 개방 중...${NC}"
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 4000/tcp
sudo ufw allow 5000/tcp
sudo ufw allow 6000/tcp
sudo ufw allow 7000/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 9000/tcp
sleep 2

# 13. hl-visor 실행
echo -e "${YELLOW}hl-visor를 시작합니다.${NC}"
./hl-node run-validator

# 13. 검증자 활성화
echo -e "${YELLOW}검증자를 활성화합니다...${NC}"
~/hl-node --chain Testnet send-signed-action "{\"type\": \"CValidatorAction\", \"unjailSelf\": null}" "$PRIVATE_KEY"

echo -e "${YELLOW}모든 작업이 완료되었습니다. 컨트롤+A+D로 스크린을 종료해주세요.${NC}"
echo -e "${YELLOW}터미널로 돌아가서 'su - hlnode'를 입력하시고 'du -hs hl'를 입력하시면 노드가 구동중인지 확인할 수 있습니다.${NC}"
echo -e "${GREEN}스크립트 작성자: https://t.me/kjkresearch${NC}"
