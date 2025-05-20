# 도커 이미지 풀
$ docker pull peersyst/exrp:latest

# 필요한 패키지 설치
sudo apt-get install -y wget lz4 curl grep sed

# 스냅샷 다운로드 스크립트 실행
chmod +x ./sh_scripts/download_snapshot.sh
./sh_scripts/download_snapshot.sh

# 스냅샷 파일 이름 가져오기 (download_snapshot.sh에서 다운로드한 가장 최신 파일)
SNAPSHOT_FILE=$(ls -t xrp_*.tar.lz4 | head -1)

# node data 저장을 위한 디렉토리 생성
$ mkdir -p /home/$(whoami)/.exrpd

# 스냅샷 압축 해제 및 데이터 디렉토리로 이동
$ lz4 -c -d $SNAPSHOT_FILE | tar -x -C $HOME/.exrpd

# 다운로드 받은 스냅샷 파일 삭제
$ rm -v $SNAPSHOT_FILE

# 컨테이너 실행 및 내부 접속
$ docker run -it --name xrplevm-setup \
  -v /home/$(whoami)/.exrpd:/root/.exrpd \
  -e DAEMON_NAME=exrpd \
  -e DAEMON_HOME=/root/.exrpd \
  peersyst/exrp:latest /bin/sh

# 키링 백엔드를 file로 설정
exrpd config set client keyring-backend file

# 키링 디렉토리 생성 (file 백엔드용)
mkdir -p /root/.exrpd/keyring-file
chmod 700 /root/.exrpd/keyring-file

# 체인 ID 설정 및 다른 초기화 명령들...
exrpd config set client chain-id xrplevm_1449000-1
exrpd init anam145 --chain-id xrplevm_1449000-1
wget -O /root/.exrpd/config/genesis.json https://raw.githubusercontent.com/xrplevm/networks/refs/heads/main/testnet/genesis.json
PEERS=$(curl -sL https://raw.githubusercontent.com/xrplevm/networks/main/testnet/peers.txt | sort -R | head -n 10 | awk '{print $1}' | paste -s -d,)
sed -i.bak -e "s/^seeds *=.*/seeds = \"$PEERS\"/" /root/.exrpd/config/config.toml

# RPC 및 API 주소 변경
# config.toml에서 RPC 주소를 0.0.0.0으로 변경
sed -i 's|^laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' /root/.exrpd/config/config.toml

# app.toml 설정 변경 (파일이 이미 존재하는 경우)
if [ -f "/root/.exrpd/config/app.toml" ]; then
  # API 주소 변경
  sed -i 's|address = "tcp://127.0.0.1:1317"|address = "tcp://0.0.0.0:1317"|' /root/.exrpd/config/app.toml
  
  # JSON-RPC 주소 변경
  sed -i 's|address = "127.0.0.1:8545"|address = "0.0.0.0:8545"|' /root/.exrpd/config/app.toml
  sed -i 's|ws-address = "127.0.0.1:8546"|ws-address = "0.0.0.0:8546"|' /root/.exrpd/config/app.toml
  
  # minimum-gas-prices 설정 (아직 설정되지 않은 경우)
  if ! grep -q "^minimum-gas-prices =" /root/.exrpd/config/app.toml; then
    sed -i '1s/^/minimum-gas-prices = "0axrp"\n/' /root/.exrpd/config/app.toml
  fi
else
  # app.toml이 없는 경우 새로 생성
  cat > /root/.exrpd/config/app.toml << EOL
minimum-gas-prices = "0axrp"

[api]
enable = true
swagger = true
address = "tcp://0.0.0.0:1317"

[json-rpc]
enable = true
address = "0.0.0.0:8545"
ws-address = "0.0.0.0:8546"
api = "eth,net,web3,txpool"

[telemetry]
enable = false
EOL
fi

# 변경 사항 확인
echo "확인: RPC 설정"
grep -n "laddr" /root/.exrpd/config/config.toml | grep "26657"

echo "확인: API 및 JSON-RPC 설정"
if [ -f "/root/.exrpd/config/app.toml" ]; then
  grep -n "address" /root/.exrpd/config/app.toml
  grep -n "minimum-gas-prices" /root/.exrpd/config/app.toml
fi

# 밸리데이터 키 생성 (file 백엔드 사용)
exrpd keys add anam145_validator_key_tmp --key-type eth_secp256k1 --keyring-backend file

# 비밀번호를 입력 후 반드시 기억!
# 니모닉 구문 안전보관!

# 컨테이너 종료
exit

# 설정 컨테이너 중지 및 삭제
docker stop xrplevm-setup
docker rm xrplevm-setup