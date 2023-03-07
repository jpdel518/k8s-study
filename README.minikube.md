# minikube

## minikubeはM1マックではファイルのマウントができない問題があるため利用すべきではない！！！！
##
##
#### minikubeのバージョン取得
```shell
minikube version
```
#### minikubeの起動
```shell
minikube start --vm-driver=hyperkit
```
#### Docker上でminikubeを起動する場合はServiceでnodePortで指定するポート番号を予め開けておく必要がある。
#### http://127.0.0.1:30000で通信できるようになる
#### ⚠︎⚠︎⚠︎ 嘘！これだとnodePortとポート番号一致していても通信できない！！！！！！
```shell
minikube start --vm-driver=docker --ports=127.0.0.1:30000:30000
```
#### minikubeの停止
```shell
minikube stop
```
#### minikubeの削除
```shell
minikube delete
```

#### 外部公開しているIPアドレスの取得（docker上にminikube立ち上げてるとportが空いていないので？外部から見れない。なぜか127.0.0.1からは見ることができる？）
```shell
minikube ip
```

#### 外部公開しているサービスのurlを取得
```shell
minikube service サービス名 --url
```

#### 外部公開しているサービスをブラウザで立ち上げる
```shell
minikube service サービス名
```

#### minikubeの状態取得
```shell
minikube status
```

#### addonの追加
```shell
minikube addons enable ingress
```

#### addonのリスト取得
```shell
minikube addons list
```
