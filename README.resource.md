# リソースチートシート

## マニフェストファイルの基礎
```yaml
apiVersion: <どのバージョンのkubernetes APIか。kindに応じて指定できる値が変わる。右記リファレンスに情報が載っている。> #https://kubernetes.io/docs/reference/
kind: <作成するオブジェクトの種別>
metadata: # オブジェクトを一意に扱うための情報
  name: <namespaceと一緒に使う。nameとnamespaceで一意になる必要がある。>
  namespace: <nameと一緒に使う。nameとnamespaceで一意になる必要がある。指定しない場合はdefaultというnamespaceが自動で設定される。>
# namespaceは単一の物理クラスターで複数の仮想クラスターを作成するのに使用。１つのクラスターを論理的に分けて使用する。
# 使用例としては・特定の目的：frontend, backend, monitoring ・チーム ・環境：production, developmentでnamespaceを分けて使用する。
# namespaceを分けるメリット：・Podやコンテナのリソース範囲指定（cpuやストレージ上限設定、defaultのcpuやメモリを設定）、・namespace全体の総リソース制限（あるnamespaceだけがリソースを使いすぎないように）、・権限（BRAC）の管理（チームごとに特定のnamespaceへの権限を付与）
# namespaceを削除するとnamespaceに属するリソースも全て削除される）
  labels: # 任意で設定できる
    app: <appラベル>
    env: <envラベル>
spec: <オブジェクトの理想状態>
```
***


## Pod
* Podはkubernetesの最小単位。Podの中には複数のdocker containerが含まれる。
* ⚠︎⚠︎⚠︎ Podは直接使用されない。何らかの理由でPodの数が減ってしまった場合に自分で追加しなければいけない。それを人の代わりにやってくれるのがReplicaSet。
* 主要なspecはcontainersとvolumesの２種類。
```yaml
spec:
  containers: # Podに格納するコンテナ情報を指定）
    name: <Pod内のコンテナ一位に特定できる名前を指定。>
    image: <コンテナイメージを指定。バージョン指定しない場合はlatestになるので注意。>
    imagePullPolicy: <イメージ取得方法を指定。Always：毎回リポジトリからダウンロード。Never：ローカルイメージを利用。IfNotPresent：ローカルに存在すればローカルを利用し、なければリポジトリからダウンロードする。デフォルトはIfNotPresent。>
    command: <コンテナへ引き渡すコマンド、dockerで言うところのENTRYPOINT。つまり実行部分。>
    args: <コンテナへ引き渡すコマンド、dockerで言うところのCMD。つまりcommandに引数として渡される部分。envから値を${env名}で取得、使用することも可能。>
    env: # configmap, secretを利用する方法の１つ。もう１つはvolumesから利用する方法。コンテナへ引き渡す環境変数を指定、動作変更させるためによく使う。
      name: <環境変数名>
      valueFrom:
        configMapKeyRef: # configmapの場合
          name: <ConfigMapのmetadata.nameと一致>
          key: <ConfigMap.dataに記載のkey値と一致。keyを書かない場合はmetadata.nameで一致したものを全て取ってくる>
        secretKeyRef: # secretの場合
          name: <Secretのmetadata.nameと一致>
          key: <Secret.dataに記載のkey値と一致。keyを書かない場合はmetadata.nameで一致したものを全て取ってくる>
    volumeMounts: # volumesで定義したデータをコンテナへマウント。マウント先ストレージを指定
      name: <spec.volumes.configMap.nameに一致させる。それによってどのvolumeをどのマウントパスに紐づけるのか指定することができる。>
      mountPath: <マウントさせるコンテナ内のパスを指定>
      readOnly: <読み取り専用かどうか。デフォルトはfalse>

    # kubernetesでのヘルスチェック -> podレベルでのヘルスチェック kubectl describe podで再起動やリクエストを受け付け内容になったログを確認することが
    # LiveinessProbe：Podが正常に動作しているかどうかを確認する。Podが正常に動作していない場合は再起動する。
    # ReadinessProbe：Podがリクエストを受け付ける準備ができているかどうか（サービスインする準備ができているかどうか）を確認する。Podが準備ができていない場合はリクエストを受け付けない。
    # livenessProbe or readinessProbe（両方同時に設定することも可能）
    livenessProbe:
      httpGet:
        path: / # ヘルスチェックするパス
        port: 80 # ヘルスチェックするポート番号
      initialDelaySeconds: 5 # 5秒後に最初のヘルスチェックを起動
      timeoutSeconds: 1 # 1秒以内に応答がなければ、コンテナを再起動する
      periodSeconds: 10 # ヘルスチェックを行う間隔（10秒）
      failureThreshold: 3 # ヘルスチェックが失敗した場合にコンテナを再起動するまでの閾値（3回）
  volumes: # 大分類はボリューム名、データ保存先の２つ。データ保存先はhostPath,nfs,configMap,secret,emptyDirなどを指定できる。volumeMountsとセットで利用。(ボリュームとネットワークは同一Pod内で共有されるためコンテナの外に定義される）
    name: <ボリューム名を指定、containers.volumeMounts.nameに一致させることでマッピングさせる。>
    hostPath: # ホストサーバ上のパスを指定
      path: <ホスト上のパス>
      type: <Directory：存在するディレクトリ。DirectoryOrCreate：ディレクトリが存在しなければ作成。File：存在するファイル。FileOrCreate：ファイルが存在しなければ作成>
    nfs: # NFSサーバを指定
      server: <NFSサーバのIPアドレス>
      path: <NFSサーバ上のパス>
    configMap: # kubernetes上のリソースであるconfigMapを利用する方法の１つ。もう１つはenvから環境変数に設定する方法。
      name: <ConfigMapのmetadata.nameと一致>
      items: # 省略可能
        key: <ConfigMap.dataに記載のkey値と一致>
        path: <ConfigMapの保存先ファイル名。キーと同じ名前を使うのが分かりやすい>
    secret: # kubernetes上のリソースであるsecretを利用する方法の１つ。もう１つはenvから環境変数に設定する方法。
      secretName: <Secretのmetadata.nameと一致>
      items: # 省略可能
        key: <Secretのどのキーを使うのか>
        path: <Secretの保存先ファイル名。キーと同じ名前を使うのが分かりやすい>
    emptyDir: {} # 一時的な空ディレクトリを指定
```
***


