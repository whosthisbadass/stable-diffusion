FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime as base

COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1
ENV WEBUI_VERSION=01
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
    XDG_CACHE_HOME=/config/temp

RUN apt-get update -y -q=2 && \
    apt-get install -y -q=2 curl \
    wget \
    mc \
    bc \
    nano \
    rsync \
    libgl1-mesa-glx \
    libgoogle-perftools-dev \
    libcufft10 \
    cmake \
    build-essential \
#    python3-opencv \
    fonts-dejavu-core \
    jq \
    moreutils \
    aria2 \
    libglfw3-dev \
    libgles2-mesa-dev \
    pkg-config \
    libcairo2 \
    libcairo2-dev \
#    replace \
#    replace \
#    replace \
#    replace \
    ffmpeg \
    libopencv-dev \
    dotnet-sdk-8.0 \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

ADD parameters/* ${SD_INSTALL_DIR}/parameters/

RUN groupmod -g 1000 abc && \
    usermod -u 1000 abc

COPY --chown=abc:abc *.sh ./

RUN chmod +x /entry.sh

ENV XDG_CONFIG_HOME=/home/abc
ENV HOME=/home/abc
RUN mkdir /home/abc && \
    chown -R abc:abc /home/abc

RUN cd /tmp && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    chown -R abc:abc /root && \
    chown -R abc:abc ${SD_INSTALL_DIR} && \
    chown -R abc:abc /home/abc

EXPOSE 7860/tcp
