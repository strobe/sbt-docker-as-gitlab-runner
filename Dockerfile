# Minimal image (Alpine based) wiht SBT on Java 8, suitable for Gitlab-CI runner
# 
# To allow docker commands works inside container, you have to launch it like that:
#
#       docker run -it -v /var/run/docker.sock:/var/run/docker.sock image_name:latest sh -c "bash"
#
# For GitLab is impotant to setup volume for runner at /etc/gitlab-runner/config.toml
# on host machine like this:
#  
# concurrent = 1
#
# [[runners]]
# url = "http://gitlab.com/ci"
# token = "1e2d70c942e60ce701f576"
# tls-skip-verify = false
# tls-ca-file = ""
# name = "osx-docker"
# executor = "docker"
# [runners.docker]
#     host = "tcp://192.168.99.100:2376"
#     tls_cert_path = "/Users/evgeniy/.docker/machine/machines/docker-vm"
#     tls_verify = true
#     image = "strobe/sbt-docker-as-gitlab-runner"
#     privileged = false
#     volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock"]
#


FROM library/docker:1.9.1

# adding bash
RUN apk upgrade --update && \
    apk add bash

# Install cURL
RUN apk upgrade --update && \
    apk add curl ca-certificates tar bash && \
    curl -Ls https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk > /tmp/glibc-2.21-r2.apk && \
    apk add --allow-untrusted /tmp/glibc-2.21-r2.apk

# Java Version
ENV JAVA_VERSION_MAJOR 8
ENV JAVA_VERSION_MINOR 66
ENV JAVA_VERSION_BUILD 17
ENV JAVA_PACKAGE       jdk

# Download and unarchive Java
RUN mkdir /opt && curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie"\
  http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    | tar -xzf - -C /opt &&\
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk &&\
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/lib/plugin.jar \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so

# Set environment
ENV JAVA_HOME /opt/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin

RUN bash -c 'java -version'

# SBT
ENV SBT_VERSION 0.13.8

RUN mkdir -p /usr/local/bin && wget -P /usr/local/bin/ http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/$SBT_VERSION/sbt-launch.jar && ls /usr/local/bin

COPY sbt /usr/local/bin/

# create an empty sbt project;
# then fetch all sbt jars from Maven repo so that your sbt will be ready to be used when you launch the image
COPY test-sbt.sh /tmp/

ENV SCALA_VERSION 2.11.6

RUN cd /tmp && \
    mkdir -p src/main/scala && \
    echo "object Main {}" > src/main/scala/Main.scala && \
    ./test-sbt.sh && \
    rm -rf *

# Define default command.
CMD ["sbt"]