## ワークロードリソースについて
#### 複数のPodを作成・管理するためのリソース。
* Replicaset：指定したレプリカ数のPodを常に保証する
* Deployment：PodとReplicasetのアップデート機能を提供
* Daemonset：Podを全てのノードで稼働させる
* Statefulset：ステートフルなアプリケーションを管理。Podの順番を保証したい場合に使用する
* Job：Podの作成時と失敗時の対応を定義
* Cronjob：定期的にJobをスケジュール
#### ワークロードリソースにはPodテンプレートが必要
#### Podテンプレート：ワークロードリソースはPodを作成するので、どんなPodを作成するか定義書が必要になる。ワークロードリソースが作成、管理するPodの情報。
#### Podテンプレートにはコンテナ名、コンテナイメージ、ボリューム、リソースなどを指定することができる。ただし、Pod名はワークロードリソースが自動で付与するので、Podテンプレートには記載しない。
***

## ReplicaSet
#### ReplicaSetはPodの集合。Podをスケールできるのが特徴。
#### ⚠︎⚠︎⚠︎ ReplicaSetは普段直接使用されない。  
#### ⚠︎⚠︎⚠︎ DeploymentというReplicaSetを管理するリソースを使用することが推奨されている。→ReplicaSetはReplica数を保証するだけで、新しいPodに入れ替える（Deploy時のPodバージョンアップ）機能がないため。
#### 主要なspecはreplicasとselector、templateの３種類。
```yaml
spec:
  replicas: <稼働させたいPodの数。この値を指定することでスケールアウトやスケールインが可能。>
  selector: <対象となるPodを特定するため。matchLabels.app, matchLabels.envを指定。基本的にはテンプレートとして含めるPodのmetadata.labelsに一致させる>
  template: # Podテンプレート。複製したいPodのマニフェストファイルを指定。中身はPodと全く同じ。
```
#### マニフェストファイルのreplicasの値を変更して、kubectl applyする事でPodのスケールを変更することができる。
#### コマンドからreplicasを変更する方法
```shell
kubectl scale rs/replicaset名 --replicas=3
```

