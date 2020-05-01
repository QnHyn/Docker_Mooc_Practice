# 配置阿里镜像
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://registry.cn-hangzhou.aliyuncs.com"]
}
EOF
# 更新源
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  
sudo yum clean all  
sudo yum makecache fast
sudo yum update


# 安装依赖包和docker
sudo yum install -y yum-utils lvm2 git vim gcc glibc-static telnet bridge-utils net-tools bind-utils wget device-mapper-persistent-data nfs-utils
sudo yum install -y docker-ce-19.03.8 docker-ce-cli-19.03.8 containerd.io


# 添加vagrant到docker组中
sudo gpasswd -a vagrant docker # 把当前用户添加到docker组中
sudo systemctl restart docker


# 配置K8S的yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


# 也可以尝试国内的源 http://ljchen.net/2018/10/23/%E5%9F%BA%E4%BA%8E%E9%98%BF%E9%87%8C%E4%BA%91%E9%95%9C%E5%83%8F%E7%AB%99%E5%AE%89%E8%A3%85kubernetes/
sudo setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# install kubeadm, kubectl, and kubelet.
sudo yum install -y kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0


cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
EOF
sudo sysctl --system

sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

# 修改docker Cgroup Driver为systemd
sudo sed -i "s#^ExecStart=/usr/bin/dockerd.*#ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --exec-opt native.cgroupdriver=systemd#g" /usr/lib/systemd/system/docker.service
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable kubelet
sudo systemctl restart kubelet


# 拉去镜像
# 运行脚本如下 镜像到了阿里云的杭州机房的容器仓库里，拉取还是比较快的
echo ""
echo "=========================================================="
echo "Pull Kubernetes v1.18.0 Images from aliyuncs.com ......"
echo "=========================================================="
echo ""

MY_REGISTRY=registry.cn-hangzhou.aliyuncs.com/openthings

## 拉取镜像
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-apiserver:v1.18.0
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-controller-manager:v1.18.0
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-scheduler:v1.18.0
docker pull ${MY_REGISTRY}/k8s-gcr-io-kube-proxy:v1.18.0
docker pull ${MY_REGISTRY}/k8s-gcr-io-etcd:3.4.3-0
docker pull ${MY_REGISTRY}/k8s-gcr-io-pause:3.2
docker pull ${MY_REGISTRY}/k8s-gcr-io-coredns:1.6.7

## 添加Tag
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-apiserver:v1.18.0 k8s.gcr.io/kube-apiserver:v1.18.0
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-scheduler:v1.18.0 k8s.gcr.io/kube-scheduler:v1.18.0
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-controller-manager:v1.18.0 k8s.gcr.io/kube-controller-manager:v1.18.0
docker tag ${MY_REGISTRY}/k8s-gcr-io-kube-proxy:v1.18.0 k8s.gcr.io/kube-proxy:v1.18.0
docker tag ${MY_REGISTRY}/k8s-gcr-io-etcd:3.4.3-0 k8s.gcr.io/etcd:3.4.3-0
docker tag ${MY_REGISTRY}/k8s-gcr-io-pause:3.2 k8s.gcr.io/pause:3.2
docker tag ${MY_REGISTRY}/k8s-gcr-io-coredns:1.6.7 k8s.gcr.io/coredns:1.6.7

echo ""
echo "=========================================================="
echo "Pull Kubernetes v1.18.0 Images FINISHED."
echo "into registry.cn-hangzhou.aliyuncs.com/openthings, "
echo "           by openthings@https://my.oschina.net/u/2306127."
echo "=========================================================="

echo ""

## 修改源
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://eyzd1v97.mirror.aliyuncs.com"]
}
EOF

sudo systemctl restart docker
sudo systemctl restart kubelet
#docker pull weaveworks/weave-npc:2.6.2
#docker pull weaveworks/weave-kube:2.6.2
#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"








