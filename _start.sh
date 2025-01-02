#!/usr/bin/bash
# NOTE: run as root

mkdir /opt/TChat/
#? simply chmod all to test
chmod -R 777 /opt/TChat/
cd /opt/TChat/

######################
# Install dependencies
######################
apt install openjdk-11-jdk -y
apt install mysql -y
apt install redis -y


wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
xz -d ffmpeg-release-amd64-static.tar.xz
tar xf ffmpeg-release-amd64-static.tar
cd ffmpeg-5.0-amd64-static/
cp ff* /usr/local/bin/


wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
go version
go mod tidy
make -j4

#? for minio
mkdir /data
chmod -R 750 /data


######################
# Setup mysql
######################
# setup mysql root password
# then change all .yaml files in teamgram-server/teamgramd/etc/ to use the new password
# example: set password to `TCh4t_2o2A` then change Mysql block to something similar:
# ```
# Mysql:
#   DSN: root:TCh4t_2o2A@tcp(127.0.0.1:3306)/teamgram?charset=utf8mb4&parseTime=true
#   Active: 64
#   Idle: 64
#   IdleTimeout: 4h
# ```


######################
# Init Database
######################
# 1. create teamgram database
# mysql -uroot -p
# mysql> create database teamgram;
# mysql> exit
# 
# 2. import sql scripts
# mysql -uroot teamgram < teamgramd/sql/1_teamgram.sql
# mysql -uroot teamgram < teamgramd/sql/migrate-*.sql
# mysql -uroot teamgram < teamgramd/sql/z_init.sql


######################
# Run
######################

#? kill rsync if there's any process running
kill -9 $(pgrep rsync) 


echo "run etcd ..."
tmux new -d -s etcd "cd /opt/TChat/etcd-download-test/ && ./etcd"
sleep 5

echo "run zookeeper ..."
tmux new -d -s zookeeper "cd /opt/TChat/kafka_2.11-2.2.1 && ./bin/zookeeper-server-start.sh ./config/zookeeper.properties"
sleep 5
echo "run kafka ..."
tmux new -d -s kafka "cd /opt/TChat/kafka_2.11-2.2.1/ && ./bin/kafka-server-start.sh ./config/server.properties"

echo "run minio ..."
tmux new -d -s minio "cd /opt/TChat/ && ./minio server /data"

echo "run pika ..."
tmux new -d -s pika "cd /opt/TChat/pika/ && ./bin/pika -c ./conf/pika.conf"

sleep 5



cd /opt/TChat/teamgram-server/teamgramd/bin/


ps aux | grep "./bin/idgen" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/status" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/authsession" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/dfs" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/media" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/biz" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/msg" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/sync" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/bff" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/session" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/gnetway" | grep -v grep | awk '{print $2}' | xargs kill -9
ps aux | grep "./bin/httpserver" | grep -v grep | awk '{print $2}' | xargs kill -9

sleep 5


echo "run idgen ..."
tmux new -d -s idgen "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./idgen -f=../etc/idgen.yaml"
sleep 1

echo "run status ..."
tmux new -d -s status "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./status -f=../etc/status.yaml"
sleep 1

echo "run authsession ..."
tmux new -d -s authsession "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./authsession -f=../etc/authsession.yaml"
sleep 1

echo "run dfs ..."
tmux new -d -s dfs "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./dfs -f=../etc/dfs.yaml"
sleep 1

echo "run media ..."
tmux new -d -s media "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./media -f=../etc/media.yaml"
sleep 1

echo "run biz ..."
tmux new -d -s biz "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./biz -f=../etc/biz.yaml"
sleep 1

echo "run msg ..."
tmux new -d -s msg "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./msg -f=../etc/msg.yaml"
sleep 1

echo "run sync ..."
tmux new -d -s sync "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./sync -f=../etc/sync.yaml"
sleep 1

echo "run bff ..."
tmux new -d -s bff "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./bff -f=../etc/bff.yaml"
sleep 5

echo "run session ..."
tmux new -d -s session "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./session -f=../etc/session.yaml"
sleep 1

echo "run gnetway ..."
tmux new -d -s gnetway "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./gnetway -f=../etc/gnetway.yaml"
sleep 1

echo "run httpserver ..."
tmux new -d -s httpserver "cd /opt/TChat/teamgram-server/teamgramd/bin/ && ./httpserver -f=../etc/httpserver.yaml"
sleep 1


# echo "run tweb ..."
# tmux new -d -s tweb "cd /opt/TChat/tweb/ && pnpm start --host"
# sleep 1