## Deployment
#### DeploymentはReplicaSetの集合。ReplicaSetのロールアウト（更新）、前のバージョンロールバック（戻す）といった世代管理ができる。
#### ほとんどのアプリケーション（定義実行するJOB意外）はDeploymentで管理。ローリングアップデートやロールバックなどのアップデート機能を提供。
#### 主要なスペックは５種類。
```yaml
spec:
  replicas: <ReplicaSetと同様>
  selector: <ReplicaSetと同様>
  revisionHistoryLimit: <ReplicaSetの履歴保存数の指定。デフォルトは10。>
  strategy: # 更新戦略。RecreateかRollingUpdateを指定。基本的にはRollingUpdate
    type: <RollingUpdateを指定>
    rollingUpdate: # maxSurge、maxUnavailableを使用してどれくらいの勢いでrollingUpdateしていくか指定
      maxSurge: <replicasを超えて良いPod数。更新処理にいくつエクストラで追加できるPodの最大数>
      maxUnavailable: <一度に消失して良いPod数を指定。更新処理中に使用不可になるPodの最大数>
  paused: <ロールアウトを明示的に一時停止させる。基本使わない>
  progressDeadlineSeconds: <更新プログレスの最大秒数。デフォルトは600秒。基本使わない>
  template: # ReplicaSetと基本同じ。ただしresourcesによりAutoScalingを設定可能。（HPA: Horizontal Pod Autoscaler）
    spec:
      containers:
        resources:
          limits: # リソースの上限値を指定。Podが使用するリソース(CPU/メモリ)に制限を設けることができる。Resource Limitで指定されたリソース以上にコンテナプロセスが使用しようとした場合、、CPUの場合は速度が遅くなる、、Memoryの場合はコンテナプロセスがキルされる。
            cpu: <CPUの上限値を指定。>
            memory: <メモリの上限値を指定。>
          requests: # リソースの要求値を指定。Podをデプロイする時に対象Node上にデプロイされている全Podのrequestsリソース（cpu/memory）量がNodeのキャパシティをオーバーしないようにチェックする仕組み。あくまでもrequestsのリソースであって実リソース量に空きがあることを保証する仕組みではない
            cpu: <CPUの要求値を指定。>
            memory: <メモリの要求値を指定。>
```
#### マニフェストファイルを変更して、kubectl applyする事でデプロイしてヒストリーを残すことができる。
#### コマンドからimageを変更する方法
```shell
kubectl set image deployment/<deployment名> <Podテンプレートのコンテナ名>=nginx:1.16.0
```
#### ヒストリーの確認（Revisionの番号が大きい方がより新しいReplicaSetを表す）
```shell
kubectl rollout history deployment.v1.apps/<deployment名>
```
#### ヒストリーのロールバック（ヒストリーのRevision１に戻すことができる）
```shell
kubectl rollout undo deployment.v1.apps/deployment名 --to-revision=1
```
#### コマンドによる既存のdeploymentへHPAを適用（cpu50%でスケール。最低Pod数1、最大Pod数10）
```shell
kubectl autoscale deploy <deployment名> --cpu-percent 50 --min 1 --max 10
```
#### リソースによる既存のdeploymentへHPAを適用
```shell
kubectl autoscale deploy <deployment名> --cpu-percent 50 --min 1 --max 10 dry-run=client -o yaml > hpa.yaml
kubectl apply -f hpa.yaml
```
#### 作成したHPAの確認
```shell
kubectl get hpa
```
#### 負荷をかける方法
```shell
kubectl run apache-bench -i --tty --rm --image httpd -- /bin/sh -c "while true; do ab -n 10 -c 10 http://nginx.default.svc.cluster.local/ > /dev/null; done;"
```
#### 負荷状態を確認
```shell
watch "kubectl get hpa"
```
***

