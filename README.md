# virt-scripts

libvirtを用いた簡易k8s環境構築ツール。

## 使い方

### 雛形VMの作成

まず`virt-install`コマンドを用いて雛形のVMイメージを1つ作成する。
さらにマルチノード構成にする場合にはこのVMイメージを複製する。

雛形のVMは`virt-install.sh`から作成できる。
なおスペックは`vars.sh`にて定義されているため、
変更する場合はこのファイルを編集する。

```sh
bash virt-install.sh
```

`virt-install.sh`を実行するとVMが起動されOSインストール画面に移行するので、
メニューに従って操作を行う。
インストールが完了すると、`vars.sh`の`ORIG_VMNAME`で定義された
名称のVMが作成されていることが分かる。

```sh
ORIG_VMNAME=ubuntu-orig
```

なおHDD容量が指定したサイズより小さい場合があるため、
ログインして論理ボリュームを拡張する。

```sh
sudo virsh console ubuntu-orig
sudo vgextend ubuntu-vg /dev/sdb  # 不要の場合もある
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

次のセクションでVMを複製する前に、雛形VMをシャットダウンする必要がある。

```sh
sudo virsh shutdown ubuntu-orig
```

### クラスタノードVMの複製

雛形を元にVMを複製する。`clone-vms.sh`の`VMNAMES`にて各VMの名前を定義すると、
その台数分のVMが作成、起動される
(内部で`virt-clone`コマンドを用いている)。

```sh
bash clone-vms.sh
```

なお複製されたVMは起動されたときに全て同じIPアドレスを割り当てられてしまうため、
（正しく）異なるアドレスとなるように設定を変更する。
この原因はDHCPサーバーが（MACアドレスではなく）`machine-id`に対してIPアドレス割り当てを
行うためであり、
`virt-clone`コマンドではこの挙動を制御できないため手動での変更が必要となる。

参考: [libvirtのnetworkでDHCPが同じIPを振り続ける](https://qiita.com/sandopan65/items/75ca7e6563e86a7dfd8c)

VMにログインして以下のコマンドを実行し`machine-id`をクリアした後に再起動すると
新たに別の`machine-id`にて起動される。

またホスト名も全て同じになっているため`hostnamectl`コマンドにて任意の名前に変更しておく。

sshではログインできないためconsole経由で操作する。

```sh
sudo virsh console ${VMNAME}
sudo bash -c "echo -n > /etc/machine-id"
sudo hostnamectl hostname HOSTNAME
sudo reboot  # IPアドレスを再設定するため一度再起動する
```

全てのVMで作業が完了したら、
`virsh net-dhcp-leases`コマンドによりそれぞれのノードのIPアドレスが
異なっていることが確認できる（ただし値が上手く反映されていないこともある）。
コマンドの最後にネットワーク名を指定する必要があるが、
`virt-install.sh`で`NW_BRIDGE=virbr0`としている場合
ネットワーク名は`default`となっている。

```sh
sudo virsh net-dhcp-leases default
```

### kubernetesクラスタのセットアップ

複製されたVMのそれぞれにおいて`install-kubeadm.sh`を実行する
（このスクリプトは
[ここ](https://gist.githubusercontent.com/rokuosan/cc9a243fb7a2f43ff6bab40b9fc06f98/raw/0f385980be15795c73fa7077db468e4947c6b19b/install.sh)
を参考に作成しました）。

```sh
scp install-kubeadm.sh ${USER}@${IPADDR}:
ssh ${USER}@${IPADDR} bash install-kubeadm
```

このスクリプト実行が成功すると、
次に`kubeadm init`によるクラスタ構築が可能となる。
masterノード、workerノードそれぞれで次の操作を行う。

masterノード:

```sh
ssh ${USER}@${IPADDR}
sudo kubeadm init --control-plane-endpoint=${IPADDR}

# kubeconfigの設定も忘れず行う
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

workerノード:

masterでの`kubeadm init`完了時に出力されるトークンなどの情報を利用して、
workerノードで以下のように`kubeadm join`を実行しクラスタに参加させる。

```sh
$ sudo kubeadm join 10.10.10.240:6443 --token lu4wng.331v1crmk77ouua2 \
        --discovery-token-ca-cert-hash sha256:7070922f6dfb288bca91e364e197a06cd641e4cf57b181188624988b3f0e3e43

```

### CNIのインストール

ここでは[Cilium](https://cilium.io/)を用いる。

```sh
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
curl -L https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz
```

```sh
cilium install
```

ciliumのバージョンを確認してインストールしたい場合は以下の様にする。

```sh
cilium version
cilium install --version 1.14.2
```

### VMの一括削除

もし複製されたVMを一括消去したい場合は`remove-vms.sh`にて停止、削除を行う。

```sh
bash remove-vms.sh
```
