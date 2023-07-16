# awsチートシート
##
## aws cli, kubectlの設定
#### 1. aws cliをインストール（下記に従ってpkgをインストールする）
https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html

#### 2. AWSコンソール上からIAM Userを作成（プログラムから実行、既存ポリシーをアタッチでAdministratorAccessをアタッチする）→ ACCESS KEY IDとSECRET ACCESS KEYを取得   

#### 3. aws cliにIAM Userを紐付ける
```
aws configure --profile <profile名>

ACCESS KEY ID：取得した値
SECRET ACCESS KEY：取得した値
Default Region：ap-northeast-1
Default Output format：入力しなくて大丈夫
```

#### 4. aws cliで作成したプロファイルを確認（実行した結果、上で作成したIAMユーザが見えていれば成功！）
```
aws iam list-users --profile <profile名>
```

#### 5. kubectlのIAMユーザー設定
```
export AWS_PROFILE=<profile名>
```

#### 6. IAMユーザーが設定されているかを確認
```shell
aws sts get-caller-identity
```
***


## eksctlの設定
#### 1. eksctlをインストール（Githubにインストールコマンドのってる  https://github.com/weaveworks/eksctl）
```shell
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

#### 2. eksctlバージョン
```shell
eksctl version
```

#### 3. eksctlヘルプ
```shell
eksctl -h
```

#### 4. eksクラスターの作成
eksctlでは簡単にeksクラスターを作成することができる。（⚠︎⚠︎⚠︎︎ -pまたは--profileで明示的にaws cliのprofileを指定しないとdefaultのaws credentialsが使われるので注意）   

作成されるクラスターのDefault条件は下記。  
* 自動生成された名前のクラスター  
* m5.largeのEC2インスタンスによって構成された２台のworker nodes  
* EC2は公式AWS EKS AMI  
* リージョンはus-west-2  
* EKS用のVPCが作成される（Quotaに注意）  
```
eksctl create cluster
```

#### 5. カスタマイズする場合はcluster.yamlを記述
```shell
eksctl create cluster -f cluster.yaml
```

#### 6. お試しで作成した際のコマンドは下記（20~25分くらいかかる）
```shell
eksctl create cluster --name test-cluster --region ap-northeast-1 --profile eks_setup_user
```

#### 7. もしprofileが分からない場合：less ~/.aws/credentials
#### 8. AWSコンソール見ると下記が自動生成されている
* CloudFormation(AWSのリソースをコードで管理。イベントからどんなリソースを作成したか確認できる)
* vpc
* サブネット
* igw
* EC2
* EKSが自動で作成される。
***


## kubectlの設定
#### 1. kubeconfigに新しいクラスターを追加（追加したクラスターは↑で作成したtest-cluster）
```shell
aws eks update-kubeconfig --name test-cluster --profile eks_setup_user
```
#### 2. 更新したkubeconfigの確認
```
less ~/.kube/config

# 次を確認
# test-clusterのクラスターが作成されていること
# test-clusterのcontextが作成されていること。
# current_contextがtest-clusterになっていること

# ここから先はkubectlでaws上のリソースを操作することができるようになる
```

#### 試しにリソース作成してみる
⚠︎⚠︎⚠︎︎ ︎簡単にサービスを公開する流れ（実際にはセキュリティや可用性の設定を行う必要がある）
```shell
# deploymentを作成
kubectl create deployment nginx --image=nginx --replicas=3

# ローカルでは確認できなかったtypeがLoadBalancerのServiceを立ち上げることができる。
kubectl create service loadbalancer nginx --tcp=80

# ロードバランサーはAWSコンソール上のEC2のロードバランサーから立ち上がっていることを確認
# DNS名（http://a57ac91c64c9c4249aeeeeeec4a73fe2-1952700971.ap-northeast-1.elb.amazonaws.com）からpodに接続することができる

# リソースの削除
kubectl delete service nginx（ロードバランサーが削除されていることをAWSコンソール上から確認できる）
kubectl delete deploy nginx
```
***


## AWS Load Balancer
#### 1. AWS Load Balancer Controllerをインストールすることで、AWS上のロードバランサーを作成することができる。  
https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/

#### 2. cluster.yamlに下記を追記
```yaml
nodeGroup:
  iam:
    withAddonPolicies:
      awsLoadBalancerController: true
