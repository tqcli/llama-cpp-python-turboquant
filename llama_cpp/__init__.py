import os as _os
import sys as _sys

# Windows-only DLL search-path setup. delvewheel bundles CUDA runtime DLLs
# (cudart64_12, cublas64_12, etc.) into <wheel_root>/llama_cpp.libs/ during
# the cibuildwheel repair step. Python's loader needs an explicit
# os.add_dll_directory call to find them — PATH-based DLL resolution is
# disabled by default since Python 3.8 on Windows. Must run BEFORE the C
# extension is loaded (`from .llama_cpp import *` below).
if _sys.platform == "win32":
    _libs_dir = _os.path.abspath(
        _os.path.join(_os.path.dirname(__file__), "..", "llama_cpp.libs")
    )
    if _os.path.isdir(_libs_dir):
        _os.add_dll_directory(_libs_dir)

from .llama_cpp import *
from .llama import *

__version__ = "0.3.20"

# ---------------------------------------------------------------------------
# TurboQuant runtime sentinels.
# tqcli/core/engine_auditor.py reads TURBOQUANT_BUILD to distinguish this
# fork from upstream llama-cpp-python at runtime.
# ---------------------------------------------------------------------------
TURBOQUANT_BUILD: bool = True
TURBOQUANT_KV_TYPES: tuple[str, ...] = ("turbo2", "turbo3", "turbo4")
