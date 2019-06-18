# Copyright 2017-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#

FROM ubuntu:14.04.5

ENV DOCKER_BUCKET="download.docker.com" \
    DOCKER_VERSION="17.09.0-ce" \
    DOCKER_CHANNEL="stable" \
    DOCKER_SHA256="a9e90a73c3cdfbf238f148e1ec0eaff5eb181f92f35bdd938fd7dab18e1c4647" \
    DIND_COMMIT="3b5fac462d21ca164b3778647420016315289034" \
    DOCKER_COMPOSE_VERSION="1.21.2" \
    GITVERSION_VERSION="3.6.5"

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt install -y apt-transport-https \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb https://download.mono-project.com/repo/ubuntu stable-trusty main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update \
    && apt-get install software-properties-common -y --no-install-recommends \
    && apt-add-repository ppa:git-core/ppa \
    && apt-get update \
    && apt-get install git=1:2.* -y --no-install-recommends \
    && git version \
    && apt-get install -y --no-install-recommends openssh-client=1:6.6* \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && apt-get install -y --no-install-recommends \
       wget=1.15-* python=2.7.* python2.7-dev=2.7.* fakeroot=1.20-* ca-certificates \
       tar=1.27.* gzip=1.6-* zip=3.0-* autoconf=2.69-* automake=1:1.14.* \
       bzip2=1.0.* file=1:5.14-* g++=4:4.8.* gcc=4:4.8.* imagemagick=8:6.7.* \
       libbz2-dev=1.0.* libc6-dev=2.19-* libcurl4-openssl-dev=7.35.* libdb-dev=1:5.3.* \
       libevent-dev=2.0.* libffi-dev=3.1~* libgeoip-dev=1.6.* libglib2.0-dev=2.40.* \
       libjpeg-dev=8c-* libkrb5-dev=1.12+* liblzma-dev=5.1.* \
       libmagickcore-dev=8:6.7.* libmagickwand-dev=8:6.7.* libmysqlclient-dev=5.5.* \
       libncurses5-dev=5.9+* libpng12-dev=1.2.* libpq-dev=9.3.* libreadline-dev=6.3-* \
       libsqlite3-dev=3.8.* libssl-dev=1.0.* libtool=2.4.* libwebp-dev=0.4.* \
       libxml2-dev=2.9.* libxslt1-dev=1.1.* libyaml-dev=0.1.* make=3.81-* \
       patch=2.7.* xz-utils=5.1.* zlib1g-dev=1:1.2.* unzip=6.0-* curl=7.35.* \
       e2fsprogs=1.42.* iptables=1.4.* xfsprogs=3.1.* xz-utils=5.1.* \
       mono-devel less=458-* groff=1.22.* liberror-perl=0.17-* \
       asciidoc=8.6.* build-essential=11.* bzr=2.6.* cvs=2:1.12.* cvsps=2.1-* docbook-xml=4.5-* docbook-xsl=1.78.* dpkg-dev=1.17.* \
       libdbd-sqlite3-perl=1.40-* libdbi-perl=1.630-* libdpkg-perl=1.17.* libhttp-date-perl=6.02-* \
       libio-pty-perl=1:1.08-* libserf-1-1=1.3.* libsvn-perl=1.8.* libsvn1=1.8.* libtcl8.6=8.6.* libtimedate-perl=2.3000-* \
       libunistring0=0.9.* libxml2-utils=2.9.* libyaml-perl=0.84-* python-bzrlib=2.6.* python-configobj=4.7.* \
       sgml-base=1.26+* sgml-data=2.0.* subversion=1.8.* tcl=8.6.* tcl8.6=8.6.* xml-core=0.13+* xmlto=0.0.* xsltproc=1.1.* \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Download and set up GitVersion
RUN set -ex \
    && wget "https://github.com/GitTools/GitVersion/releases/download/v${GITVERSION_VERSION}/GitVersion_${GITVERSION_VERSION}.zip" -O /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && mkdir -p /usr/local/GitVersion_${GITVERSION_VERSION} \
    && unzip /tmp/GitVersion_${GITVERSION_VERSION}.zip -d /usr/local/GitVersion_${GITVERSION_VERSION} \
    && rm /tmp/GitVersion_${GITVERSION_VERSION}.zip \
    && echo "mono /usr/local/GitVersion_${GITVERSION_VERSION}/GitVersion.exe \$@" >> /usr/local/bin/gitversion \
    && chmod +x /usr/local/bin/gitversion

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
    && addgroup dockremap \
    && useradd -g dockremap dockremap \
    && echo 'dockremap:165536:65536' >> /etc/subuid \
    && echo 'dockremap:165536:65536' >> /etc/subgid \
    && wget "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind" -O /usr/local/bin/dind \
    && curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/dind /usr/local/bin/docker-compose \
