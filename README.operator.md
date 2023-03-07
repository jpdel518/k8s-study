# Operatorチートシート
* Operatorとは： 制御ループ（制御対象を監視し、理想状態に近づける仕組み）を用いたKubernetesの拡張機能（監視対象を自分で定義）
* Operatorがなぜ必要か： ドメイン知識をコード化して、人間が手動作業しなくてはいけない事柄を減らす事が目的？
* CRD + CustomControllerの組み合わせで構成される
* Controllerとは： コントロールプレーンのコンポーネントの１つ。制御ループを実現。
* Controllerの役割： Kubernetes上に作成されたリソースの現実状態（APIサーバーを通してetcdから取得）を理想状態（APIサーバーを通してetcdから取得したKubernetesオブジェクトのspecフィールド）に近づけるために動く 
* CRD（CustomResourceDefinition）はAPIの拡張を行う。自分が作成するアプリケーション独自の理想状態を宣言的に表す拡張定義
* CRDをデプロイすることで、CustomResourceを取り扱うことができるようになる
* CustomControllerは作成されたCustomResourceのspec定義に従って、理想状態に近づける独自の管理ロジックを提供する
* CustomControllerはコントロールプレーン上ではなく、workerノード上にデプロイされる
* CustomControllerは基本的にDeploymentとしてデプロイされる


## Operatorのインストール（Postgres Operatorの使用）
```shell
# CRDの登録
kubectl create -f https://raw.githubusercontent.com/zalando/postgres-operator/master/manifests/operatorconfiguration.crd.yaml

# デフォルトの設定（ConfigurationParameters）を登録
# https://github.com/zalando/postgres-operator/blob/master/docs/reference/operator_parameters.md
kubectl create -f https://raw.githubusercontent.com/zalando/postgres-operator/master/manifests/postgresql-operator-default-configuration.yaml

# RBAC用のServiceAccount作成
kubectl create -f https://raw.githubusercontent.com/zalando/postgres-operator/master/manifests/operator-service-account-rbac.yaml

# Controllerの作成？
kubectl create -f ./operator/postgres-operator-with-crd.yaml

# カスタムリソースの操作をkubectlの代わりにUIでできるようになるリソース（オプショナル）
kubectl apply -k github.com/zalando/postgres-operator/ui/manifests
```

#### 作成したUIの確認
```shell
kubectl port-forward svc/postgres-operator-ui 8081:80

# localhost:8081
# CustomResourceを実際に作成したりできる
```

#### 登録されたAPI Resourceを確認
```shell
kubectl api-resources | grep zalan

#operatorconfigurations            opconfig     acid.zalan.do/v1                       true         OperatorConfiguration
#postgresqls                       pg           acid.zalan.do/v1                       true         postgresql
```

#### CRDの確認
```shell
# 一覧の取得
kubectl get customresourcedefinition

# 詳細（YAML）を確認
kubectl get customresourcedefinition postgresqls.acid.zalan.do -o yaml
```