```
#### 3. cert-managerをインストールすることで、自動でSSL証明書を発行することができる。（前述のURLに詳細記載）

#### 4. AwsLoadBalancerController用のDeployment, Serviceを作成（前述のURLに詳細記載）
```shell
kubectl apply -f v2_4_0_full.yaml
```
#### 5. ingressを作成（eks_ingress.ymlを参照）
#### 6. クラスターの削除（5~10分くらいかかる）
```
eksctl delete cluster --name test-cluster --region ap-northeast-1 --profile eks_setup_user

# ⚠︎⚠︎⚠︎ ︎eksctlでclusterを削除してもLoadBalancerが残っているためそれに紐づいたVPCやネットワークインターフェイスなどは残ってしまう。
# ⚠︎⚠︎⚠︎ ︎LoadBalancerをAWSコンソール上から削除する必要がある。
# ⚠︎⚠︎⚠︎ ︎CloudFormationの削除もAWSコンソール上から実施
```

#### 7. NodeGroupの削除（NodeGroupはworker nodeのこと）コマンドが返ってきてから削除されるまで時間かかるのでkubectl get node で適宜確認する
```shell
eksctl delete nodegroup --cluster test-cluster --region ap-northeast-1 --profile eks_setup_user --name ng-1

# cluster.yamlに記述したNodeGroupを削除する場合は下記
eksctl delete nodegroup -f cluster.yaml --approve --profile eks_setup_user
```

#### 8. NodeGroupの作成（cluster.yamlに記述したNodeGroupを作成する場合は下記）
```shell
eksctl create nodegroup -f cluster.yaml --profile eks_setup_user
```
***


## IAMユーザーの削除
#### 1. ~/.aws/credentialsと~/.aws/configからeks_setup_userに関する行を削除
#### 2. AWSコンソール上のIAMユーザーページからeks_setup_userを削除
#### 3. ~/.kube/configのcurrent_contextをdocker-desktopに戻しておく
***


## Cluster Autoscaler
* kubernetesでnodeのオートスケールを行うためのツール  
* 各種クラウドプロバイダーの仕組みに沿ってオートスケーリングできるように実装されている  
* AWSではAuto Scaling Groupを利用している  

#### 1. cluster.yamlに下記を追記
```yaml
nodeGroups:
  # Node数の制限は下記を追記
  minSize: 1 # 最小ノード数
  maxSize: 3 # 最大ノード数
  desiredCapacity: 1 # 起動時のノード数
  # Policyのアタッチ
  iam:
    withAddonPolicies:
      autoScaler: true
```
#### 2. Cluster Autoscalerのインストール（https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws）
#### 3. 右記manifestを参考に修正： https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
#### 4. 作成したmanifestをapplyするとcluster auto scaleは適用
```shell
kubectl apply -f cluster-autoscaler-autodiscover.yaml
```
#### 5. pod数を増やすとNodeが増えることを確認できる
```shell
kubectl scale deployment nginx --replicas=10
```
***


## CloudWatch Container Insights
* CloudWatch Container Insightsでは、EKS上のアプリケーションのログやメトリクスを収集、集計、可視化することができる
* CloudWatchの機能で、ダッシュボード上でメトリクスを可視化したり、メトリクスやログに対してアラートを設定、通知したりできる

#### 1. cluster.yamlに下記を追記
```yaml
nodeGroups:
  iam:
    withAddonPolicies:
      cloudWatch: true
```
#### 2. CloudWatch Container Insightsのコマンドでのインストール（https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html）
#### 3. メトリクスの確認
1. AWSコンソール上でCloudWatch > インサイト > Container Insightsを選択
2. 「リソース」が選択されているセレクターを「パフォーマンスのモニタリング」に変更
3.  アラートを設定したいPodを選択（フィルター等を使用）
4. アラートを設定したいリソースのメニューボタンを押下し、「メトリクスで表示」を選択
5. アクションの中からベルマークを選択
6. 閾値を設定してアラートの作成をしていく
#### 4. ログの確認
1. AWSコンソール上でCloudWatch > ログ > ロググループを選択
2. ロググループの中に「/aws/containerinsights/<cluster名>/application」があるので選択 
3. ログを確認したいPod名を選択するとログが表示される
***

## ECRにイメージをpush
#### 1. アカウントIDを取得
```shell
aws sts get-caller-identity --profile eks_setup_user
```
#### 2. dockerイメージの作成
```shell
docker build -t <アカウントID>.dkr.ecr.ap-northeast-1.amazonaws.com/<イメージ名>:<タグ> .
```
#### 3. ECRへログイン
```shell
aws ecr get-login-password --region ap-northeast-1 --profile eks_setup_user | docker login --username AWS --password-stdin <アカウントID>.dkr.ecr.ap-northeast-1.amazonaws.com
```
#### 4. ECRにリポジトリを作成
```shell
aws ecr create-repository --repository-name <イメージ名> --region ap-northeast-1 --profile eks_setup_user
```
#### 5. ECRにイメージをpush
```shell
docker push <アカウントID>.dkr.ecr.ap-northeast-1.amazonaws.com/<イメージ名>:<タグ>
```
***

## EKSにアクセス可能なIAMユーザーの追加（対象のKubernetesClusterを作成したユーザー以外のIAMでアクセスできるようにしたい場合）
⚠︎⚠︎⚠︎ IAMにAdministratorAccessのポリシーをアタッチしていてもAWSリソースとは別に、Kubernetes側でもユーザーの認証機能があるため作成したIAMではアクセスできない
#### 1. IAMユーザーを作成しておく
#### 2. アクセスさせたいユーザーのARNを確認
```shell
aws iam list-users --profile eks_setup_user
```
#### 3. system:mastersグループにIAMユーザを追加している（⚠︎⚠︎⚠︎ アンチパターン）
```shell
eksctl create iamidentitymapping --cluster <cluster名> --arn <ユーザーのARN> --group system:masters --username <ユーザー名> --profile eks_setup_user
```
#### 4. IAMユーザーの切り替え（プロフィールを作成）
```shell
aws configure --profile <IAMユーザーのプロファイル名>
```
#### 5. 簡易版IAMユーザーの切り替え（./kube/configを丸ごと更新する場合。あんまり良くないやり方）
```shell
mv ~/.kube/config ~/.kube/config.bak
rm -rf ~/.kube/config
```
#### 5. IAMユーザーの切り替え （~/.kube/configの更新）
```shell
aws --profile <新しいIAM> eks --region ap-northeast-1 update-kubeconfig --name <cluster名>
```
#### 5. IAMユーザーの切り替え（環境変数による切り替え）
```shell
# Profileを切り替える
export AWS_PROFILE=<新しいIAM>
```
***

## 既存VPCにEKSクラスターアタッチさせる方法
#### 1. EKSで使用するVPCにはEKS特有の設定が必要になる
1. 異なるAZに、２つ以上の同じ種類のサブネット（Publicサブネット, Privateサブネット）がある
2. パブリックサブネットに対し、パブリックIPアドレスを自動割り当てにする（Publicサブネットはインターネットに接続できるのでセキュリティ的に少し危険。LoadBalancerなど外からアクセスされる必要があるものだけをおく。）
3. パブリックサブネットのタグにkubernetes.io/role/elb=1を付与する
4. プライベートサブネットのタグにkubernetes.io/role/internal-elb=1を付与する（Privateサブネットはインターネットに接続できないのでセキュリティ的に安全。基本的にはこちらにプログラム配置。NatGatewayはインターネットから接続される必要のないインスタンスについて、インターネットからの接続を遮断しつつ、自身はインターネットに接続を出来るようにするため。）
5. VPCとサブネットのタグにkubernetes.io/cluster/<cluster名>=sharedを付与する
#### 2. 作成したVPCにeks clusterを作成するにはcluster.yamlに下記を追記
```yaml
vpc:
  id:  #作成したVPC IDを入力。「""」で囲って文字列にする
    subnets:
      private:
        <Privateサブネットの名前-1>:
          id: <PrivateサブネットのID-1> # PrivateサブネットのID-1。「""」で囲って文字列にする
        <Privateサブネットの名前-2>:
          id: <PrivateサブネットのID-2> # PrivateサブネットのID-2。「""」で囲って文字列にする
      public:
        <Publicサブネットの名前-1>:
          id: <PublicサブネットのID-1> # PublicサブネットのID-1。「""」で囲って文字列にする
        <Publicサブネットの名前-2>:
          id: <PublicサブネットのID-2> # PublicサブネットのID-2。「""」で囲って文字列にする

nodeGroups:
  privateNetworking: true # 基本的なNodeはPrivateサブネットに配置する
```
実際にPrivateサブネットでNodeが起動しているかを確認するには、AWSコンソールのAutoScaleからkubernetes用のAutoScaleグループを選択してネットワーク内のサブネットにPrivateサブネットが指定されているかで確認できる。  
⚠︎⚠︎⚠︎ NatGatewayは使用時間に応じて課金されるので長時間使用しない場合は削除しておくこと, InternetGatewayも条件によっては課金されるので同様に削除しておくこと。必要になった際に再作成してルートテーブルに紐づければ良い。  
***


## EKSのアップデート（全部で１時間くらいかかる）
* Kubernetesでは3~4ヶ月に1回の頻度でマイナーバージョンがアップデートされる。
* EKSにおいても同様である。
* EKS利用者はバージョンに追従するために定期的にアップデートを行う必要がある。
* EKSをアップデートするには、クラスタとノードそれぞれをアップデートする。
* EKSではインプレースアップデート（依存環境をアップデートするやり方）がサポートされている。この方法では１マイナーバージョンずつアップデートを行う必要がある。
* インプレースアップデートを行うために設定する「PodDisruptionBudget」とは ノードのアップデートなどで意図的にノードを終了させる際に、最低限起動しておくべきPodの数を保証できる機能
* ノード終了時にPodの数を0にすることを防ぐことができるので、インプレースアップデートによる一時的なダウンの影響を極力抑える。 

#### 1. インプレースアップデートの前に、クラスターオートスケールを無効化させる
```shell
kubectl scale deployment cluster-autoscaler -n kube-system --replicas 0
```
#### 2. ノードを２つ起動しておく
```shell
eksctl scale nodegroup --cluster eks-cluster --nodes 2 --name eks-ng --profile eks_setup_user
```
#### 3. Podを複数起動しておく
```shell
kubectl scale deployment nginx replicas 2
```
#### 4. PodDisruptionBudget manifestファイル作成
```shell
kubectl create poddisruptionbudget --dry-run=client -o yaml nginx --selector "app=nginx" --min-available 1 > ./pod_disruption_budget/nginx-pdb.yaml
```
#### 5. PodDisruptionBudget作成
```shell
kubectl apply -f ./pod_disruption_budget/nginx-pdb.yaml
```
#### 6. PodDisruptionBudgetのリソース確認
```shell
kubectl get poddisruptionbudgets.policy
```
#### 7. クラスタのアップデート
```shell
eksctl upgrade cluster --name eks-cluster --approve --profile eks_setup_user
```
#### 8. AddOn（EKSを起動した際にNodeにデフォルトで起動されているプログラム）のアップデート
```shell
eksctl utils update-aws-node --cluster eks-cluster --approve --profile eks_setup_user
```
#### 9.CoreDNSのアップデート
```shell
eksctl utils update-coredns --cluster eks-cluster --approve --profile eks_setup_user
```
#### 10. KubeProxyのアップデート
```shell
eksctl utils update-kube-proxy --cluster eks-cluster --approve --profile eks_setup_user
```
#### 11. ClusterAutoScalerのアップデート
```shell
cluster-autoscaler-autodiscovery.yamlファイルのDeploymentのcontainer.imageのバージョンをKubernetes Serverバージョンに合わせる

+

kubectl apply -f cluster-autoscaler-autodiscovery.yaml
```
#### 12. NodeGroupのアップデート
```shell
cluster.yamlのバージョンをKubernetes Serverバージョンに合わせる 

+

nodeGroups.nameを変更する（バージョンがわかるようにするとbetter）

+
 
