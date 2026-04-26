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
