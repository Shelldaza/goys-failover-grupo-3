# Runbook — Drill 5: load-sharing VRRP, ambos DIST activos

**Fecha:** 20/10/2026 · **Responsable:** R5 · **Fase:** F4
**Escenario:** verificar que ambos routers de distribución reenvían tráfico a la vez, cada uno como master de un grupo VRRP. No hay falla inducida: este drill documenta el estado estable de balanceo de carga.

## 1. Diseño

| Grupo | VIP | MAC virtual | Master (prio 150) | Backup (prio 100) | Hosts |
| :---- | :---- | :---- | :---- | :---- | :---- |
| vrid 10 | 192.168.10.1 | 00:00:5E:00:01:0A | DIST-1 | DIST-2 | PC-USER |
| vrid 20 | 192.168.20.1 | 00:00:5E:00:01:14 | DIST-2 | DIST-1 | SRV |

## 2. Detección (cómo se verifica)

- `/interface vrrp print` en DIST-1: `vrrp10` `RM`, `vrrp20` `B`.
- `/interface vrrp print` en DIST-2: `vrrp10` `B`, `vrrp20` `RM`.
- `arp` en PC-USER: `192.168.10.1` → `00:00:5e:00:01:0a`.
- `arp` en SRV: `192.168.20.1` → `00:00:5e:00:01:14`.
- `trace 192.168.20.100` desde PC-USER: primer salto 192.168.10.2 (dirección propia de DIST-1).
- `trace 192.168.10.100` desde SRV: primer salto 192.168.20.1 (VIP de vrid 20, que solo responde el master, DIST-2).

Las direcciones del primer salto difieren porque el router responde con la IP de su interfaz de salida; en SRV es la VIP. En ambos casos el tráfico de cada LAN pasa por un DIST distinto.

## 3. Respuesta

No aplica: ambos routers están operativos y cada uno atiende el grupo del que es master. Cada host usa como gateway la VIP de su grupo, sin configuración adicional en los hosts.

## 4. Recuperación

No aplica en estado estable. Ante la caída de uno de los DIST, el otro asume ambos grupos (verificado en el Drill 1) y al volver el caído se recupera el balanceo por preemption.

## 5. Tiempo medido

No aplica (el drill es una verificación de estado, sin falla). Los tiempos de convergencia están en el Drill 1.

## 6. Post-mortem

- **Por qué funciona:** prioridades cruzadas (150/100 en cada grupo) y preemption activa: cada DIST es master de un grupo y backup del otro, por lo que ambos reenvían tráfico en condiciones normales.
- **Qué aprendimos:** el balanceo es por LAN, no por flujo: todo el tráfico de PC-USER sale por DIST-1 y todo el de SRV por DIST-2. Con distribución desigual de tráfico entre las LAN, el reparto no es parejo.
- **Riesgo residual:** si cae un DIST, el otro absorbe el tráfico de ambas LAN, por lo que debe dimensionarse para el 100 % de la carga.
- **Verificación de seguridad:** ambos grupos usan autenticación AH (ver sección de VRRP de la memoria).

## 7. Evidencias

Carpeta `capturas/F4/`:

- `F4-drill5-DIST-1.png`, `F4-drill5-DIST-2.png`
- `F4-drill5-PC-USER.png`, `F4-drill5-SRV.png`
