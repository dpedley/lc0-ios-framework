#!/bin/sh

pushd submodules/lc0/libs/lczero-common/; protoc proto/net.proto --cpp_out ../../../../generated; popd
