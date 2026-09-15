from unittest.mock import patch


def test_local_llama_setup_uses_safe_llama_server_defaults():
    from hermes_cli import model_setup_flows, model_setup_flows_custom

    config = {}
    # Patch where the callee is defined: upstream moved ``_model_flow_custom``
    # into model_setup_flows_custom, so patching the re-exported name in
    # model_setup_flows no longer intercepts the call.
    with patch.object(model_setup_flows_custom, "_model_flow_custom") as custom:
        model_setup_flows._model_flow_local_llama(config)

    custom.assert_called_once_with(
        config,
        preset={
            "base_url": "http://127.0.0.1:8080/v1",
            "api_key": "local",
            "model": "pi2-local",
        },
    )


def test_custom_flow_still_accepts_calls_without_preset():
    import inspect

    from hermes_cli import model_setup_flows

    parameter = inspect.signature(model_setup_flows._model_flow_custom).parameters["preset"]
    assert parameter.default is None
