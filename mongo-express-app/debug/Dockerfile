FROM centos:7

COPY . /tmp/debug

RUN  \
# Install MongoDB shell, tools.
mv /tmp/debug/mongodb-org-4.0.repo /etc/yum.repos.d; \
yum install -y mongodb-org-shell-4.0.5 mongodb-org-tools-4.0.5; \
#yum install wget \
#wget https://fastdl.mongodb.org/linux/mongodb-shell-linux-x86_64-rhel70-4.0.28.tgz \
#tar -zxvf mongodb-shell-linux-x86_64-rhel70-4.0.28.tgz \
#mv mongodb-linux-x86_64-rhel70-4.0.28/bin/mongo /usr/local/bin/ \
# Install ip , ifconfig command.
yum install -y iproute net-tools; \
# Install jq
curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64; \
chmod +x /usr/local/bin/jq; \
# Delete cache files.
yum clean all;
