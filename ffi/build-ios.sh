#!/usr/bin/env bash
# Builds the two library files the Xcode project links against.
#
# Both stay: device arm64 and simulator arm64 cannot be joined with lipo - same
# architecture, different platform - so Xcode picks between them by SDK instead.
# Nothing in the dependency tree is C, so cross compiling needs no toolchain
# beyond `rustup target add aarch64-apple-ios aarch64-apple-ios-sim`.
set -euo pipefail
cd "$(dirname "$0")/.."

export IPHONEOS_DEPLOYMENT_TARGET=18.0

for target in aarch64-apple-ios aarch64-apple-ios-sim; do
    cargo build -p core_engine_ffi --release --target "$target"
done

ls -l target/aarch64-apple-ios/release/libfreepdf.a \
      target/aarch64-apple-ios-sim/release/libfreepdf.a
