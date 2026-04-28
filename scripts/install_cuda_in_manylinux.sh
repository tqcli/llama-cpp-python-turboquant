#!/usr/bin/env bash
# DNF-install CUDA 12.8 toolkit inside pypa/manylinux_2_34_x86_64
# (AlmaLinux 9 base, glibc 2.34). Used by the cp311 manylinux_2_34
# sweep cell only. NOT used by the manylinux_2_28 main cells (those
# use pytorch/manylinux2_28-builder:cuda12.8 which ships CUDA preinstalled).
#
# This script is the "Path B" prototype tracked at
# tqcli/llama-cpp-python-turboquant#3. If the sweep cell succeeds, 0.7.1
# can adopt this approach and drop the dependency on pytorch's CUDA images.
set -euo pipefail

echo "=== Adding NVIDIA CUDA RHEL 9 repo ==="
dnf -y install dnf-plugins-core
dnf config-manager --add-repo \
  https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo

echo "=== Installing CUDA 12.8 toolkit ==="
# Try the meta-package first (NVIDIA's documented path).
# Fallback: install the constituent packages explicitly. This guards against
# repodata variations between the meta-package and the explicit package list.
dnf -y install cuda-toolkit-12-8 \
  || dnf -y install cuda-12-8 cuda-compiler-12-8 cuda-cudart-devel-12-8 \
                    libcublas-devel-12-8 cuda-driver-devel-12-8

# Compatibility symlink: most build configs assume /usr/local/cuda
[ -e /usr/local/cuda ] || ln -sf /usr/local/cuda-12.8 /usr/local/cuda

echo "=== nvcc version ==="
/usr/local/cuda/bin/nvcc --version

echo "=== Required libs for our linker flags ==="
# Sanity-check that everything CMAKE_*_LINKER_FLAGS reaches for actually exists.
ls -la /usr/local/cuda/lib64/stubs/libcuda.so
ls -la /usr/local/cuda/lib64/libcudart.so.12 \
    || ls -la /usr/local/cuda/lib64/libcudart.so
ls -la /usr/local/cuda/lib64/libcublas.so.12 \
    || ls -la /usr/local/cuda/lib64/libcublas.so
ls -la /usr/local/cuda/lib64/libcublasLt.so.12 \
    || ls -la /usr/local/cuda/lib64/libcublasLt.so

echo "=== gcc + libgomp for -fopenmp link ==="
gcc --version | head -1
ldconfig -p | grep -E "libgomp\.so" | head -3 \
    || echo "WARN: libgomp not found via ldconfig — relying on default lib path"

echo "=== install_cuda_in_manylinux.sh complete ==="
