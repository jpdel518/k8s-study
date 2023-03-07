# Helmチートシート

* HelmはKubernetes向けのパッケージマネージャ
* 主な機能は次の4つ 
  1. 「Chart」と呼ばれる設定ファイルに基づいた各種リソースの自動作成
  2. デプロイされたアプリケーションの削除・更新といった管理
  3. リポジトリで公開されているChartの検索やダウンロード、インストール
  4. Chartのパッケージ化やリポジトリへのアップロード
* Helmでは「stable」や「incubator」という名称の公式リポジトリが提供されているほか、サードパーティによるリポジトリも多く提供されている。
* リポジトリで公開されているChartはHelmHubで横断的に検索可能：https://artifacthub.io/
* Chartを使ってアプリケーションをデプロイすることを「install」。
* インストールされたアプリケーションのインスタンスは「release」。
##

## Helmコマンドの基礎
#### helmのインストール
```shell
brew install helm
```
#### リポジトリのローカルへの追加
```shell
helm repo add <ローカルで参照するリポジトリ名> <URL>
# 例：helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```
#### リポジトリ内のChartを更新
```shell
helm repo update
```
#### ローカルに追加されているリポジトリ内からChartの検索
```shell
helm search repo ＜検索するキーワード＞
```
#### 検索キーワードを省略すると、登録されているリポジトリで提供されているすべてのChartが出力される
```shell
helm search repo
```
#### アプリケーションのデプロイ（install）
```shell
helm install ＜Release名＞ ＜Chart名＞
# 例：helm install wordpress stable/wordpress
```
#### パラメータ（values.yaml）を付与したデプロイ
```shell
helm install <Release名> <Chart名> --set ＜パラメータ名＞=＜値＞, ＜パラメータ名＞=＜値＞
helm install <Release名> <Chart名> -f ＜YAMLファイル＞
```
#### どんなパラメータ（values.yaml）を付与できるのか確認
```shell
helm show values <Chart名>
# 例：helm show values prometheus-community/prometheus-blackbox-exporter
```
#### デプロイされたReleaseの一覧
```shell
helm list
```
#### デプロイされているアプリケーションのアップデート（パラメータの更新）
```shell
helm upgrade <Release名> <Chart名> --set ＜パラメータ名＞=＜値＞, ＜パラメータ名＞=＜値＞
helm upgrade <Release名> <Chart名> -f ＜YAMLファイル＞

# installされていなかったらインストール、installされていなければアップデートする方法
helm upgrade --install <Release名> <Chart名>
```
#### アップデート履歴の表示（リビジョンの取得）
```shell
helm history ＜Release名＞
# 例：helm history wordpress
```
#### Realseのロールバック
```shell
helm rollback ＜Release名＞ ＜リビジョン＞
# 例：helm rollback wordpress 1
```
#### デプロイされたアプリケーションの削除
```shell
helm uninstall ＜Release名＞
```
***


## Chartを知る
#### 既存Chartのダウンロード
```shell
helm pull <Chart名>
# 例：helm pull stable/wordpress
```
#### ダウンロードしたChartはtar/gzipで圧縮されているので解凍
```shell
ls
tar xvzf wordpress-8.1.2.tgz
```
#### ローカルに保存されたChartからデプロイを行う
```shell
helm install <Release名> <Path>
例：helm install wordpress ./wordpress
```

#### Chartのファイル構造
* Chart.yaml # Chartに関する各種メタデータなどが格納されている
* values.yaml # Chartのデフォルトパラメータ
* templates/ # ディレクトリ。Kubernetesのマニフェストファイルを生成するためのテンプレートファイルが格納。格納されているファイルはほぼマニフェストファイル。Chart特有の記載（パラメータ）がある。

#### Chart.yamlの構造
```yaml
apiVersion # 【必須】ChartのAPIバージョン。v2
name # 【必須】Chart名。
version # 【必須】Chartのバージョン。Semantic Versioning形式「Major番号.Minor番号.Patch番号」
type # Chartのタイプ（「application」もしくは「library」）デフォルトはapplication
dependencies # Chartが依存するChartについての情報をリスト形式で指定
```
#### Chart.ymlのdependencies
* 必要なアプリケーションをデプロイするための設定を別のChartに分離しておくことで、メンテナンス性や再利用性を向上させる目的
* dependenciesに指定されるChartのことを「Subchart（サブチャート）」とよぶ
* Chart.yamlがあるディレクトリ上で「helm dependency update」コマンドを実行すると、dependenciesの情報を元に対応するChartの最新版をダウンロードしてchartsディレクトリ内に格納してくれる
* 下記のような記述
```
 dependencies:
 - name: mariadb # 【必須】SubChartの名前
   version: 7.x.x # 【必須】SubChartのバージョン
   repository: https://kubernetes-charts.storage.googleapis.com/ # 【必須】SubChartのリポジトリのURL
   condition: mariadb.enabled # SubChartの有効/無効を切り替えるために使用する設定パラメータ名。親Chartでhelm installした際に一緒にデプロイするか。「--set」もしくは「-f <YAMLファイル>」で指定。デフォルトは有効。
   tags: # SubChartの有効/無効を切り替えるために使用するタグ名をリスト形式で指定。基本的にconditionと同じだが、複数指定できる点が異なる。複数のタグのうち、１つでもfalseが設定されればデプロイされない。
     - wordpress-database
   enabled: true # SubChartの有効/無効をbool形式（true/false）で指定
   import-values: # SubChartに渡す設定パラメータ。リスト形式で指定
     - xxxx
```

