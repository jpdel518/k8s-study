# kubectlチートシート
##

## 基本
#### 1. kubectlのバージョン取得
```shell
kubectl version
```
#### 2. kubectlのconfig情報
#### ~/.kube/configに記載。書き換えることで変更することも可能。
例えばdocker-desktopとminikubeのcontextがある状態でcurrent-context（現在使用しているcontext）の指定をminikubeからdocker-desktopに変更したりできる。
#### 3. kubectlのconfig情報の一部を表示
```shell
kubectl config current-context
```

## リソースの閲覧
#### 1. kubectl構文の基本
```shell
kubectl [command] [TYPE] [NAME] [flags]

# command：実行したい操作（get, create, patch, deleteなど）
# TYPE：リソースタイプ（pod, node, service, deployment）
# NAME：リソース名（特定のリソースに対してだけ操作を行いたい場合）
# flags：オプションのフラグ（--kubeconfigなど）
```

#### 2. リソース一覧の表示（NAME, SHORTNAMES, APIVERSION, KIND等が表示されるので、yamlファイル作成時にすごく便利）
```shell
kubectl api-resources
```

#### 3. kubectlの出力フォーマット
```shell
kubectl [command] [TYPE] [NAME] -o <output_format>

# output_formatには下記が入る。
# json： JSON形式で出力。jqを一緒に使うと便利。
# name： リソースタイプ/NAMEが出力
# wide： プラスアルファの情報も一緒に出力
# yaml： YAML形式で出力
# jsonpath='{.items[*].metadata.name}'： jsonの中から指定されたパスの情報だけを取ってくる
```

#### 4. Resourceをリスト表示
```shell
kubectl get [TYPE] [NAME] [flags]

# TYPE：リソースタイプ（pod, pods, po, node, nodes, service, svc）大文字小文字区別せず、単数系、複数形、短縮系が使える

# よく使うオプション：
# -n --namespace <namespace> （namespaceを指定しない場合にはdefaultというnamespaceが使われる） --all-namespacesで全てのnamespaceから取得できる

# 例：kubectl get pod -n kube-system（kube-systemというnamespace内のpodを取得）
```
#### 5. リソースの状態を取得（マニフェストファイルから。TYPE/NAME(pod/sample, replicaset.apps/sample)の取得も行える。）
```shell
kubectl get -f pod.yml
```
#### 6. リソースの状態更新を監視
```shell
kubectl get pod -w
```
#### 7. ノード上のPodリソース状態を取得。どのNodeで動いているか確認することができる！IPアドレスも取得可能。
```shell
kubectl get pod -o wide
```
#### 8. podのラベルも表示
```shell
kubectl get pod --show-labels
```
#### 9. podのラベルを使って絞る（Serviceで使用するselectorを指定。selectorのkey名はappだけとは限らない。runとか自由に付けられる）
```shell
kubectl get pod --selector app=<label名>
kubectl get pod -l app=<label名>
```
#### 10. ノード上のリソースの大部分（pod,service,deployment）の情報を取得
```shell
kubecdtl get all
```
#### 11. リソースの詳細を取得（エラーが発生して起動しない場合やクラッシュした場合など。Eventsにそういった情報が載っている）
```shell
kubectl describe [TYPE] [NAME] [flags]
```
#### 12. 対象のNodeで動いている全てのPodを確認することができる（CPUやMemoryの状態、上限を確認することもできる）
```shell
kubectl describe node <Node名>
```
***


## デバッグ系
#### 1. describe意外にデバッグ時に使用するコマンド（リソースファイルを確認）
```shell
kubectl get pod <pod名> -o yaml
```
#### 2. リソース内のログを取得（describeで分からなかった場合に確認する感じ） コンテナが複数ある場合： -c <コンテナ名>
```shell
kubectl logs TYPE(kindの事) NAME
```
#### 3. ログの更新を確認することができる
```shell
kubectl logs TYPE/NAME -f
```
***


## リソースの操作
#### 1. リソースの作成
```shell
kubectl create -f pod.yml
```
#### 2. kubenetesのマニフェストファイルからリソース（Pod, ReplicaSet, Service）の作成
```shell
kubectl apply -f pod.yml
```
####  3. コマンドのみでリソース作成（一部のTYPEのみ。作成できるものはkubectl create -hで確認することができる。）
```shell
kubectl create [TYPE] [NAME] [flags]
# 例：kubectl create namespace test-ns（test-nsというnamespaceの作成）

# よく使うオプション
# --dry-run：serverとclientを指定できる。clientのdry-runとyamlのoutputフォーマットを組み合わせてYAMLファイルのベースを作成するときに使うと便利。
# kubectl create namespace test-ns --dry-run=client -o yaml > test-ns.yaml
# kubectl apply -f test-ns.yaml
```

#### 4. リソースの削除
```shell
kubectl delete -f pod.yml
```
#### 5. リソースの削除
```shell
kubectl delete -f pod.yml（ファイル名から削除）
kubectl delete TYPE(kindの事)/NAME（リソース名から削除）
```
#### 6. コマンドのみで作成したリソースの削除
```shell
kubectl delete [TYPE] [NAME] [flags]
# 例：kubectl delete namespace test-ns（test-nsというnamespaceの削除）
```
#### 7. kubernetesオブジェクトの管理方法（いずれか１つの方法で管理を行うこと。同じオブジェクトに対し複数の管理方法を組み合わせた場合、未定義の挙動をもたらす）
* 命令型コマンド： クラスター内の現行オブジェクトに対し処理を行う。開発のみ使用。
  kubectl run nginx --image nginx
  kubectl create namespace test-ns
