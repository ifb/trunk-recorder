FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy AS base

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 605C66F00D6C9793 0E98404D386FA1D9 648ACFD622F3D138 && \
  echo deb http://http.us.debian.org/debian sid main >> /etc/apt/sources.list && \
  echo "Package: *" > /etc/apt/preferences && \
  echo "Pin: release o=Debian" >> /etc/apt/preferences && \
  echo "Pin-Priority: 1" >> /etc/apt/preferences && \
  echo "" >> /etc/apt/preferences && \
  echo "Package: librtlsdr*" >> /etc/apt/preferences && \
  echo "Pin: release o=Debian" >> /etc/apt/preferences && \
  echo "Pin-Priority: 1500" >> /etc/apt/preferences && \
  apt-get update && \
  apt-get -y upgrade && \
  export DEBIAN_FRONTEND=noninteractive && \
  apt-get install -y --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    docker.io \
    fdkaac \
    git \
    gnupg \
    gnuradio \
    gnuradio-dev \
    gr-funcube \
    gr-iqbal \
    libairspy-dev \
    libairspyhf-dev \
    libbladerf-dev \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libfreesrp-dev \
    libgmp-dev \
    libhackrf-dev \
    liborc-0.4-dev \
    libpthread-stubs0-dev \
    librtlsdr-dev \
    libsndfile1-dev \
    libsoapysdr-dev \
    libssl-dev \
    libuhd-dev \
    libusb-dev \
    libxtrx-dev \
    pkg-config \
    software-properties-common \
    sox \
    wget && \
  # Fix the error message level for SmartNet
  sed -i 's/log_level = debug/log_level = info/g' /etc/gnuradio/conf.d/gnuradio-runtime.conf && \
  # Compile gr-osmosdr ourselves so we can install the Airspy serial number patch
  cd /tmp && \
  git clone https://git.osmocom.org/gr-osmosdr && \
  cd gr-osmosdr && \
  wget -q -O - https://raw.githubusercontent.com/robotastic/trunk-recorder/master/lib/gr-osmosdr/airspy_source_c.cc.patch | git apply -v && \
  mkdir build && \
  cd build && \
  cmake -DENABLE_NONFREE=TRUE .. && \
  make -j$(nproc) && \
  make install && \
  ldconfig && \
  # compile trunk-recorder
  cd /tmp && \
  git clone --depth=1 https://github.com/robotastic/trunk-recorder.git && \
  cd trunk-recorder && \
  mkdir build && \
  cd build && \
  cmake ../ && \
  make -j$(nproc) && \
  make install && \
  # Clean up
  apt-get autoremove -y && \
  rm -rf /src/* /tmp/* /var/lib/apt/lists/*

WORKDIR /app

# GNURadio requires a place to store some files, can only be set via $HOME env var.
ENV HOME=/tmp

CMD trunk-recorder --config=/app/config.json
