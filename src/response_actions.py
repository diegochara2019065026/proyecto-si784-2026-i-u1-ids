import ipaddress
import platform
import re
import subprocess
from datetime import datetime, timedelta
from typing import Optional


DEFAULT_BLOCK_TYPES = {
    "ICMP_FLOOD",
    "FUERZA_BRUTA_SSH",
}


class ActiveResponse:
    def __init__(self, config: Optional[dict] = None):
        self.config = config or {}
        self.enabled = bool(self.config.get("enabled", True))
        self.auto_block_enabled = bool(self.config.get("auto_block_enabled", False))
        self.block_minutes = max(1, int(self.config.get("block_minutes", 10)))
        self.block_alert_types = set(
            self.config.get("block_alert_types", sorted(DEFAULT_BLOCK_TYPES))
        )
        self.rule_prefix = self.config.get(
            "windows_firewall_rule_prefix",
            "TrafficWatch IDS Auto Block",
        )

    def build_response(self, alert_type: str, source_ip: str) -> Optional[dict]:
        if not self.enabled or alert_type not in self.block_alert_types:
            return None

        clean_ip = self._validate_ip(source_ip)
        block_until = datetime.now() + timedelta(minutes=self.block_minutes)
        rule_name = self._rule_name(alert_type, clean_ip)
        response = {
            "action": "BLOQUEO_TEMPORAL_IP",
            "status": "RECOMENDADO",
            "reason": f"Alerta {alert_type} desde {clean_ip}",
            "source_ip": clean_ip,
            "duration_minutes": self.block_minutes,
            "block_until": block_until.strftime("%Y-%m-%d %H:%M:%S"),
            "windows_rule_name": rule_name,
            "windows_block_command": (
                f'New-NetFirewallRule -DisplayName "{rule_name}" '
                f'-Direction Inbound -RemoteAddress {clean_ip} -Action Block'
            ),
            "windows_unblock_command": (
                f'Remove-NetFirewallRule -DisplayName "{rule_name}"'
            ),
            "note": (
                "Ejecuta el comando de bloqueo como administrador, o activa "
                "auto_block_enabled en config.json para que el IDS lo intente aplicar."
            ),
        }

        if self.auto_block_enabled:
            response.update(self._apply_windows_block(rule_name, clean_ip))

        return response

    def _validate_ip(self, source_ip: str) -> str:
        try:
            return str(ipaddress.ip_address(str(source_ip or "").strip()))
        except ValueError as error:
            raise ValueError(f"IP origen invalida para respuesta activa: {source_ip}") from error

    def _rule_name(self, alert_type: str, source_ip: str) -> str:
        clean_type = re.sub(r"[^A-Za-z0-9_-]+", "_", alert_type)
        return f"{self.rule_prefix} {clean_type} {source_ip}"

    def _apply_windows_block(self, rule_name: str, source_ip: str) -> dict:
        if platform.system().lower() != "windows":
            return {
                "status": "NO_APLICADO",
                "error": "El bloqueo automatico solo esta implementado para Windows Firewall.",
            }

        command = [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-Command",
            (
                f'New-NetFirewallRule -DisplayName "{rule_name}" '
                f'-Direction Inbound -RemoteAddress {source_ip} -Action Block '
                "-ErrorAction Stop"
            ),
        ]

        try:
            subprocess.run(command, capture_output=True, text=True, check=True)
        except FileNotFoundError:
            return {
                "status": "NO_APLICADO",
                "error": "No se encontro powershell.exe para aplicar Windows Firewall.",
            }
        except subprocess.CalledProcessError as error:
            message = (error.stderr or error.stdout or str(error)).strip()
            return {
                "status": "NO_APLICADO",
                "error": message or "No se pudo aplicar la regla de firewall.",
            }

        return {
            "status": "BLOQUEO_APLICADO",
            "applied_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }
