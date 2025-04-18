FROM alpine:latest

ARG packages="tensorflowlite"

RUN apk add --no-cache alpine-sdk sudo

COPY package /home/builder/packages
RUN sudo chown -R builder:builder /home/builder/packages

RUN abuild-keygen -a -n

USER builder
WORKDIR /home/builder/packages

# Build packages
RUN for pkg in $packages; do \
      cd /home/builder/packages/$pkg && \
      abuild checksum && \
      abuild -r; \
    done

# Copy built APKs to a common folder
RUN mkdir -p /home/builder/output && \
    find /home/builder/packages/ -name '*.apk' -exec cp {} /home/builder/output/ \;

WORKDIR /home/builder/output