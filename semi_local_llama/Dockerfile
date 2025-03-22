FROM debian:stable-slim


RUN apt-get update && apt-get install -y gnupg software-properties-common wget curl unzip jq nginx procps
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null


RUN gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
tee /etc/apt/sources.list.d/hashicorp.list

RUN apt update
RUN apt-get install terraform packer -y
RUN mkdir -p /aws_install/ \ 
    cd /aws_install/ && \ 
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \ 
    unzip awscliv2.zip && \ 
    ./aws/install && \ 
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \ 
    dpkg -i session-manager-plugin.deb && \ 
    cd / && \ 
    rm -rf /aws_install

WORKDIR /terraform
# COPY . .
COPY nginx/default /etc/nginx/sites-available/
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]