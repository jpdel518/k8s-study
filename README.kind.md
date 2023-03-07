# kindチートシート
* kindとは： 「dockerコンテナノード」を使用したKubernetesクラスターをローカル環境に立ち上げるためのツール
* dockerコンテナノードとは： Kubernetesのノードとしてdockerコンテナを起動（仮想ノードとしてdockerコンテナを起動）
* dockerコンテナの中ではコンテナランタイム（コンテナやコンテナイメージを管理するソフトウェア）が起動
* コンテナランタイムがKubernetesのコンポーネントやアプリケーションを管理
* dockerコンテナの中ではkubeletが起動してコンテナインスタンスをノードと勘違いさせる
* Docker For DesktopのKubernetesとkindのKubernetesの違い
  * Docker For DesktopのKubernetesはシングルノード（masterノードしかいない。masterノードにリソースが追加される本番のkubernetes環境とは一致しない作り）
  * kindのKubernetesはマルチノードをサポートしている（masterノードとworkerノード両方が作られる）



## kindの基本
#### kindのインストール
```shell
brew install kind
```

#### クラスターの作成（シングルノード）
```shell
kind create cluster
```

#### kubectlの使用環境をkindに変更
```shell
kubectl cluster-info --context kind-kind
```

#### nodeの確認
```shell
kubectl get node -o wide
```

#### Clusterマニフェストファイルの作成
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
```

#### クラスターの作成（マルチノード）
```shell
kind create cluster --config=<クラスターマニフェストファイル>
```

#### 単純にPortForwardすればいいけど、、
#### 外部公開のためのport穴あけしたClusterマニフェストファイル（hostポートは8080で開けて、nodeポートは30080ポートを開けた）
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 8080
  - role: worker
  - role: worker
```

#### Serviceを作成する際に下記のようにcontainerポートをnodeポート30080に接続すると、localhost:8080/で接続できるようになる
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: web-nginx
  name: web-nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-nginx
  template:
    metadata:
      labels:
        app: web-nginx
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-nginx
spec:
  selector:
    app: web-nginx
  type: NodePort
  ports:
    - port: 80
      nodePort: 30080
```

#### クラスターの削除
```shell
kind delete cluster
```

#### ローカルのdockerコンテナイメージをkindクラスターにロード
```shell
kind load docker-image <イメージ名>
```
