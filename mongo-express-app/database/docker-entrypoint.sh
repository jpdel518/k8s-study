#! /bin/sh
INIT_FLAG_FILE=/data/db/init-completed
INIT_LOG_FILE=/data/db/init-mongod.log

start_mongod_as_daemon() {
echo
echo "> start mongod ..."
echo
mongod \
  --fork \
  --logpath ${INIT_LOG_FILE} \
  --quiet \
  --bind_ip 127.0.0.1 \
  --smallfiles;
}

create_user() {
echo
echo "> create user ..."
echo
if [ ! "$MONGO_INITDB_ROOT_USERNAME" ] || [ ! "$MONGO_INITDB_ROOT_PASSWORD" ]; then
  return
fi
mongo "${MONGO_INITDB_DATABASE}" <<-EOS
  db.createUser({
    user: "${MONGO_INITDB_ROOT_USERNAME}",
    pwd: "${MONGO_INITDB_ROOT_PASSWORD}",
    roles: [{ role: "root", db: "${MONGO_INITDB_DATABASE:-admin}"}]
  })
EOS
}

create_initialize_flag() {
echo
echo "> create initialize flag file ..."
echo
cat <<-EOF > "${INIT_FLAG_FILE}"
[$(date +%Y-%m-%dT%H:%M:%S.%3N)] Initialize scripts if finigshed.
EOF
}

stop_mongod() {
echo
echo "> stop mongod ..."
echo
mongod --shutdown
}

if [ ! -e ${INIT_FLAG_FILE} ]; then
  echo
  echo "--- Initialize MongoDB ---"
  echo
  start_mongod_as_daemon
  create_user
  create_initialize_flag
  stop_mongod
fi

exec "$@"



##! /bin/sh
#INIT_FLAG_FILE=/data/db/init-completed
#INIT_LOG_FILE=/data/db/init-mongod.log
#
## MongoDBの起動
#start_mongod_as_daemon() {
#echo
#echo "> start mongod ..."
#echo
## forkはデーモン起動するためのオプション
## quietはログをあまり表示させない
## bind_ipは受け付けるIPアドレス
## small_filesはファイル類を最小限に
#mongod \
#  --fork \
#  --logpath ${INIT_LOG_FILE} \
#  --quiet \
#  --bind_ip 127.0.0.1 \
#  --smallfiles;
#}
## ユーザ作成
#create_user() {
#echo
#echo "> create user ..."
#echo
## $MONGO_INITDB_ROOT_USERNAMEもしくは$MONGO_INITDB_ROOT_PASSWORDが設定されていなければ処理終了
#if [ ! "$MONGO_INITDB_ROOT_USERNAME" ] || [ ! "$MONGO_INITDB_ROOT_PASSWORD" ]; then
#  return
#fi
#mongo "${MONGO_INITDB_DATABASE}" <<-EOS
#  db.createUser({
#    user: "${MONGO_INITDB_ROOT_USERNAME}",
#    pwd: "${MONGO_INITDB_ROOT_PASSWORD}",
#    roles: [{ role: "root", db: "${MONGO_INITDB_DATABASE:-admin}"}]
#  })
#EOS
#}
## フラグ作成
#create_initialize_flag() {
#echo
#echo "> create initialize flag file ..."
#echo
#cat <<-EOF > "${INIT_FLAG_FILE}"
#[$(date +%Y-%m-%dT%H:%S.%3N)] Initialized scripts if finished.
#EOF
#}
#stop_mongod() {
#echo
#echo "> stop mongod ..."
#echo
#mongod --shutdown
#}
#
#
## フラグがなければ初期化処理実行
#if [ ! -e ${INIT_FLAG_FILE} ]; then
#  echo
#  echo "--- Initialize MongoDB ---"
#  echo
#  # MongoDBの起動
#  start_mongod_as_daemon
#  # ユーザ作成
#  create_user
#  # フラグ作成
#  create_initialize_flag
#  stop_mongod
#fi
#
#exec "$@"
