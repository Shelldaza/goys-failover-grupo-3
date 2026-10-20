# Runbook — Drill 3: caída del enlace EDGE ↔ ISP-1 (BGP)

**Fecha:** 20/10/2026 · **Responsable:** R5 · **Fase:** F4
**Escenario:** se deshabilita `ether1` de ISP-1 (enlace 203.0.113.0/30 hacia EDGE) con tráfico PC-USER → 2.2.2.2 en curso.

## 1. Estado base

- EDGE: 2 sesiones eBGP `Established` (ISP-1 203.0.113.1 AS 65001; ISP-2 198.51.100.1 AS 65002), hold-time 3 min, keepalive 1 min.
- Default `0.0.0.0/0` con dos rutas BGP: activa por 203.0.113.1 (local-pref 200) y de respaldo por 198.51.100.1 (local-pref 100).
- `2.2.2.2/32` solo por ISP-1 y `3.3.3.3/32` solo por ISP-2 (los filtros aceptan cada loopback únicamente de su ISP).
- PC-USER alcanza 2.2.2.2 y 3.3.3.3. `trace 3.3.3.3`: 192.168.10.1 → 10.0.0.25 → 10.0.0.5 → 3.3.3.3.
- Relojes: ISP-1 adelantado ≈ 4 s respecto de EDGE (incluye el tiempo entre comandos).

## 2. Detección

- **Síntoma:** `ping 2.2.2.2` desde PC-USER pierde respuesta; EDGE responde `Destination host unreachable` (10.0.0.5).
- **Mecanismo:** no hubo caída de interfaz en EDGE. La sesión BGP se mantuvo hasta vencer el hold-time.
- **Confirmación:** `/log print where topics~"bgp"` en EDGE: `03:29:20 HoldTimer expired F3-ISP-1-1`; `.last-notification` con código 04 (Hold Timer Expired).

## 3. Respuesta

No requiere intervención manual. Al caer la sesión, EDGE retira las rutas aprendidas de ISP-1 y el default activo pasa a 198.51.100.1 (ISP-2). La ruta a 2.2.2.2 desaparece. 3.3.3.3 sigue alcanzable sin cambios (5/5 respuestas desde EDGE).

A partir de `icmp_seq=150` el ping de PC-USER recibe `Destination network unreachable` desde 198.51.100.1: el tráfico ya sale por ISP-2, que no conoce 2.2.2.2 (comportamiento esperado por diseño).

## 4. Recuperación

1. En ISP-1: `/interface enable ether1`.
2. Verificar en EDGE: sesión F3-ISP-1-1 en `E`; default activo por 203.0.113.1 con respaldo por 198.51.100.1; ruta `2.2.2.2/32` vía 203.0.113.1; `ping 2.2.2.2` 3/3.

## 5. Tiempos medidos

| Fase | Medición | Resultado |
| :---- | :---- | :---- |
| Corte | Hora (reloj ISP-1) | 03:27:11 |
| Detección en EDGE | Hold Timer Expired | 03:29:20 (reloj EDGE) → ≈ 129 s (125–129 s según offset de relojes) |
| Failover del default | Coincide con la caída de la sesión | `icmp_seq=150` pasa a responder ISP-2 |
| Impacto | Blackhole hacia ISP-1 | ≈ 2 min 9 s |
| Recuperación | ISP-1 habilitado → sesión `Established` | 03:34:01 → 03:34:04 ≈ 3 s |
| Recuperación | Respuesta a 2.2.2.2 en PC-USER | desde `icmp_seq=17` (pico de 824 ms en `icmp_seq=21`) |

El hold-time es de 180 s y se cuenta desde el último keepalive recibido, por eso el tiempo medido (129 s) es menor.

## 6. Post-mortem

- **Impacto:** ≈ 2 min de blackhole para el tráfico enviado por ISP-1. Durante ese lapso EDGE seguía usando el default de mayor local-pref sobre un enlace muerto.
- **Causa raíz:** deshabilitación intencional de ether1 en ISP-1 (drill). La detección dependió del hold-time BGP.
- **Qué funcionó:** al vencer el hold-time, failover automático al default de ISP-2 y reconexión de la sesión en ≈ 3 s al restaurar el enlace; ISP-2 y 3.3.3.3 no se vieron afectados.
- **Limitación del lab:** 2.2.2.2 solo existe vía ISP-1, así que no hay camino alternativo hacia él. El failover se verifica por el cambio del default, no por la conectividad a 2.2.2.2.
- **Riesgo residual:** sin BFD ni timers reducidos, una falla sin caída de interfaz produce un blackhole de hasta 180 s.
- **Mejora posible (no implementada ni probada):** BFD para las sesiones eBGP o reducir hold-time y keepalive, con el costo de mayor sensibilidad a flapping.

## 7. Evidencias

Carpeta `capturas/F4/`:

- `F4-drill3-base-EDGE.png`, `F4-drill3-base-ISP-1.png`, `F4-drill3-base-PC-USER.png`
- `F4-drill3-falla-EDGE.png`, `F4-drill3-falla-log-EDGE.png`, `F4-drill3-falla-PC-USER.png`
- `F4-drill3-recuperacion-EDGE.png`, `F4-drill3-recuperacion-log-EDGE.png`, `F4-drill3-recuperacion-PC-USER.png`
