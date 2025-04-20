FROM alpine:latest

ARG package_directory=main

RUN apk update

RUN apk add --no-cache \
    alpine-sdk \
    abuild \
    cmake \
    samurai \
    git \
    python3 \
    python3-dev \
    curl \
    sudo \
    fakeroot \
    bash \
    clang18 \
    automake
    
RUN adduser -D builder && \
    adduser builder abuild && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

RUN sudo mkdir -p /var/cache/distfiles && sudo chown builder:builder /var/cache/distfiles

# Copy your APKBUILD and sources
COPY ${package_directory} /home/builder/packages

RUN sudo chown -R builder:builder /home/builder/packages

RUN mkdir -p /home/builder/.abuild && \
    echo 'PACKAGER_PRIVKEY="/home/builder/.abuild/portsman-anamy.rsa"' >> /home/builder/.abuild/abuild.conf

WORKDIR /home/builder

RUN --mount=type=secret,id=portsman_key,dst=/tmp/portsman.rsa \
    --mount=type=secret,id=portsman_pub,dst=/tmp/portsman.rsa.pub \
    sudo cp /tmp/portsman.rsa /home/builder/.abuild/portsman-anamy.rsa && \
    sudo cp /tmp/portsman.rsa.pub /home/builder/.abuild/portsman-anamy.rsa.pub && \
    sudo cp /tmp/portsman.rsa.pub /etc/apk/keys/portsman-anamy.rsa.pub && \
    sudo chown builder:builder /home/builder/.abuild/portsman-anamy.rsa /home/builder/.abuild/portsman-anamy.rsa.pub /etc/apk/keys/portsman-anamy.rsa.pub && \
    sudo chmod 600 /home/builder/.abuild/portsman-anamy.rsa && \
    sudo chmod 644 /home/builder/.abuild/portsman-anamy.rsa.pub /etc/apk/keys/portsman-anamy.rsa.pub
    
# If package_directory is testing
RUN if [ "$package_directory" = "testing" ]; then \
        echo "Testing repository selected"; \
        echo "https://portsman.anamy.gay" | sudo tee -a /etc/apk/repositories; \
        sudo apk update; \
    fi

RUN for pkg in packages/*; do \
        cd /home/builder/$pkg && \
        abuild checksum && \
        abuild -r; \
        done 

RUN mv /home/builder/packages/packages /home/builder/output

WORKDIR /home/builder/output