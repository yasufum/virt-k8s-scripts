# virt-scripts

libvirtを用いた簡易k8s環境構築ツール。

## 使い方

### 雛形VMの作成

まず`virt-install`により雛形のVMイメージを1つ作成し、
マルチノード構成とする場合にはさらにこれを複製する。

雛形のVMを作成するには`virt-install.sh`を実行する。スペックを変更したい場合は
スクリプト内のパラメータを直接書き換える。

TODO: パラメータは他のスクリプトと共用しているので、外出しの設定ファイルとして分ける。

```sh
bash virt-install.sh
```

### クラスタノードVMの複製

雛形を元にVMを複製する。`clone-vms.sh`の`VMNAMES`にて各VMの名前を定義すると、
その台数分のVMが作成、起動される
(内部で`virt-clone`コマンドを用いている)。

```sh
bash clone-vms.sh
```

なお複製されたVMは起動されたときに全て同じIPアドレスを割り当てられてしまうため、
異なるアドレスとなるように設定を変更する。
原因はDHCPサーバーが（MACアドレスではなく）`machine-id`に対してIPアドレス割り当てを
行うためであり、
`virt-clone`コマンドではこの挙動を制御できないため手動での変更が必要。

参考: [libvirtのnetworkでDHCPが同じIPを振り続ける](https://qiita.com/sandopan65/items/75ca7e6563e86a7dfd8c)

VMにログインして以下のコマンドを実行し`machine-id`をクリアした後に再起動すると
新たに別の`machine-id`にて起動される。
sshではログインできないためconsole経由で操作する。

```sh
sudo virsh console ${VMNAME}
sudo bash -c "echo -n > /etc/machine-id"
sudo reboot
```

全てのVMで作業が完了したらvirshコマンドによりそれぞれのIPアドレスが異なることを確認する。
`virt-install.sh`で`NW_BRIDGE=virbr0`としている場合、
ネットワーク名は`default`となっている。

```sh
sudo virsh net-dhcp-leases default
```

### kubernetesクラスタのセットアップ

複製されたVMのそれぞれにおいて`install-kubeadm.sh`を実行する。

```sh
scp install-kubeadm.sh ${USER}@${IPADDR}:
ssh ${USER}@${IPADDR} bash install-kubeadm
```

このスクリプト実行が成功すると、`kubeadm init`によるクラスタ構築が可能となる。

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

masterでの`kubeadm init`完了時に出力される以下の様なコマンドを実行し
クラスタに参加させる。

```sh
$ sudo kubeadm join 10.10.10.240:6443 --token lu4wng.331v1crmk77ouua2 \
        --discovery-token-ca-cert-hash sha256:7070922f6dfb288bca91e364e197a06cd641e4cf57b181188624988b3f0e3e43

```

### CNIのインストール

ここでは[Cilium]()を用いる。

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
