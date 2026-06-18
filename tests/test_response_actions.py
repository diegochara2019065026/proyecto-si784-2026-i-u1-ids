from src.alert_manager import AlertManager
from src.response_actions import ActiveResponse


def test_active_response_adds_recommended_block_to_icmp_alert(tmp_path):
    manager = AlertManager(
        str(tmp_path / "alerts.json"),
        active_response=ActiveResponse({
            "enabled": True,
            "auto_block_enabled": False,
            "block_minutes": 5,
            "block_alert_types": ["ICMP_FLOOD"],
        }),
    )

    saved = manager.generate_alert(
        "MEDIO",
        "ICMP_FLOOD",
        "192.168.1.50",
        "20 paquetes ICMP en 5 segundos",
    )

    alerts = manager.storage.read()

    assert saved is True
    assert alerts[0]["response_action"]["action"] == "BLOQUEO_TEMPORAL_IP"
    assert alerts[0]["response_action"]["status"] == "RECOMENDADO"
    assert alerts[0]["response_action"]["duration_minutes"] == 5
    assert "192.168.1.50" in alerts[0]["response_action"]["windows_block_command"]


def test_active_response_ignores_unconfigured_alert_type(tmp_path):
    manager = AlertManager(
        str(tmp_path / "alerts.json"),
        active_response=ActiveResponse({
            "enabled": True,
            "block_alert_types": ["FUERZA_BRUTA_SSH"],
        }),
    )

    manager.generate_alert("BAJO", "PUERTO_SOSPECHOSO", "192.168.1.51", "Puerto 22")

    assert "response_action" not in manager.storage.read()[0]
