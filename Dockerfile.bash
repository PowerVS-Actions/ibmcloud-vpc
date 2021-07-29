FROM ubuntu:20.04

LABEL authors="Rafael Sene - rpsene@br.ibm.com"

RUN apt-get update; apt-get -y install jq curl wget python3 python3-pip libpq-dev python-dev build-essential

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh; ibmcloud plugin install power-iaas; ibmcloud plugin install vpc-infrastructure

WORKDIR /output

COPY ./vpc.sh .

ENTRYPOINT ["/usr/bin/bash", "./vpc.sh"]