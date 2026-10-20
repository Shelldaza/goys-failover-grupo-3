# Runbook — Drill 4: check-gateway, failover estático de enlace

**Fecha:** 20/10/2026 · **Responsable:** R5 · **Fase:** F4
**Escenario:** ruta estática de prueba en EDGE con dos gateways y `check-gateway=ping`. Se deshabilita `ether1` de ISP-1 y se mide cuánto tarda EDGE en pasar al gateway de respaldo.

## 1. Preparación

Para no alterar el default BGP de producción se usa una ruta de **prueba** (9.9.9.9/32, prefijo inexistente) en EDGE, eliminada al terminar:

```
/ip route add dst-address=9.9.9.9/32 gateway=203.0.113.1 distance=1 check-gateway=ping comment="DRILL4-test"
/ip route add dst-address=9.9.9.9/32 gateway=198.51.100.1 distance=2 check-gateway=ping comment="DRILL4-test"
```

Estado base: ruta activa por 203.0.113.1 (distance 1, ISP-1); la de 198.51.100.1 (distance 2, ISP-2) como respaldo.

Medición: script en EDGE que imprime cada segundo la hora y el gateway de la ruta activa:

```
:for i from=1 to=150 do={ :local g [/ip route find where dst-address="9.9.9.9/32" active]; :if ([:len $g]>0) do={ :put ([/system clock get time]." ".[/ip route get ($g->0) gateway]) } else={ :put ([/system clock get time]." sin ruta activa") }; :delay 1s }
```

## 2. Detección

- **Corte:** en ISP-1, `/interface disable ether1` a las 04:12:46 (reloj de ISP-1). El script de EDGE arrancó a las 04:12:29 y mostró 203.0.113.1 de forma ininterrumpida hasta las 04:13:13.
- **Mecanismo:** `check-gateway=ping` sondea periódicamente el gateway; al no recibir respuesta marca la ruta como inactiva. No depende de que caiga la interfaz ni de ningún protocolo de ruteo.
- **Confirmación:** a las 04:13:14 (reloj de EDGE) el gateway activo pasa a 198.51.100.1.

## 3. Respuesta

Automática. La ruta con distance 1 queda inactiva y se activa la de distance 2 por ISP-2. Sin intervención manual y sin "sin ruta activa" en ningún momento del monitor.

## 4. Recuperación

1. En ISP-1: `/interface enable ether1` a las 04:13:23 (reloj de ISP-1).
2. El monitor vuelve a 203.0.113.1 a las 04:13:33 (reloj de EDGE).
3. Limpieza: `/ip route remove [find comment="DRILL4-test"]` y verificación con `/ip route print where dst-address=9.9.9.9/32` (lista vacía).

## 5. Tiempos medidos

El `clock print` de ISP-1 de la preparación no quedó registrado. Se usa el offset máximo medido en el Drill 3 (ISP-1 adelantado hasta 4 s respecto de EDGE).

| Fase | Medición | Resultado |
| :---- | :---- | :---- |
| Corte → failover | 04:12:46 (ISP-1) → 04:13:14 (EDGE) | ≈ 28 s (28–32 s según offset) |
| Habilitación → failback | 04:13:23 (ISP-1) → 04:13:33 (EDGE) | ≈ 10 s (10–14 s según offset) |
| Rutas sin gateway activo | Monitor | ninguna |

Comparación con el Drill 3: BGP tardó ≈ 129 s en detectar la misma falla (hold-time); `check-gateway=ping` la detectó en ≈ 28 s.

## 6. Post-mortem

- **Por qué funcionó:** `check-gateway=ping` verifica la alcanzabilidad real del siguiente salto, aunque la interfaz local siga en `up`.
- **Qué aprendimos:** la detección por sondeo (≈ 28 s) es mucho más rápida que esperar el hold-time BGP (≈ 129 s) en una falla sin caída de interfaz, pero sigue siendo del orden de decenas de segundos.
- **Limitación:** la medición tiene resolución de 1 s y la incertidumbre del offset de relojes (hasta 4 s). La ruta de prueba no transporta tráfico real; se midió el cambio de ruta activa, no la pérdida de paquetes.
- **Riesgo residual:** `check-gateway` solo verifica el siguiente salto, no el camino completo hasta destino.
- **Mejora posible (no implementada):** BFD para detección sub-segundo.

## 7. Evidencias

Carpeta `capturas/F4/`:

- `F4-drill4-base-EDGE.png`
- `F4-drill4-falla-ISP-1.png`, `F4-drill4-falla-EDGE.png`
- `F4-drill4-recuperacion-ISP-1.png`, `F4-drill4-recuperacion-EDGE.png`
- `F4-drill4-limpieza-EDGE.png`
