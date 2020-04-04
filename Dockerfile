# Dockerfile for building Ansible,Kubectl,Helm and RKE image for Alpine 3, with as few additional software as possible.
#
# Version  1.0
#

FROM alpine:3.11.5

LABEL author="Don High"
LABEL maintainer="donghigh@yahoo.com"

ENV \
 HELM_VERSION=3.1.1 \
 KUBECTL_VERSION=1.17.0 \
 RKE_VERSION=1.0.6

RUN echo "===> Installing sudo, curl, bash to emulate normal OS behavior..."  && \
    apk --update add sudo curl bash make                              && \
    sed -i s,/bin/ash,/bin/bash, /etc/passwd && \
    \
    \
    echo "===> Adding Python runtime..."  && \
    apk --update add python3 py3-pip openssl ca-certificates    && \
    apk --update add --virtual build-dependencies \
                python3-dev libffi-dev openssl-dev build-base  && \
    pip3 install --upgrade pip cffi                            && \
    \
    \
    echo "===> Installing Ansible..."  && \
    pip3 install ansible               && \
    \
    \
    \
    echo "===> Installing Openshift..."  && \
    pip3 install openshift               && \
    \
    \
    echo "===> Installing handy tools (not absolutely required)..."  && \
    pip install --upgrade pycrypto pywinrm         && \
    apk --update add sshpass openssh-client rsync  && \
    \
    \
    echo "===> Removing package list..."  && \
    apk del build-dependencies            && \
    rm -rf /var/cache/apk/*               && \
    \
    \
    echo "===> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible                        && \
    echo 'localhost' > /etc/ansible/hosts && \
    \
    \
    echo "===> Installing Kubectl..."  && \
    curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl && \
    \
    \
    echo "===> Installing Helm..."  && \
    curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    | tar zx -C /usr/local/bin --strip-components=1 linux-amd64/helm && \
    \
    \
    echo "===> Installing Rancher RKE..."  && \
    curl -L -o /usr/local/bin/rke https://github.com/rancher/rke/releases/download/v${RKE_VERSION}/rke_linux-amd64 \
    && chmod +x /usr/local/bin/rke



#CMD [ "executable" ] ["bash", "-l"]




