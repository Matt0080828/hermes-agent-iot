from types import SimpleNamespace
from typing import Any, cast

from hermes_cli.models_local import LMStudioLoadResult
from run_agent import AIAgent


def _agent(load_mode="explicit"):
    return SimpleNamespace(
        provider="lmstudio",
        model="test/model",
        base_url="http://127.0.0.1:1234/v1",
        api_key="",
        lmstudio_load_mode=load_mode,
        _config_context_length=None,
        context_compressor=None,
        api_mode="chat_completions",
    )


def test_lmstudio_jit_load_mode_skips_explicit_preload(monkeypatch):
    calls = []

    def fake_ensure(*args, **kwargs):
        calls.append((args, kwargs))
        return LMStudioLoadResult(64_000)

    monkeypatch.setattr("hermes_cli.models_local.ensure_lmstudio_model_loaded", fake_ensure)

    result = AIAgent._ensure_lmstudio_runtime_loaded(cast(Any, _agent("jit")))

    assert result is None
    assert calls == []






def test_verified_runtime_context_is_authoritative_over_lower_explicit_budget():
    """Fork policy: the context LM Studio reports as actually loaded wins over a lower
    preload hint, so the compression budget matches the real runtime window."""
    result = AIAgent._effective_lmstudio_context_length(
        80_000,
        LMStudioLoadResult(120_000),
    )

    assert result == 120_000


def test_explicit_budget_is_used_when_runtime_does_not_report_one():
    """Without a verified runtime context the explicit config value is the only budget."""
    assert AIAgent._effective_lmstudio_context_length(80_000, None) == 80_000
    assert AIAgent._effective_lmstudio_context_length(None, None) is None