#### values.yaml
* Chartでどのようなパラメーターを利用できるかを指定する
* 「--set」オプションもしくは「-f ＜YAMLファイル＞」オプションでパラメーターを指定
* values.yamlはパラメーターのデフォルト値を記述したもの

#### values.scheme.yaml（ないこともある）
* values.yamlファイルで指定されたパラメーターについて、型や必須かどうかを指定することができる

#### templates内のファイル構造
* NOTES.txt # Chartのインストール時（「helm install」コマンドの実行時）にユーザーに表示する文章を記述
* _helpers.tpl # Chart内で複数回利用されるようなテンプレートや値を定義しておくヘルパーファイル
* その他 # deployment.yamlやingress.yaml, svc.yamlなどが格納されている

#### teplates内のYAMLファイルの記述
* values.yamlファイルや「helm install」コマンドの実行時に指定したパラメータに対し、「.Values」というオブジェクト経由でアクセスできる。
* たとえば「image.registry」というパラメータに対しては「.Values.image.registry」と指定することでその値を参照できる。
* パラメーター値意外
  * .Release.Name # helm installコマンドの引数で指定されたリリース名
  * .Release.Namespace # デプロイ先のK8sのnamespace
  * .Release.IsUpgrade # リリースを管理するサービス？？？
  * .Release.IsInstall # upgradeもしくはrollback時にtrue、そうでない場合はfalse
  * .Chart # Chart.yamlファイルの中身がそのまま格納されたオブジェクト
  * .Files # Chart内に含まれるファイルの一覧が格納されているオブジェクト
  * .Capabilities # 使用しているK8s環境の情報が格納されたオブジェクト
* 書き方はGo言語のテンプレート機能
```
 apiVersion: {{ template "wordpress.deployment.apiVersion" . }} # _helpers.tplから取得
 kind: Deployment
 metadata:
   name: {{ template "wordpress.fullname" . }} # _helpers.tplから取得
   labels:
     app: "{{ template "wordpress.fullname" . }}" # _helpers.tplから取得
     chart: "{{ template "wordpress.chart" . }}" # _helpers.tplから取得
     release: {{ .Release.Name | quote }}
     heritage: {{ .Release.Service | quote }}
 spec:
   selector:
     matchLabels:
       app: "{{ template "wordpress.fullname" . }}" # _helpers.tplから取得
       release: {{ .Release.Name | quote }}
   {{- if .Values.updateStrategy }}
   strategy: {{ toYaml .Values.updateStrategy | nindent 4 }}
   {{- end }}
   replicas: {{ .Values.replicaCount }}
   template:
     metadata:
       labels:
         app: "{{ template "wordpress.fullname" . }}"
         chart: "{{ template "wordpress.chart" . }}"
         release: {{ .Release.Name | quote }}
```
***


## annotationによるhook
#### テンプレートの「metadata.annotaions」プロパティで「helm.sh/hook」というプロパティを追加
#### そこで実行タイミングを指定する値を指定すると作成するタイミングを指定したリソースを定義できる
* pre-install # helm installコマンドを実行して、リソースを作成する前
* post-install # helm installを実行して、リソース作成完了後
* pre-delete # helm deleteを実行して、リソースを削除する前
* post-delete # helm deleteを実行して、リソースの削除完了後
* pre-upgrade # helm upgradeを実行して、リソースをアップグレードする前
* post-upgrade # helm upgradeを実行して、リソースのアップグレード完了後
* pre-rollback # helm rollbackを実行して、リソースをロールバックする前
* post-rollback	# helm rollbackを実行して、リソースのロールバック完了後
* test helm # test 実行時（つまりテスト用のリソースを作成してテストを実行することができる）
***


## CRD連携
#### 「crds」ディレクトリ内にCRDを作成するためのマニフェストファイルを格納
#### templatesディレクトリ以下に配置されているマニフェストファイルが処理される前に、直接YAML形式のKubernetesマニフェストとして処理される
***


## Chartの作成（Chart.yaml  charts  templates  values.yamlが用意されたディレクトリが作成される）
```shell
helm create ＜Chart名＞
```
***


## Chartの公開
#### Chartの公開に必要なものは下記
* 公開するChartの情報を含む「index.yaml」というインデックスファイル
* tar.gz形式で圧縮したChart
#### index.yamlの作成
```shell
helm repo index <公開したいChartのディレクトリ>
```
#### 圧縮したChartの作成
```shell
helm package <公開したいChartのディレクトリ>
```
#### index.yamlと圧縮したChartをWebサーバー上に公開
#### 公開したChartの利用
```shell
helm repo add <ローカルで参照するリポジトリ名> <URL>
```
