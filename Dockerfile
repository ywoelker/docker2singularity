FROM ubuntu:20.10 AS base

RUN apt-get update && apt-get install --yes --no-install-recommends \
    # support singularity build/pull workflows
    ca-certificates squashfs-tools \
 && rm -rf /var/lib/apt/lists/*

FROM base AS builder

# https://sylabs.io/guides/3.7/admin-guide/installation.html#installation-on-linux

RUN apt-get update && apt-get install --yes --no-install-recommends \
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    wget ca-certificates \
    pkg-config \
    git \
    cryptsetup \
  && rm -rf /var/lib/apt/lists/*

RUN export VERSION=1.16.4 \
 && wget --quiet https://golang.org/dl/go${VERSION}.linux-amd64.tar.gz \
 && tar -C /usr/local -xzf go${VERSION}.linux-amd64.tar.gz \
 && rm /go${VERSION}.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

RUN export VERSION=3.7.3 \
 && cd /tmp \
 && wget --quiet https://github.com/hpcng/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz \
 && tar -xzf singularity-${VERSION}.tar.gz \
 && cd singularity \
 && ./mconfig --prefix=/singularity \
 && make -C builddir \
 && make -C builddir install

FROM base

# Original Singularity information.

COPY --from=builder /tmp/singularity/LICENSE.md /singularity/LICENSE.md
COPY --from=builder /tmp/singularity/README.md /singularity/README.md

# This repository's information.

ADD README.md LICENSE Dockerfile /

# Singularity executable.

# Full install...
#COPY --from=builder /singularity /singularity

# Minimal install... supports singularity pull/build workflows.
COPY --from=builder /singularity/bin/singularity /singularity/bin/singularity
COPY --from=builder /singularity/etc/singularity/singularity.conf /singularity/etc/singularity/singularity.conf

# Conveniences.

ENV PATH=$PATH:/singularity/bin
RUN mkdir /output
WORKDIR /output
