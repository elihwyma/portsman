FROM alpine:latest

RUN apk update

RUN apk add --no-cache \
    alpine-sdk \
    abuild \
    cmake \
    git \
    samurai \
    python3 \
    python3-dev \
    curl \
    sudo \
    fakeroot \
    bash \
    clang17 \
    automake
    
RUN adduser -D builder && \
    adduser builder abuild && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

RUN sudo mkdir -p /var/cache/distfiles && sudo chown builder:builder /var/cache/distfiles

ARG package_directory=main

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
        echo "Testing repository selected."; \
        echo "https://portsman.anamy.gay" | sudo tee -a /etc/apk/repositories; \
        sudo apk update; \
    fi

# Use -e (exit immediately on error) and -x (print commands before execution)
RUN set -ex; \
    for pkg in packages/*; do \
        echo "+++ Building $pkg"; \
        \
        # Store current directory
        start_dir=$(pwd); \
        \
        # Group commands using { ... ;}. Note spaces and final semicolon.
        # This runs in the *current* shell, unlike (...)
        { \
            echo "--- Changing directory to /home/builder/$pkg"; \
            # Use && for safety within the group even with set -e
            cd "/home/builder/$pkg" && \
            echo "--- Running abuild checksum for $pkg" && \
            abuild checksum && \
            echo "--- Running abuild -r for $pkg" && \
            abuild -r; \
        }; \
        # Capture exit status immediately after the command group
        EXIT_STATUS=$?; \
        \
        # Always change back to starting directory in case cd failed partially
        # or for consistency before checking status / continuing loop
        cd "$start_dir"; \
        \
        # Check exit status from the command group
        if [ $EXIT_STATUS -ne 0 ]; then \
            echo "!!! Build FAILED for $pkg with exit status $EXIT_STATUS"; \
            exit $EXIT_STATUS; \
        fi; \
        # If successful, loop continues
        echo "--- Successfully completed $pkg"; \
    done; \
    echo "+++ All packages built successfully"

RUN mv /home/builder/packages/packages /home/builder/output

WORKDIR /home/builder/output