## HPAファイル
#### Deploymentをスケーリングするためのリソース
#### HorizontalPodAutoScaler(HPA)を有効にするにはメトリクスサーバーをclusterに入れる必要がある
#### メトリクスサーバーのインストール（https://github.com/kubernetes-sigs/metrics-server/tree/master/charts/metrics-server）
#### インストールすると下記コマンド実行可能
```shell
# nodesのCPU/memory使用量をチェック
kubectl top nodes 

# PodsのCPU/memory使用量をチェック
kubectl top pods
```
#### HPAファイルの構成
```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: test-hpa
spec:
  maxReplicas: 7  # 最大レプリカ数
  minReplicas: 1  # 最小レプリカ数
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: test-hpa  # ターゲットになるDeploymentのmetadata.nameに一致
  targetCPUUtilizationPercentage: 80 # scale upする際のパーセンテージ。 resources.limitsをベース(100%)にしてスケーリングする。
status:
  currentReplicas: 0
  desiredReplicas: 0
```
#### 負荷テスト
```shell
# 負荷テスト方法：同時並行して1000個のリクエストを500000000リクエストになるまでtest-hpaに投げる
kubectl run apache-bench -it --rm \
  --image=httpd \
  --restart Never \
  -- ab -n 500000000 -c 1000 test-hpa/
```
***


## Service
#### ServiceはPodの集合を抽象化して公開するのが役割。
#### Podの集合に対するDNS名。
#### Podの集合に対する負荷分散。（外部公開、名前解決、L4ロードバランサーの役割）
#### 背景：各PodはIPアドレスを持っている。理想状態に近づけるためにPodの作成、削除されるが、そのたびにアプリケーションのIPアドレスが変化する → 使う側が大変
#### ServiceがDNS名を提供し、後ろにあるIPアドレスの管理をしてくれる -> 常に同じ名前を使ってアプリケーションを参照できる。
#### Serviceは対象となるPodを認識する必要がある -> セレクターを使ってターゲットとなるPodを定義（Podのラベルを使用する）
#### Portのマッピングをすることもできる。（Service側のPortとPodのPortが異なっていてもOK）
#### Serviceが作成されると、ターゲットとなるPodのIPアドレスはエンドポイントという別のリソースに格納されるようになる。（kubectl get endpoints <Service名>）
#### 全部で４種類
* ClusterIP（クラスタネットワーク内にIPアドレスを公開。名前指定でPodへ到達できるようにする。KubernetesCluster内の通信で使用）
* NodePort（ClusterIPに加え、Nodeのポートにポートマッピングして受け付けられるようにする。Kubernetesで動作している全てのnodeが同じPort番号を受け付けることで、外部からの接続を受け付ける。KubernetesCluster外との通信で使用。kubectl get node -o wideで取得したNodeのIP + kube解放したportで接続ができるようになる。接続できない場合はAWSのセキュリティグループ）
* LoadBalancer（NodePortに加え、クラウドプロバイダーのロードバランサーを利用してサービスを公開する。）
* ExternalName（外部サービスに接続）
#### 主要なspecは４種類
```yaml
spec:
  type: <サービスの種類を指定。デフォルトはclusterIP。>
  clusterIP: <typeがclusterIPの時に指定。clusterIPの時はクラスタネットワーク内のIPアドレスを指定。Noneを指定するとHeadlessServiceになる。HeadlessServiceはロードバランサを使わずにDNSラウンドロビンしたいときに使うService。個々のPodでPVを作成し、異なるデータを格納するStatefulSet（どのPodへリクエストするかで結果が異なる）では必ずHeadlessサービスをペアで使用。""（空文字）はIPアドレスの自動採番。ClusterIPへは<Service名>.＜Namespace名＞.svc.cluster.localで接続可能>
  ports: # 受付または転送先のポート番号を指定。
    port: <サービスで公開するPort>
    targetPort: <Pod側のPort。コンテナ転送ポート。省略した場合はportで指定したものと同じ番号が使用される。>
    nodePort: <typeがNodePortの場合に使用。ノード受付ポート。外部から接続する際のポート番号になる）
  selector: # 転送先のPodを特定するラベルを指定。
    app: <転送先のPodを指定>
    env: <転送先のPodを指定>
```
#### clusterIPを指定した場合、serviceからホスト名を指定する方法：<service名>.<serviceのネームスペース>.svc.cluster.local（例：mysql.database.svc.cluster.local cluster.localはそのサービスのクラスター内という指定になる）
#### 本当に↑の名前解決されているかの確認：kubectl run testpod --image=centos:6 --restart=Never -i --rm -- dig competition-site-service.competition-site.svc.cluster.local
#### StatefulSetを使用してpod-0 pod-1 pod-2のように同じPodを複数起動した場合、HeadlessServiceを使用することでpod-0.db-svc（Pod名＋HeadlessService名）で名前解決できるようになる
***


