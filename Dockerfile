FROM ubuntu:20.04

# Suppress time zone questions during build
ENV TZ=Asia/Shanghai

RUN printf '%s\n' \
  '# USTC Ubuntu mirrors' \
  '# 中国科学技术大学开源软件镜像站' \
  'deb http://mirrors.ustc.edu.cn/ubuntu/ focal main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu/ focal-updates main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu/ focal-backports main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu/ focal-security main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu-ports/ focal main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu-ports/ focal-updates main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu-ports/ focal-backports main restricted universe multiverse' \
  'deb http://mirrors.ustc.edu.cn/ubuntu-ports/ focal-security main restricted universe multiverse' \
  > /etc/apt/sources.list

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  && echo $TZ > /etc/timezone \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
# Packages sorted alphabetically
    asciidoc \
    astyle \
    autoconf \
    bc \
    bison \
    build-essential \
    ccache \
    cmake \
    cmake-curses-gui \
    cpio \
    cryptsetup-bin \
    curl \
    dblatex \
    default-jre \
    doxygen \
    file \
    flex \
    gdisk \
    genext2fs \
    gettext-base \
    git \
    graphviz \
    gzip \
    help2man \
    iproute2 \
    iputils-ping \
    jq \
    libacl1-dev \
    libelf-dev \
    libglade2-0 \
    libgtk2.0-0 \
    libjson-c-dev \
    libmpc-dev \
    libncurses5 \
    libncurses5-dev \
    libncursesw5-dev \
    libpcap-dev \
    libssl-dev \
    libtool \
    locales \
    m4 \
    mtd-utils \
    parted \
    patchelf \
    python3 \
    python3-pip \
    rsync \
    ruby-full \
    ruby-jira \
    ruby-parslet \
    squashfs-tools \
    sudo \
    texinfo \
    tree \
    u-boot-tools \
    udev \
    unifdef \
    util-linux \
    vim \
    w3m \
    wget \
    xz-utils \
    zlib1g-dev \
    zlibc \
# Cleanup
  && rm -rf /var/lib/apt/lists/* \
# Generate en_US.UTF-8 locale
  && locale-gen en_US.UTF-8 \
# Update locate to en_US.UTF-8
  && update-locale LANG=en_US.UTF-8 LANGUAGE=en \
# git needs a user
  && git config --system user.email "br@example.com" && git config --system user.name "Build Root" \
# TBD Use bundler instead?
  && gem install nokogiri -v 1.15.4 \
  && gem install minitar -v 0.12.1 \
  && gem install asciidoctor slop optimist \
  && gem install json_schemer \
# Enable use of python command
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 100 \
# Install python-matplotlib
  && python -m pip install matplotlib \
# Support Microsemi version
  && ln -s /usr/local/bin/mchp-install-pkg /usr/local/bin/mscc-install-pkg

# Install npm, node and the antora packages
# Node version must be an LTS.
ENV NVM_VERSION=0.39.5
ENV NODE_VERSION=18.17.1
ENV NVM_DIR=/nvm
WORKDIR /nvm
RUN mkdir -p /nvm/.npm /nvm/.cache
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
ENV PATH="/nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
RUN node -e "fs.writeFileSync('package.json', '{}')"
RUN npm i -g -D -E @antora/cli@3.1 @antora/site-generator@3.1 @antora/lunr-extension
# Ignore requests to update npm
COPY ./npmrc /nvm/.npmrc

# Set locale
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8'

# buildroot-layer needs this for installing missing toolchains
COPY ./mchp-install-pkg /usr/local/bin

# Add simple grid client as this is needed to dispatch sub-jobs in the internal
# mchp building environment
COPY ./SimpleGridClient /usr/local/bin

RUN git clone https://github.com/matthiasmiller/javascriptlint.git /tmp/jsl
RUN cd /tmp/jsl; git checkout 5a245b453d68228878d6c283e12ef35327c45279; cd ./src; make -f Makefile.ref; cp ./Linux_All_DBG.OBJ/jsl /usr/local/bin/

# Make working in the shell a bit nicer
COPY ./alias.sh /nvm/.bashrc

# A common entrypoint for setting up things before running the user command(s)
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