# Ensure docker-compose works
    && docker-compose version

# Install dependencies by all python images equivalent to buildpack-deps:jessie
# on the public repos.

RUN set -ex \
    && wget "https://bootstrap.pypa.io/2.6/get-pip.py" -O /tmp/get-pip.py \
    && python /tmp/get-pip.py \
    && pip install awscli==1.* \
    && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /var/lib/docker

COPY dockerd-entrypoint.sh /usr/local/bin/

# Copy install tools
COPY tools /opt/tools

ENV ANDROID_HOME="/usr/local/android-sdk-linux" \
    JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64" \
    JDK_VERSION="8u171-b11-2~14.04" \
    JDK_HOME="/usr/lib/jvm/java-8-openjdk-amd64" \
    JRE_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre" \
    JAVA_VERSION="8" \
    INSTALLED_GRADLE_VERSIONS="2.14.1 3.5 4.0.2 4.1 4.2.1 4.3.1 4.4" \
    GRADLE_VERSION="4.4" \
    ANDROID_TOOLS_VER="24.4.1" \
    ANDROID_TOOLS_SHA1="725bb360f0f7d04eaccff5a2d57abdd49061326d"
ENV PATH="${PATH}:/opt/tools:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools"

# Install java8
RUN set -ex \
      && apt-get update \
      && apt-get install -y software-properties-common=0.92.37.8 \
      && add-apt-repository -y ppa:openjdk-r/ppa \
      && (echo oracle-java$JAVA_VERSION-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections) \
      && apt-get update \
      && apt-get -y install openjdk-$JAVA_VERSION-jdk=$JDK_VERSION \
      && update-ca-certificates -f \
      && apt-get install -y -qq less=458-* groff=1.22.2-* \
      && dpkg --add-architecture i386 \
      && apt-get update && apt-get install -y --force-yes expect=5.45-* libc6-i386=2.19-* \
         lib32stdc++6=4.8.4-* lib32gcc1=1:4.9.3-* lib32ncurses5=5.9+20140118-* \
         lib32z1=1:1.2.8.dfsg-* libqt5widgets5=5.2.1+dfsg-* \
      && apt-get clean \
# Precache most relevant versions of Gradle for `gradlew` scripts
      && mkdir -p /usr/src/gradle \
      && for version in $INSTALLED_GRADLE_VERSIONS; do {\
           wget "https://services.gradle.org/distributions/gradle-$version-all.zip" -O "/usr/src/gradle/gradle-$version-all.zip" \
           && unzip "/usr/src/gradle/gradle-$version-all.zip" -d /usr/local \
           && mkdir "/tmp/gradle-$version" \
           && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" wrapper \
           # Android Studio uses the "-all" distribution for it's wrapper script.
           && perl -pi -e "s/gradle-$version-bin.zip/gradle-$version-all.zip/" "/tmp/gradle-$version/gradle/wrapper/gradle-wrapper.properties" \
           && "/tmp/gradle-$version/gradlew" -p "/tmp/gradle-$version" init \
           && rm -rf "/tmp/gradle-$version" \
           && if [ "$version" != "$GRADLE_VERSION" ]; then rm -rf "/usr/local/gradle-$version"; fi; \
         }; done \
# Install default GRADLE_VERSION to path
      && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
      && rm -rf /usr/src/gradle \
# Install Android SDK
      && wget "https://dl.google.com/android/android-sdk_r$ANDROID_TOOLS_VER-linux.tgz" -O /tmp/android-sdk.tgz \
      && echo "${ANDROID_TOOLS_SHA1} /tmp/android-sdk.tgz" | sha1sum -c - \
      && tar -xzf /tmp/android-sdk.tgz -C /usr/local/ \
      && chown -R root.root $ANDROID_HOME \
      && ln -s $ANDROID_HOME/tools/android /usr/bin/android \
      && /opt/tools/android-accept-licenses.sh "android update sdk --all --no-ui --filter platform-tools,build-tools-23.0.3,build-tools-24.0.3,build-tools-25.0.3,build-tools-26.0.2,android-23,android-24,android-25,android-26" \
      && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*