eksctl create nodegroup -f ./eks/cluster.yaml --profile eks_setup_user
```
#### 13. 古いNodeGroupの削除
```shell
eksctl delete nodegroup -f ./eks/cluster.yaml --only-missing --approve --profile eks_setup_user
```
#### 14. 無効化していたClusterAutoScalerの有効化
```
kubectl scale deployment cluster-autoscaler -n kube-system --replicas 1
```
#### 15. Clusterのバージョン確認
```
kubectl version --short
```
#### 16. Nodeのバージョン確認
```
kubectl get node
```
***


# EKSクラスターにユーザーを追加する（⚠︎⚠︎⚠︎ アンチパターン）
この方法は簡単だが、管理者権限を与えてしまう  
EKSクラスターにユーザーを追加するには、ユーザーのIAMユーザーを作成し、そのIAMユーザーにEKSクラスターにアクセスするための権限を付与する。
#### 1. AWSコンソールからIAMユーザーを作成する（K8sクラスターにアクセスするだけなら特にポリシーのアタッチは必要ない）
#### 2. IAMユーザーにEKSクラスターにアクセスするための権限を付与する
```shell
kubectl edit -n kube-system configmap/aws-auth

# 以下の記述を追記
mapUsers: |
      - groups:
        - system:masters  # K8s User Group
        userarn: arn:aws:iam::111122223333:user/eks-viewer   # AWS IAM user
        username: this-aws-iam-user-name-will-have-root-access # K8s User Name（なんでもオッケー。わかりやすい名前つける）
```
#### 3. 反映を確認
```shell
kubectl get -n kube-system configmap/aws-auth -o yaml
```
#### 4. ユーザーを切り替えて確認
```shell
# Profileを切り替える
export AWS_PROFILE=<追加したユーザー>
# 権限の確認
kubectl get pod
kubectl auth can-i create deployments
kubectl auth can-i delete deployments
kubectl auth can-i create clusterrole
kubectl auth can-i create pod --as=system:anonymous
```
#### system:mastersグループに所属しているユーザーは、K8sクラスターの全てのリソースに対して操作が可能（ルートユーザーを作っているようなものなので非推奨）
***


# EKSクラスターに追加したユーザーの権限を制限する（RBAC）
やる事は下記
* 新しいclusterrolebindingを作成する
* 既存のclusterroleに対して、新しいclusterrolebindingを作成する（clusterroleから作成することも可能）
#### 1. 既存のclusterroleの確認
```shell
kubectl get clusterrole -n kube-system
```
#### 2. viewのclusterroleの詳細を確認（get, list, watchの権限しかないことが確認できる）
```shell
kubectl describe clusterrole view -n kube-system
```
#### 3. clusterroleであるviewを元にclusterrolebindingの作成
```shell
kubectl create clusterrolebinding <作成するclusterrolebindingの名前> --clusterrole=view --group=<viewロールをbindする新しいグループ名> --dry-run=client -o yaml > <作成するclusterrolebindingの名前>.yaml
# 例： kubectl create clusterrolebinding system:viewer --clusterrole=view --group=eks-viewer --dry-run=client -o yaml > system-viewer.yaml
```
#### 4. 作成したclusterrolebindingのyamlファイルをapply
```shell
kubectl apply -f <作成したclusterrolebindingの名前>.yaml
# 例： kubectl apply -f system-viewer.yaml
```
#### 5. clusterrolebindingの確認
```shell
kubectl get clusterrolebinding
```
#### 6. 作成したclusterrolebindingの詳細を確認
```shell
kubectl describe clusterrolebinding <作成したclusterrolebindingの名前>
```
#### 7. 作成したグループをユーザへ付与するために、aws-authのconfigmapを編集
```shell
kubectl edit -n kube-system configmap/aws-auth

# 以下の記述を追記
mapUsers: |
    - groups:
        - system:viewer  # K8s User Group
        userarn: arn:aws:iam::111122223333:user/eks-viewer   # AWS IAM user
        username: this-aws-iam-user-name-will-have-root-access # K8s User Name（なんでもオッケー。わかりやすい名前つける）
