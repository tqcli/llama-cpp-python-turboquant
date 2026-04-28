#!/usr/bin/env bash
# Repair a Linux wheel built by cibuildwheel for llama-cpp-python-turboquant.
#
# Args: $1 = source wheel path, $2 = dest dir, $3 = variant ("cuda" or "cpu")
#
# CPU variant: standard auditwheel repair, bundles all non-system libs.
# CUDA variant: PyTorch +cuXXX pattern. Exclude CUDA libs from the wheel
#   (declared as a [cuda12] extra in pyproject.toml so pip pulls them from
#   PyPI at install time), then patchelf the C extension's RPATH so it
#   finds <site-packages>/nvidia/<lib>/lib/ at runtime.
set -euo pipefail

WHEEL="$1"
DEST_DIR="$2"
VARIANT="$3"

if [ "$VARIANT" = "cuda" ]; then
    # Exclude CUDA runtime libs; user's [cuda12] extra installs them at
    # runtime from nvidia-cuda-runtime-cu12 / nvidia-cublas-cu12 wheels.
    auditwheel repair \
        --plat manylinux2014_x86_64 \
        --exclude libcudart.so.12 \
        --exclude libcublas.so.12 \
        --exclude libcublasLt.so.12 \
        -w "$DEST_DIR" "$WHEEL"

    # Patch RPATH on every .so inside the repaired wheel so the linker
    # finds the pip-installed nvidia/*/lib/ at runtime.
    REPAIRED_WHEEL=$(ls -t "$DEST_DIR"/*.whl | head -1)
    UNPACK_DIR=$(mktemp -d)
    pushd "$UNPACK_DIR" > /dev/null
    unzip -q "$REPAIRED_WHEEL"
    # The C extension is at llama_cpp/lib/*.so (or similar). Walk all .so
    # files under llama_cpp/ and add the nvidia/* RPATH entries.
    find llama_cpp -name '*.so' -type f -print0 | while IFS= read -r -d '' so; do
        # $ORIGIN walks 2 dirs up from <site-packages>/llama_cpp/lib/X.so
        # to <site-packages>/, then into nvidia/<lib>/lib/.
        patchelf --add-rpath '$ORIGIN/../../nvidia/cuda_runtime/lib:$ORIGIN/../../nvidia/cublas/lib' "$so"
    done
    rm "$REPAIRED_WHEEL"
    zip -qr "$REPAIRED_WHEEL" .
    popd > /dev/null
    rm -rf "$UNPACK_DIR"
else
    auditwheel repair --plat manylinux2014_x86_64 -w "$DEST_DIR" "$WHEEL"
fi
