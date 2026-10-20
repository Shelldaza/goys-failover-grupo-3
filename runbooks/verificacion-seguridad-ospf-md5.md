# Runbook — Verificación de seguridad: clave OSPF MD5 incorrecta en CORE-1

**Fecha:** 20/10/2026 · **Responsable:** R3 / R5 · **Fase:** F4
**Objetivo:** demostrar que una adyacencia OSPF con clave MD5 incorrecta **falla**.

## 1. Estado base

- CORE-1 y CORE-2 con sus vecinos OSPF en `Full` (CORE-1↔CORE-2 por 10.0.0.8/30, router-ids 4.4.4.4 y 5.5.5.5).
- En CORE-1 existe un único template de interfaz para todos los enlaces internos: `networks=10.0.0.0/24 area=backbone auth=md5 auth-id=1` (índice 0). La clave MD5 se define por template, no por enlace.

## 2. Procedimiento

1. En CORE-1: `/routing ospf interface-template set 0 auth-key=CLAVE-INC-TEST` (clave de prueba, distinta de la real).
2. Observar `/routing ospf neighbor print` y `/log print where message~"authentication failed|timeout"` en CORE-1 y CORE-2.

Primer intento descartado: `set [find where interfaces=ether2]` no encontró ningún template (el template se define por red, no por interfaz), por lo que el comando no aplicó ningún cambio y la adyacencia siguió `Full`.

## 3. Detección (evidencia en el log de CORE-2)

- 04:42:52 `authentication failed from 10.0.0.9 md5 mismatch` en `ether2` (primer rechazo de CORE-2 a los paquetes de CORE-1). Se repite cada 10 s (hello-interval).
- 04:43:22 el vecino 4.4.4.4 pasa por `timeout` a `Down` (dead-timer de 40 s).

## 4. Respuesta

OSPF descarta los paquetes con firma MD5 inválida. No se forma ni se mantiene la adyacencia con el router que usa la clave incorrecta. El resto de la red mantiene conectividad por los caminos redundantes (CORE-2).

## 5. Recuperación

1. En CORE-1: `/routing ospf interface-template set 0 auth-key=<CLAVE_OSPF>` (clave real, compartida fuera del repo; no se documenta).
2. Tras ~45 s, `/routing ospf neighbor print` en CORE-1 y CORE-2: 4 vecinos `Full` en cada uno.

## 6. Tiempos

| Fase | Medición | Resultado |
| :---- | :---- | :---- |
| Primer rechazo por MD5 | Log CORE-2 | 04:42:52 |
| Adyacencia caída | Log CORE-2 | 04:43:22 (≈ 40 s desde el último hello válido, dead-timer) |
| Restauración | Neighbor print | 4 vecinos `Full` tras ~45 s |

Las horas exactas del comando de cambio y de la restauración no se registraron con `clock print`; los tiempos se derivan del log.

## 7. Post-mortem

- **Resultado:** con clave incorrecta, la adyacencia **falla** y queda documentada en el log (`md5 mismatch`). El plano de control no acepta vecinos sin la clave.
- **Qué aprendimos:** el template aplica una sola clave a todos los enlaces del router, por lo que un error de clave afecta a todas sus adyacencias, no solo a una. Un cambio de clave debe hacerse de forma coordinada entre vecinos.
- **Riesgo residual:** la clave OSPF aparece en texto plano en `/export` (por eso los exports del repo están censurados) y se comparte por fuera del repositorio (limitación documentada en la memoria).

## 8. Evidencias

Carpeta `capturas/F4/`:

- `F4-seguridad-base-CORE-1.png`, `F4-seguridad-base-CORE-2.png`
- `F4-seguridad-cambio-CORE-1.png`
- `F4-seguridad-falla-CORE-1.png`, `F4-seguridad-falla-CORE-2.png`
- `F4-seguridad-log-CORE-1.png`, `F4-seguridad-log-CORE-2.png`
- `F4-seguridad-recuperacion-CORE-1.png`, `F4-seguridad-recuperacion-CORE-2.png`