## ConfigMap
#### ConfigMapはKubernetes上の機密性のない設定情報をキーとバリューで保存し、Podから参照できる。
#### コンテナイメージとは別に設定情報を保存することで、コンテナイメージの再ビルドをしなくても設定情報を変更できる。
#### specではなく、dataにキーバリュー形式でconfigを記述。ファイルとして保存する場合は、dataのキーにファイル名、バリューにファイルの中身を記載する。
#### configMapを参照する方法は２種類。
* Podの環境変数に設定する方法（Podのspec.containers.envを使用。アプリケーションの接続先DB Host,User,Portとか）
* 読み取り専用のボリュームを作成しコンテナから読み込む（Podのvolumes/volumeMountsを使用してファイルとしてマウントする方法。Nginxのconfファイルとか）。
#### コマンドから作成する
```shell
kubectl create cm <configmap名> --from-literal=<key名>='<value>' --dry-run=client -o yaml > <configmapリソースファイル名>
kubectl apply -f <configmapリソースファイル名>
```
#### Key-Value形式のファイルから作成する
```shell
kubectl create cm <configmap名> --from-env-file=<filepath> --dry-run=client -o yaml > <configmapリソースファイル名>
kubectl apply -f <configmapリソースファイル名>
```
#### configmapを更新する
```shell
kubectl edit cm <configmap名> 

# 反映させるにはPodの再作成が必要になる
kubectl rollout restart deployment <deployment名>
```
***


## Secret
#### SecretはKubernetes上で扱う機微情報（パスワードやトークン）を保存、管理しPodから参照可能にする。base64エンコードされている。
#### specではなく、dataにキーバリューで記述。
#### 種類
* Opaque(ユーザが定義したデータ)
* kubernetes.io/dockercfg(Dockerへのレジストリへの接続権限)
* kubernetes.io/basic-auth(basic認証) など
#### 生成方法は２種類（Secretファイルは通常、運用作業で作られることになるのでコマンド生成になる）
* マニフェストファイルから生成する方法
* コマンドで直接生成する方法
#### マニフェストファイルから生成
```yaml
data/stringData：base64エンコードしたデータ/生データ。secretの中身を見たい時はデコードする
type:（タイプを指定。例：Opaque(デフォルト)）
```
#### YAMLを自分で記述（dataに記載）する際に、Secret元になるkeyfileの作成方法
```shell
# 鍵ファイルの作成？
openssl rand -base64 1024 | tr -d '\r\n' | cut -c 1-1024 > keyfile

# base64文字列の作成
echo -n 文字列 | base64

# 複数行文字列をbase64文字列に変換。
echo -n '複数行文字列' | base64

# ファイルに記述された文字列をbase64にしたい場合
cat ファイル名 | base64
```
#### dataに記載されているデータをbase64デコードする
echo -n dataに記載base64文字列 | base64 --decode

#### コマンドから生成
```shell
kubectl create secret generic <secret名>

# コマンドでキーバリューを指定して生成（--dry-run=client -o yamlでYAMLファイルに出力する方法も使われる）
kubectl create secret generic <secret名> --from-literal=<key>=<value>

# コマンドでファイルから生成（--dry-run=client -o yamlでYAMLファイルに出力する方法も使われる）
kubectl create secret generic <secret名> --from-file=<key>=<filepath>
```

#### Secret情報を確認
```shell
kubectl get secret
```
#### Secret情報の中身を確認（yaml形式で出力）。中身を出力したらマニフェストファイル（yaml）に中身をコピペする。
```shell
kubectl get secret/secret名 -o yaml
```
# Secretの削除。マニフェストファイルに中身をコピペし終わったら削除しておくこと！
```shell
kubectl delete secret/secret名
```
#### 使用方法は３つ。
* ボリューム内のファイルとして、Pod内のコンテナとしてマウントする方法
* コンテナの環境変数の設定。
* kubectlがDockerイメージをPullする際に使用。
***