* 命令型オブジェクト設定： kubectlコマンドに処理内容(create, replaceなど)、任意のフラグ、そして最低１つのファイル名を指定。ファイルが対象。本番でも使用。
  kubectl create/delete/replace -f nginx.yml
* 宣言型オブジェクト設定： ユーザーはローカルに置かれている設定ファイルを操作。ユーザーはファイルに対する操作内容を指定しない（kubectlが検出）。ディレクトリが対象。本番でも使用。
  kubectl apply/diff -f configs/

#### 8. コンテナの中に入る
```shell
kubectl exec -it pod名 -sh
```
#### 9. mysqlのコンテナのなかに入る
```shell
kubectl exec -n database -it mysql-754f74cc48-8nk4r -- mysql -uroot -ppassword
show databases;
use test_db;
show tables;
select * from users;
```
#### 10. コンテナから出る
```shell
exit（プロセスを削除して出る。）
ctrl + P -> ctrl + Q（プロセスを残して出る。本番環境等のデバッグ環境以外ではこちらで出る必要がある。もしくは終了しないようにloopをcommand実行させておくか。）
```
#### 11. ローカルファイルをコンテナ内へコピー（Podで使用）
```shell
kubectl cp target_file pod名:/path/to/target_dir/
```
#### 12. コンテナ内のファイルをローカルへコピー（Podで使用）
```shell
kubectl cp pod名:/path/to/target_file ./target_file
```

## Deployment
#### 1. ロールアウト履歴確認（Deploymentで使用。リビジョンを取得）
```shell
kubectl rollout history TYPE(kindの事) NAME
```
#### 2. CHANGE CAUSEにコメントを残すにはmetadataのannotationsのkubernetes.io/change-causeにコメントを残す必要がある
#### 3. ロールバック（Deploymentで使用）（Nはrevisionの指定。デフォルト0）
```shell
kubectl rollout undo TYPE(kindの事) NAME --to-revision=N
```

## Service
#### 1. Serviceのデバッグ方法１
* ポートフォワーディング。
* kubernetesクラスターの外からクラスター内のサービスにアクセスするため。
* Service名で（DockerではこれをやらないとServiceからNodePortで外部に公開していても見ることができない。これやるとhttp://localhost:8080が表示されるURLになる）
```shell
kubectl port-forward service/<Service名> 8080:<Serviceで公開しているPort>
```
#### 2. Serviceのデバッグ方法２
```shell
kubectl get endpoints <Service名>
```
#### 3. 準備のできているIP Addressと準備のできていないIP Addressを見ることができる。IPアドレスはkubectl get pod -o wideで確認することができる。そこからどのPodのIP Addressが用意できていないのか確認する。（→そこからselectorが正しいのか確認）
```shell
kubectl describe endpoints <Service名>
```
#### 4. Serviceのデバッグ方法３
* Debug用のPodを一時的に起動してアクセス（kubectl run curl --image curlimages/curl -it sh）
```shell
kubectl run <Pod名> --image <Image名> -it sh
# デバッグPod起動実行後、ヘッドレスサービス経由でIPアドレスなしでPodにアクセス（http://nginx-0.sample-svc/）
curl http://Pod名.ヘッドレスサービス名
```
***


## DockerImageの作成
⚠︎⚠︎⚠︎⚠︎⚠︎ DockerImage作成時の注意点 ⚠︎⚠︎⚠︎⚠︎⚠︎  
* M1マックでIMAGEを作成する場合は下記では正常に作成できない事がある。（例えばmongoコマンドがインストールできなかったりする）  
```shell
docker build -t debug .
```
* 下記のコマンドのようにplatformの指定が必要
```shell
docker build --platform linux/x86_64 -t debug .
```
* 作成したIMAGEからcontainerを作成する際には同様に下記コマンドでは正常に作成できない事がある。
```shell
docker run -it debug sh
```
* 下記コマンドのようにplatformの指定が必要
```shell
docker run --platform linux/x86_64 -it debug sh
```
【参考】 https://stackoverflow.com/questions/68630526/lib64-ld-linux-x86-64-so-2-no-such-file-or-directory-error


## mongodb
#### mongodbのReplicaSetの初期化設定の仕方
```shell
mongo
use admin
db.auth("admin", "Passw0rd")
rs.initiate({
  _id: "rs0"
  members: [
    {_id: 0, host: "mongo-0.db-svc:27017"},
    {_id: 1, host: "mongo-1.db-svc:27017"},
    {_id: 2, host: "mongo-2.db-svc:27017"}
  ]
})

```
#### 初期化進行状態の確認。どのPodがPrimaryでSecondaryなのかも分かる
```shell
rs.status()
```
#### 初期化し直したい場合
#### 全レプリカにある/data/db/配下のデータを全て削除して、リソースも削除、作成し直す
```shell
kubectl exec -it mongo-0 sh
rm -rf /data/db/*
kubectl exec -it mongo-1 sh
rm -rf /data/db/*
kubectl exec -it mongo-2 sh
rm -rf /data/db/*
kubectl delete -f weblog-db-headless.yml
kubectl delete persistentVolume名 persistentVolumeClaim名
```
