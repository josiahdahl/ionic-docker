FROM debian:jessie
MAINTAINER josiah.dahl@gmail.com

ARG NODE_VERSION
ARG IONIC_VERSION
ARG CORDOVA_VERSION
ARG YARN_VERSION
ARG GRADLE_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NODE_VERSION=$NODE_VERSION \
    IONIC_VERSION=$IONIC_VERSION \
    CORDOVA_VERSION=$CORDOVA_VERSION \
    YARN_VERSION=$YARN_VERSION \
    GRADLE_VERSION=4.4.1
    # Fix for the issue with Selenium, as described here:
    # https://github.com/SeleniumHQ/docker-selenium/issues/87
    # DBUS_SESSION_BUS_ADDRESS=/dev/null
# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# update the repository sources list
# and install dependencies
RUN apt-get update \
    && apt-get install -y git wget curl unzip ruby build-essential xvfb \
    # install python-software-properties (so you can do add-apt-repository)
    && apt-get update && apt-get install -y -q python-software-properties software-properties-common \
    && add-apt-repository "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" -y \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
    && apt-get update && apt-get -y install oracle-java8-installer \

# System libs for android enviroment
    && echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment && \
    dpkg --add-architecture i386 && \
    apt-get update && \ 
    apt-get install -y --force-yes expect ant wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \

# Install Android Tools
    mkdir  /opt/android-sdk-linux && cd /opt/android-sdk-linux && \
    wget --output-document=android-tools-sdk.zip --quiet https://dl.google.com/android/repository/tools_r25.2.3-linux.zip && \
    unzip -q android-tools-sdk.zip && \
    rm -f android-tools-sdk.zip && \
    chown -R root. /opt \ 
    && apt-get -y autoclean \

    # Install Gradle
    && mkdir  /opt/gradle && cd /opt/gradle && \
    wget --output-document=gradle.zip --quiet https://services.gradle.org/distributions/gradle-"$GRADLE_VERSION"-bin.zip && \
    unzip -q gradle.zip && \
    rm -f gradle.zip && \
    chown -R root. /opt
# nvm environment variables
ENV NVM_DIR /usr/local/nvm

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install ${NODE_VERSION} \
    && nvm alias default ${NODE_VERSION} \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/${NODE_VERSION}/lib/node_modules
ENV PATH $NVM_DIR/versions/node/${NODE_VERSION}/bin:$PATH

# Install global packages
RUN npm install -g cordova@${CORDOVA_VERSION} ionic@${IONIC_VERSION} yarn@${YARN_VERSION}

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:/opt/gradle/gradle-${GRADLE_VERSION}/bin

# Install Android SDK
RUN yes Y | ${ANDROID_HOME}/tools/bin/sdkmanager "build-tools;25.0.2" "platforms;android-25" "platform-tools" 
RUN cordova telemetry off

RUN mkdir /app

COPY ./app /app

WORKDIR /app
