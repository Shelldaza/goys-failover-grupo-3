# Post-mortem global — Epic F4 (drills de failover)

**Fecha:** 20/10/2026 · **Responsable:** R5 · **Runbooks:** un archivo por drill en esta carpeta.

## 1. Resumen de resultados

| Drill | Escenario | Detección | Tiempo medido | Recuperación |
| :---- | :---- | :---- | :---- | :---- |
| 1 — VRRP | Apagado de DIST-1 (master vrid 10) | Pérdida del gateway virtual | ≈ 2,8 s (±1 s), 1 paquete perdido | Failback sin pérdida de paquetes (un pico de 834 ms) |
| 2 — OSPF | `ether2` de DIST-1 deshabilitada (enlace a CORE-2) | Adyacencia con CORE-2 caída | 1 paquete perdido (< 1 s, no medible con precisión) | Adyacencia `Full` a los 2 s; 1 paquete perdido |
| 3 — BGP | `ether1` de ISP-1 deshabilitada | Hold Timer Expired en EDGE | ≈ 129 s de blackhole | Sesión `Established` en ≈ 3 s |
| 4 — check-gateway | Mismo corte, con ruta estática de prueba | `check-gateway=ping` | ≈ 28 s | ≈ 10 s |
| 5 — Load-sharing VRRP | Sin falla: ambos DIST activos | `vrrp print` en ambos | No aplica | No aplica |

Verificación de seguridad (clave OSPF MD5 incorrecta en CORE-1): primer rechazo `md5 mismatch` a las 04:42:52 y adyacencia `Down` a las 04:43:22. Monitoreo con Netwatch: caída detectada en ≈ 8 s y recuperación en ≈ 10 s.

## 2. Qué funcionó

- La redundancia diseñada responde sin intervención manual: VRRP, ECMP en OSPF y el default de respaldo por BGP.
- Los tiempos de VRRP y OSPF son del orden de pocos segundos; en ambos casos la pérdida se limitó a 1–2 paquetes.
- La autenticación MD5 cumple su función: con una clave incorrecta la adyacencia no se forma y el log registra el rechazo.

## 3. Qué aprendimos

1. **La detección domina el tiempo de recuperación.** La misma falla (corte del enlace a ISP-1) se detectó en ≈ 129 s por BGP (hold-time), en ≈ 28 s por `check-gateway=ping` y en ≈ 8 s por un chequeo de 10 s en Netwatch. Los valores por defecto de BGP dejan un blackhole de varios minutos si no cae la interfaz.
2. **El failover no siempre es visible en el tráfico del lab.** 2.2.2.2 solo existe por ISP-1, así que al caer ISP-1 no hay camino alternativo hacia él. El failover se verifica por el cambio del default activo, no por la conectividad a ese destino.
3. **Los filtros de F3 condicionan el monitoreo.** Los ISP solo conocen las LAN, por lo que un chequeo debe originarse en un prefijo anunciado (corrección con `src-address` en Netwatch).
4. **Una clave MD5 en OSPF es por template.** Un único template con una clave sirve a todos los enlaces del router; un error de clave afecta todas sus adyacencias. Un primer intento con `find where interfaces=ether2` no aplicó ningún cambio porque el template se define por red.

## 4. Limitaciones de la medición

- Los pings de VPCS tienen resolución de ≈ 1 s. El intervalo `-i 200` usado en los drills 2 y 3 no se verificó con marcas de tiempo, por lo que no se usó el número de secuencia como reloj.
- Los relojes de los routers difieren entre sí en pocos segundos; los tiempos derivados de dos relojes son aproximados.
- El Drill 4 mide el cambio de ruta activa sobre una ruta de prueba (9.9.9.9/32), no la pérdida de paquetes de tráfico real. La ruta se eliminó al terminar.
- El Drill 5 no incluye falla ni tiempo medido, conforme a la plantilla de la memoria.
- La verificación de clave incorrecta se hizo solo con OSPF; no se repitió con BGP ni con VRRP.
- El monitoreo se implementó con chequeos activos (Netwatch) y logs locales; no se habilitó SNMP.

## 5. Riesgos residuales y mejoras

| Riesgo | Mejora posible (no implementada) |
| :---- | :---- |
| Blackhole de hasta 180 s por hold-time BGP | BFD o timers BGP reducidos |
| Un único EDGE (SPOF, documentado en la memoria) | Par HA en producción |
| Pico de ≈ 0,8 s al cambiar de master VRRP | Reducir el intervalo de advertisement y repetir con mayor resolución |
| Monitoreo local, sin alertas externas | Syslog remoto y SNMPv3 con cliente |
| El balanceo VRRP es por LAN, no por flujo | Revisar el reparto si el tráfico entre LAN es desigual |

## 6. Evidencias

Ver la sección 7 de cada runbook y la carpeta `capturas/F4/`.
