# Runbook — Drill 2: caída del enlace DIST-1 ↔ CORE-2 (OSPF)

**Fecha:** 19–20/10/2026 · **Responsable:** R5 · **Fase:** F4
**Escenario:** se deshabilita `ether2` de DIST-1 (enlace 10.0.0.20/30 hacia CORE-2) con tráfico PC-USER → 2.2.2.2 en curso.

## 1. Estado base

- DIST-1: 2 vecinos OSPF `Full` (CORE-1 4.4.4.4 por ether1, CORE-2 5.5.5.5 por ether2).
- Default `0.0.0.0/0` (originada por EDGE) con 2 rutas ECMP: `10.0.0.13%ether1` y `10.0.0.21%ether2`, distancia 110.
- `trace 2.2.2.2` desde PC-USER: 192.168.10.1 → 10.0.0.21 (CORE-2) → 10.0.0.5 (EDGE) → 2.2.2.2.
- `/tool torch interface=ether2 ip-protocol=icmp` en DIST-1: ~1 paquete/s en TX y RX. Ida y vuelta del ping usan ether2.
- Prueba de tráfico: `ping 2.2.2.2 -i 200 -t` desde PC-USER.

## 2. Detección

- **Síntoma:** PC-USER pierde 1 paquete (`icmp_seq=20`).
- **Confirmación en DIST-1:** `/routing ospf neighbor print` muestra un solo vecino (CORE-1) y `/ip route print where dst-address=0.0.0.0/0` una sola ruta por ether1.
- **Confirmación en CORE-2:** `neighbor print` lista 3 vecinos (EDGE 1.1.1.1, CORE-1 4.4.4.4, DIST-2 7.7.7.7); el vecino 6.6.6.6 (DIST-1) ya no figura. No se midió cuánto tardó en desaparecer; el ping indica que la reconvergencia fue inferior al dead timer (40 s).

## 3. Respuesta

No requiere intervención manual. OSPF elimina la adyacencia y recalcula SPF: el tráfico pasa a CORE-1 (ether1 de DIST-1) y la ruta ECMP se reduce a una.

## 4. Recuperación

1. En DIST-1: `/interface enable ether2`.
2. Verificar en DIST-1:
   - `neighbor print`: vecino 5.5.5.5 `Full` con `adjacency=2s`.
   - `route print`: 2 rutas ECMP (ether1 y ether2).
3. Verificar en CORE-2: `neighbor print` muestra 4 vecinos `Full` (EDGE, CORE-1, DIST-1 y DIST-2); DIST-1 (6.6.6.6, 10.0.0.22) con `adjacency=18s` al momento de la consulta.

## 5. Tiempos medidos

| Fase | Medición | Resultado |
| :---- | :---- | :---- |
| Falla | Paquetes perdidos | 1 (`icmp_seq=20`) |
| Falla | Interrupción | < 1 s (1 paquete; el intervalo `-i 200` no se verificó con timestamps) |
| Recuperación | Adyacencia OSPF DIST-1↔CORE-2 | `Full` a los 2 s de habilitar la interfaz |
| Recuperación | Paquetes perdidos | 1 (`icmp_seq=32`) |

La pérdida de un solo paquete indica que este flujo no esperó el dead timer (40 s). No se midió qué mecanismo disparó la detección (en el Drill 3, un corte remoto equivalente no fue detectado por BGP hasta vencer el hold-time).

## 6. Post-mortem

- **Impacto:** pérdida de 1 paquete en el corte y 1 en la recuperación para un flujo único PC-USER → 2.2.2.2. Sin pérdida sostenida.
- **Causa raíz:** deshabilitación intencional de ether2 en DIST-1 (drill).
- **Qué funcionó:** redundancia ECMP entre CORE-1 y CORE-2, reconvergencia OSPF automática con autenticación MD5 activa y retorno a ECMP al restaurar el enlace.
- **Observación:** la pérdida en la recuperación se produce con el enlace ya funcionando; hipótesis, no medida: rebalanceo del flujo ECMP al volver la segunda ruta.
- **Riesgo residual:** sin BFD, una falla que no baje la interfaz se detectaría recién por el dead timer (40 s), como ocurrió con el hold-time en el Drill 3.
- **Mejora posible:** habilitar BFD para detección sub-segundo en caídas sin pérdida de carrier.

## 7. Evidencias

Carpeta `capturas/F4/`:

- `F4-drill2-base-DIST-1.png`, `F4-drill2-base-PC-USER.png`
- `F4-drill2-falla-DIST-1.png`, `F4-drill2-falla-CORE-2.png`, `F4-drill2-falla-PC-USER.png`
- `F4-drill2-recuperacion-DIST-1.png`, `F4-drill2-recuperacion-CORE-2.png`, `F4-drill2-recuperacion-PC-USER.png`
