# 配置阿里镜像
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://eyzd1v97.mirror.aliyuncs.com"]
}
EOF
# 更新源
sudo yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
sudo yum clean all  
sudo yum makecache fast
sudo yum update
# 安装依赖包和docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 git vim gcc glibc-static telnet bridge-utils net-tools
sudo yum install docker-ce-17.12.0.ce -y
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# 添加vagrant到docker组中
sudo gpasswd -a vagrant docker # 把当前用户添加到docker组中
sudo systemctl restart docker.service # 重启docker服务

