FROM debian:trixie-20260518-slim

ARG DOCKER_PLATFORM_CPU_ARCHITECTURE

ENV KUBECTL_VERSION=1.34.8
ENV AGE_VERSION=1.3.1
ENV YQ4_VERSION=4.53.2

ENV KUBECTL_SHA512_amd64=84b27c01cc7b03ec20b9be5a4a10d4344989b94c65b6cd16ee61f780755a2a9474428d4b44e3951ba7b92da06d5bb1b5e37e3adb3a4813f7f84b12a65d3436c1
ENV KUBECTL_SHA512_arm64=9429fc978f5d81586d193b0d22e1fd8503ee5e3b8bc6675e6c872a211e28519e00627ed270bec4798f5ca3457e1a5cccd1199eac7aced8d694fdad1bb03fd9c3
ENV AGE_SHA512_amd64=425e3f7bcd3bee2ac5e356d45f86b208a15a4ddf0c5fe512047fbe08d77a4b957b3c5db699c49c281bd20f8bc1e76ab93753ab99593ff747742808769dccc070
ENV AGE_SHA512_arm64=7f7920f5f199e46b568bec464e870fd61baae67140ddb5ed104c458ee89cdfbb7c4f48873cfa73c1218dc2a023227e7bacf635480e678a480aeac04e0f330b1f
ENV YQ4_SHA512_amd64=95d5755266c77627e6facc9b443174f17b94ab3b2c427b860232c7b79f56f1f534ed2e0b5a79b41dfcc8246a05db987d9aeb39913f36563784258ebe1d6be763
ENV YQ4_SHA512_arm64=a4ffc2dc4f8c1c43e1ee687205248d361a16d0a0c6a7ceab17c443746b9d5d014dbccff5c34883bca9115979037ee2d992aa0e6d9a485a7184136df275f6729f

LABEL base.project.name="${ProjectName}"
LABEL base.version="${Version}"
LABEL base.docker.tag="${DockerTag}"
LABEL base.docker.image.name="${DockerImageName}"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get dist-upgrade -y
RUN apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    debianutils \
    dnsutils \
    gnupg \
    iputils-ping \
    less \
    netcat-openbsd \
    openssl \
    procps \
    time \
    unzip \
    -y --no-install-recommends
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list
RUN apt-get update
RUN apt-get install google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin -y --no-install-recommends
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

RUN curl -sLo /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${DOCKER_PLATFORM_CPU_ARCHITECTURE}/kubectl"
RUN eval CHECKSUM=\$KUBECTL_SHA512_${DOCKER_PLATFORM_CPU_ARCHITECTURE} && \
    echo "${CHECKSUM}  /usr/local/bin/kubectl" | sha512sum -c -
RUN chmod +x /usr/local/bin/kubectl

RUN curl -sLo /tmp/age.tar.gz "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${DOCKER_PLATFORM_CPU_ARCHITECTURE}.tar.gz"
RUN eval CHECKSUM=\$AGE_SHA512_${DOCKER_PLATFORM_CPU_ARCHITECTURE} && \
    echo "${CHECKSUM}  /tmp/age.tar.gz" | sha512sum -c -
RUN tar xzf /tmp/age.tar.gz -C /usr/local/bin --strip-components=1 age/age age/age-keygen
RUN rm /tmp/age.tar.gz

RUN curl -sLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ4_VERSION}/yq_linux_${DOCKER_PLATFORM_CPU_ARCHITECTURE}"
RUN eval CHECKSUM=\$YQ4_SHA512_${DOCKER_PLATFORM_CPU_ARCHITECTURE} && \
    echo "${CHECKSUM}  /usr/local/bin/yq" | sha512sum -c -
RUN chmod +x /usr/local/bin/yq

RUN mkdir -p /kd/bin /kd/work /kd/secrets /kd/gke /kd/manifests
ENV PATH="/kd/bin:${PATH}"
ENV CLUSTER_SCRIPT_DIR=/kd/bin
ENV CLUSTER_MANIFEST_DIR=/kd/manifests
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True
WORKDIR /kd

ENV KAPTAIN_USER_ID=4242
RUN mkdir -p /home/kaptain
RUN groupadd -g ${KAPTAIN_USER_ID} kaptain
RUN useradd -u ${KAPTAIN_USER_ID} -g kaptain -d /home/kaptain -s /bin/bash kaptain
RUN chown kaptain:kaptain /home/kaptain /kd/work /kd/gke /kd/manifests
# Final consumer images must select USER 4242:4242 after assembly.

COPY scripts/* /kd/bin/
RUN chmod +x /kd/bin/*
