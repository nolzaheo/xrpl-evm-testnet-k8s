# 노드 컨테이너 실행 (데몬 모드)
docker run -d --name xrplevm-node \
  -v /home/$USER/.exrpd:/root/.exrpd \
  -p 26656:26656 -p 26657:26657 -p 1317:1317 -p 8545:8545 \
  --restart always \
  --entrypoint exrpd \
  peersyst/exrp:latest start

# 컨테이너 상태 확인
docker ps | grep xrplevm-node

# 로그 확인
docker logs -f xrplevm-node

# 노드 상태 확인
docker exec -it xrplevm-node exrpd status

# 동기화 상태 확인
docker exec -it xrplevm-node exrpd status | grep catching_up

# 현재 블록 높이 확인
docker exec -it xrplevm-node exrpd status | grep latest_block_height