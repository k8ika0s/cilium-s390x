#!/usr/bin/env bash

# Copyright Authors of Cilium
# SPDX-License-Identifier: Apache-2.0

set -o xtrace
set -o errexit
set -o pipefail
set -o nounset

# renovate: datasource=github-release-attachments depName=protocolbuffers/protobuf
protoc_version="v33.5"
protoc_version_number="${protoc_version#v}"
arch=$(arch)
if [[ "${arch}" == "aarch64" ]]; then
  arch="aarch_64"
elif [[ "${arch}" == "s390x" ]]; then
  arch="s390_64"
fi
protoc_archive="protoc-${protoc_version_number}-linux-${arch}.zip"
protoc_url="https://github.com/protocolbuffers/protobuf/releases/download/${protoc_version}/${protoc_archive}"

if curl --fail --show-error --silent --location "${protoc_url}" --output /tmp/protoc.zip; then
  unzip /tmp/protoc.zip -x readme.txt -d /usr/local

  # correct permissions for others
  chmod o+rx /usr/local/bin/protoc
  chmod o+rX -R /usr/local/include/google/
else
  # Keep a distro fallback for arches without upstream protobuf release assets.
  if [[ "${arch}" == "s390_64" ]]; then
    apt-get update
    apt-get install -y --no-install-recommends protobuf-compiler
    apt-get clean
    rm -rf /var/lib/apt/lists/*
  else
    echo "Failed to download ${protoc_archive} from ${protoc_url}" >&2
    exit 1
  fi
fi
