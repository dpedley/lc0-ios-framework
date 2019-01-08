#!/bin/sh

mkdir -p generated
pushd submodules/lc0/libs/lczero-common/; protoc proto/net.proto --cpp_out ../../../../generated; popd