**再チェックが必要**
## PersistentVolume & PersistentVolumeClaim
#### PersistentVolume（PV。永続データ。ストレージへの接続情報とストレージを抽象化したもの）
```yaml
spec:
  storageClassName: <ストレージ抽象化を定義するプロパティ。ストレージの種類を定義。hostPathを定義する場合は任意の文字列でOK。>
  accessModes: <ストレージ抽象化を定義するプロパティ。読み書きを定義。ReadWriteOnce：単一ノードから読み書きする。ReadOnlyMany：複数ノードから読み取りのみする。ReadWriteMany：複数ノードから読み書きする。>
  capacity: # ストレージ抽象化を定義するプロパティ。ストレージ容量の定義。
    storage: <1Gi>
  persistentVolumeReclaimPolicy: <削除時動作を定義するプロパティ。PVC削除時にPVがどう動作するのか。Retain：PVCが消えてもPVを残す。Delete：PVCが消えたらPVも消す。>
  hostPath: # 保存先を定義するプロパティ。その他にもnfs,localとかもある。https://kubernetes.io/ja/docs/concepts/storage/persistent-volumes/#%E6%B0%B8%E7%B6%9A%E3%83%9C%E3%83%AA%E3%83%A5%E3%83%BC%E3%83%A0%E3%81%AE%E7%A8%AE%E9%A1%9E）
    path: <ホスト上の保存先の指定>
    type: <Directory：存在するディレクトリ。DirectoryOrCreate：ディレクトリが存在しなければ作成。File：存在するファイル。FileOrCreate：ファイルが存在しなければ作成>
```
#### PersistentVolumeClaim（PVC。永続データを要求）
```yaml
spec:
  storageClassName: <ストレージ抽象化を定義するプロパティ。PVと同様。>
  accessModes: <ストレージ抽象化を定義するプロパティ。PVと同様>
  resources: # ストレージ抽象化を定義するプロパティ。PVのcapacityに対して要求するストレージ容量
    requests:
      storage: <1Gi>
```
#### kubectl get pv, pvcで確認
#### 【TIPs】pvをマウントしているとkubectl delete -fしてもリソースが残ることがあるっぽい。kubectl delete pv/pv名前とkubectl delete pvc/pvc名前で個別に削除してから-fで削除する必要がある。
***


## StatefulSet
#### StatefulSet（Podの集合。Podをスケールする際の名前が一定になる。Deploymentとマニフェストファイルの記載はほぼ同じ。Deploymentと異なるのはPodとPVCがセットで定義できるところ。）
```yaml
spec:
  updateStrategy: <Deploymentのstrategyと同等。strategyじゃなくupdateStrategy>
  serviceName: <ServiceのHeadlessServiceを指定。metadataのnameと一致させる。>
  template: <Podのテンプレート。Podのマニフェストファイルを記載。>
  volumeClaimTemplates: <PVCのテンプレート。PVCのマニフェストファイルを記載。>
```
#### headlessServiceと組み合わせて使用。Podの名前が一定になる。（例：nginx-0, nginx-1, nginx-2）
#### <pod名>.<headlessService名>.<namespace>.svc.cluster.localでアクセスできる。
***

## Ingress
#### Ingress（外部公開する際に使用。L7ロードバランサーの役割を果たす。L7ロードバランサーを使用するとURLでサービスを切り替えることができる。）
```yaml
metadata:
  annotations:
    kubernetes.io/ingress.class: "nginx" # minikubeので使えるingressの実態はnginxなのでそれを指定する
    nginx.ingress.kubernetes.io/ssl-redirect: "false" # SSLのリダイレクトの無効化設定
spec:
  rules: <転送ルールを設定>
```
#### kubectl get ing,svc,deployで確認
#### ADDRESSにIPアドレスが反映されるのには時間がかかる
#### minikube addons enable ingressでaddonを有効にしていないとADDRESSが空のまま更新されない
