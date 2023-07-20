FROM calvincs.azurecr.io/base-sssdunburden:latest
LABEL maintainer="Chris Wieringa <cwieri39@calvin.edu>"

# Set versions and platforms
ARG BUILDDATE=20230720-1
ARG S6_OVERLAY_VERSION=3.1.3.0
ARG TZ=America/Detroit
ARG UBUNTUCODENAME="focal"
ARG UBUNTUVERSION="20.04"

# Do all run commands with bash
SHELL ["/bin/bash", "-c"] 

# add gpg for keys
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    gpg \
    software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# Install cpscadmin repo keys
RUN echo "deb [signed-by=/usr/share/keyrings/csrepo.gpg] http://cpscadmin.cs.calvin.edu/repos/cpsc-ubuntu/ ${UBUNTUCODENAME} main" | tee -a /etc/apt/sources.list.d/cs-ubuntu-software-${UBUNTUCODENAME}.list && \
    curl https://cpscadmin.cs.calvin.edu/repos/cpsc-ubuntu/csrepo.asc | tee /tmp/csrepo.asc && \
    gpg --dearmor /tmp/csrepo.asc && \
    mv /tmp/csrepo.asc.gpg /usr/share/keyrings/csrepo.gpg && \
    rm -f /tmp/csrepo.asc

# add all the coding basics
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    # cs106/cs108
    python3 \
    python3-pip \
    python3-tk \
    python3-venv \
    python3-cartopy \
    python3-matplotlib \
    python3-scipy \
    python3-gmplot \
    python3-pil \
    python3-guizero \
    python3-pygame \
    python3-pgzero \
    python3-colorama \
    python3-bs4 \
    python3-pandas \
    python3-pexpect \
    cython3 \
    libtiff5-dev \
    libjpeg8-dev \
    libopenjp2-7-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libwebp-dev \
    tcl8.6-dev \
    tk8.6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    # cs112 
    build-essential \
    ddd \
    valgrind \
    tsgl \
    bridges-cxx \
    # cs326
    python3-paho-mqtt \
    python3-flask \
    crossbuild-essential-armhf \
    gdb-multiarch \
    mosquitto-clients \
    # cs332
    python3-websockets \
    # ada 
    gnat-7 \
    # clojure 
    clojure \
    rlwrap \
    openjfx \
    libcore-async-clojure \
    # elisp and emacs
    emacs-el \
    emacs \
    emacs-goodies-el \
    # git 
    git \
    # java
    default-jdk-headless \
    # maven
    maven \
    # mpe2
    mpe2 \
    # mpich 
    mpich \
    libmpich-dev \
    libmpich12 \
    # openmpi
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    rsh-redone-client \
    # openmp
    libgomp1 \
    libomp5 \
    libomp-dev \
    # tofrodos
    tofrodos \
    # vim
    vim \
    vim-nox \
    # zip
    zip \
    unzip && \
    # final cleanup
    rm -rf /var/lib/apt/lists/*

# monster packages that I could use, or I could mount in via NFS - opt towards NFS right now
#RUN apt-get update -y && \
#    DEBIAN_FRONTEND=noninteractive apt-get install -y \
#    csanaconda \
#    cspython \
#    csr && \
#    rm -rf /var/lib/apt/lists/*
    
# clojure misc configuration
COPY --chmod=0755 inc/clojure-classpath.sh /etc/profile.d/clojure-classpath.sh
RUN ln -s /etc/alternatives/clojure /usr/bin/clj 

# githubcli
RUN echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee -a /etc/apt/sources.list.d/githubcli.list && \
    curl https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    apt-get update -y && \
    apt-get install gh -y && \
    rm -rf /var/lib/apt/lists/*

# google cloud CLI
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv B53DC80D13EDEF05 && \
    apt-get update -y && \
    apt-get install google-cloud-sdk -y && \
    rm -rf /var/lib/apt/lists/*

# heroku CLI
RUN curl https://cli-assets.heroku.com/install-ubuntu.sh | bash && \
    rm -rf /var/lib/apt/lists/*

# microsoft key
RUN echo "deb [signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/${UBUNTUVERSION}/prod/ ${UBUNTUCODENAME} main" | tee -a /etc/apt/sources.list.d/microsoft-prod-${UBUNTUCODENAME}.list && \
    curl https://packages.microsoft.com/keys/microsoft.asc | tee /tmp/microsoft.asc && \
    gpg --dearmor /tmp/microsoft.asc && \
    mv /tmp/microsoft.asc.gpg /usr/share/keyrings/microsoft.gpg && \
    rm -f /tmp/microsoft.asc

# microsoft dotnet
#RUN apt-get update -y && \
#    apt-get install -y dotnet-sdk-3.1 dotnet-sdk-7.0 && \
#    rm -rf /var/lib/apt/lists/*

# microsoft vs code - full install
RUN echo "deb [signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code/ stable main" | tee -a /etc/apt/sources.list.d/microsoft-vscode-${UBUNTUCODENAME}.list && \
    apt-get update -y && \
    apt-get install -y code && \
    rm -f /etc/apt/sources.list.d/vscode.list && \
    rm -rf /var/lib/apt/lists/*

# microsoft vs code cli - only cli install
#RUN curl -fsSL https://code.visualstudio.com/sha/download?build=stable\&os=cli-alpine-x64 | tar zxfv - -C/usr/local/bin && \
#    chmod 0775 /usr/local/bin/code

# mpich alternatives
COPY inc/mpi-set-selections.txt /tmp/mpi-set-selections.txt
RUN /usr/bin/update-alternatives --set-selections < /tmp/mpi-set-selections.txt && \
    /usr/bin/update-alternatives --get-selections | grep mpi | grep -v mono && \
    rm -f /tmp/mpi-set-selections.txt

# nodejs
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update -y && \
    apt-get install -y nodejs && \
    /usr/bin/npm install -g npm && \
    /usr/bin/npm install -g express-generator && \
    /usr/bin/npm install -g express && \
    /usr/bin/npm install -g hot-server && \
    /usr/bin/npm install -g jslint && \
    /usr/bin/npm install -g stylus && \
    /usr/bin/npm install -g expo-cli && \
    /usr/bin/npm install -g expo/ngrok && \
    /usr/bin/npm install -g expo-dev-menu && \
    /usr/bin/npm install -g typescript && \
    /usr/bin/npm install -g @angular/cli && \
    rm -rf /var/lib/apt/lists/*

# openmpi configuration
COPY --chmod=0644 inc/openmpi-mca-params.conf /etc/openmpi/openmpi-mca-params.conf

# swi-prolog
RUN apt-add-repository -y ppa:swi-prolog/stable && \
    apt-get update -y && \
    apt-get install -y swi-prolog && \
    rm -rf /var/lib/apt/lists/*

# cs332 - python3 icecream pip
RUN python3 -m pip install icecream

ENTRYPOINT ["/init"]