```

#### 8. 反映を確認
```shell
kubectl get -n kube-system configmap/aws-auth -o yaml
```
#### 9. ユーザーを切り替えて確認
```shell
# ユーザーの切り替え
export AWS_PROFILE=<追加したユーザー>
# 権限の確認
kubectl get pod
kubectl auth can-i create deployments # noになるはず
kubectl auth can-i delete deployments # noになるはず
kubectl auth can-i create clusterrole # noになるはず
```

#### 実際に本番運用する場合にはAWSコンソール上でROLEを作成し、そのROLEにEKSクラスターにアクセスするための権限を付与することが推奨されている
#### ROLEは最大セッション時間が決まっており、その期間のみ有効なアクセスキー、シークレットキーが生成される
#### ユーザーからROLEへの切り替えはAWSコンソール上の右上のアカウント名をクリック->「ロールの切り替え」から実行する。ただしこっちだとアクセスキーとかシークレットキー取れないかも（参考： https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_roles_use_switch-role-console.html）
#### もしくは、下記のようにaws-cliを使用する（参考： https://www.karakaram.com/assuming-iam-role-using-aws-cli/）
```shell
aws sts assume-role --role-arn <ROLEのARN> --role-session-name eks-viewer --duration-seconds 3600
```
#### アクセスキーやシークレットキーを取得することができるので、それらを環境変数に設定する
```shell
export AWS_ACCESS_KEY_ID=<アクセスキー>
export AWS_SECRET_ACCESS_KEY=<シークレットキー>
```
#### 以下のように、aws-authのconfigmapを編集することで、EKSクラスターにアクセスするための権限を付与することができる
```shell
mapRoles: |
  - groups:
    - system:bootstrappers
    - system:nodes
    rolearn: arn:aws:iam::xxxxxxxx:role/eksctl-eks-from-eksctl-nodegroup-NodeInstanceRole-R3EFEQC9U6U
    username: system:node:{{EC2PrivateDNSName}}
  - groups:  # <----- new IAM role entry
    - system:viewer  # <----- K8s User Group
    rolearn: arn:aws:iam::xxxxxxxx:role/eks-viewer-role  # AWS IAM role
    username: eks-viewer
```
#### ROLEを元に戻すときは、下記のようにする
```shell
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
```
***

## IRSA
#### OIDCプロバイダーを作成し、クラスターにリンクさせる必要がある。
#### cluster.yamlに下記を追記して実行
```yaml
iam:
  withOIDC: true
```
#### OIDC ProviderがEKSクラスターにリンクされたかを確認（arnの情報が出力されればOK）
```shell
oidc_id=$(aws eks describe-cluster --name eks-cluster --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id
```
#### IAMServiceAccountの作成（EKSのk8sクラスター内にServiceAccountが作られる＋AWS IAMロールにARNで指定したポリシーがアタッチされた新しいロールが作成される）
```shell
eksctl create iamserviceaccount \
  --cluster=eks-cluster \
  --namespace=kube-system \
  --name=aws-ebs-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --profile eks_setup_user
```
#### IAMServiceAccountの確認
#### AWSコンソールのIAM > Roleから対象Policyが付与されたRoleが作成されていることを確認
#### cluster上にServiceAccountが作成されていることを確認
```shell
kubectl describe serviceaccount aws-ebs-controller
```
#### Deploymentの作成で作成したServiceAccountを指定
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    run: irsa-iam-test
  name: irsa-iam-test
spec:
  replicas: 1
  selector:
    matchLabels:
      run: irsa-iam-test
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        run: irsa-iam-test
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - sleep 500
        image: amazon/aws-cli
        name: irsa-iam-test
        resources: {}
      serviceAccountName: aws-ebs-controller
```
#### Deploymentの作成
```shell
kubectl apply -f deployment_irsa_test.yaml
```
#### コンテナ内にシェルで接続し、IAM RoleをAssumeして実行する事ができるか確認
```shell
kubectl exec -it irsa-iam-test-cf8d66797-kx2s2  sh

# 環境変数を表示（AWS_ROLE_ARNとAWS_WEB_IDENTITY_TOKEN_FILEが設定されている）
sh-4.2# env

AWS_ROLE_ARN=arn:aws:iam::xxxxxx:role/eksctl-eks-from-eksctl-addon-iamserviceaccou-Role1-1S8X0CMRPPPLY  # <--- IAM role ARNがインジェクトされている
...
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token # <---- IAM roleをAssumeするためのJWT token

# awsバージョンをチェック
sh-4.2# aws --version

# 例えばS3のLISTパーミッションを持ったRoleをAssumeしているなら下記を実行
sh-4.2# aws s3 ls
```
