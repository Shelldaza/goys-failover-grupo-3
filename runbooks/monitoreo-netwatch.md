# Runbook — Monitoreo: chequeos activos con Netwatch en DIST-1

**Fecha:** 20/10/2026 · **Responsable:** R4 / R5 · **Fase:** F4
**Objetivo:** habilitar y documentar chequeos de disponibilidad y documentar las tablas de ruteo.

## 1. Decisión de diseño

- Se implementan **chequeos activos con Netwatch** (la consigna admite "SNMP/chequeos").
- No se habilita SNMP: el laboratorio no tiene ningún cliente SNMP para verificarlo y la comunidad sería otro secreto fuera del repositorio.
- Ubicación: DIST-1. Desde ahí se ve el camino completo hacia el core, los ISP y la LAN de servidores.

## 2. Configuración (DIST-1)

Cinco chequeos ICMP, intervalo 10 s, timeout 1 s. Al cambiar de estado escriben una línea en el log (`:log warning` en DOWN, `:log info` en UP):

| Nombre | Destino | Qué verifica |
| :---- | :---- | :---- |
| ISP-1-lo | 2.2.2.2 | camino completo hasta el loopback de ISP-1 (OSPF + BGP) |
| ISP-2-lo | 3.3.3.3 | camino completo hasta el loopback de ISP-2 |
| SRV | 192.168.20.100 | LAN de servidores |
| CORE-1 | 10.0.0.13 | enlace DIST-1 ↔ CORE-1 |
| CORE-2 | 10.0.0.21 | enlace DIST-1 ↔ CORE-2 |

Ejemplo (los cinco siguen el mismo formato):

```
/tool netwatch add name=ISP-1-lo host=2.2.2.2 type=icmp interval=10s timeout=1s comment="F4 monitoreo" down-script=":log warning \"NETWATCH: 2.2.2.2 ISP-1 DOWN\"" up-script=":log info \"NETWATCH: 2.2.2.2 ISP-1 UP\""
```

### Hallazgo: origen del ping

Al crearlos, `2.2.2.2` y `3.3.3.3` quedaron `down` sin ninguna falla en la red (04:57:23). Causa: Netwatch usa como origen la IP del enlace saliente (10.0.0.x), y EDGE solo anuncia a los ISP las LAN 192.168.10.0/24 y 192.168.20.0/24 (filtro `F3-EDGE-OUT`). Los ISP no tienen ruta de vuelta hacia 10.0.0.0/24, por lo que no pueden contestar. Corrección: fijar como origen la IP de DIST-1 en la LAN anunciada:

```
/tool netwatch set [find name=ISP-1-lo] src-address=192.168.10.2
/tool netwatch set [find name=ISP-2-lo] src-address=192.168.10.2
```

Resultado: ambos en `up` a las 05:01:30 y 05:01:31.

## 3. Prueba de detección

1. Estado base: los 5 chequeos en `up`.
2. En ISP-1: `/interface disable ether1` a las 05:02:53 (reloj de ISP-1).
3. DIST-1 registra `NETWATCH: 2.2.2.2 ISP-1 DOWN` a las 05:03:01. Los otros 4 chequeos siguen en `up`.
4. En ISP-1: `/interface enable ether1` a las 05:03:30.
5. DIST-1 registra `NETWATCH: 2.2.2.2 ISP-1 UP` a las 05:03:40.

| Fase | Medición | Resultado |
| :---- | :---- | :---- |
| Detección de la caída | corte → DOWN en el log | ≈ 8 s |
| Detección de la recuperación | enable → UP en el log | ≈ 10 s |

La resolución depende del intervalo de 10 s y de la diferencia entre los relojes de ISP-1 y DIST-1 (pocos segundos), por lo que los valores son aproximados.

## 4. Tablas de ruteo (`/routing route print` en DIST-1)

- Default `0.0.0.0/0` por OSPF con dos rutas ECMP: `10.0.0.13%ether1` (CORE-1) y `10.0.0.21%ether2` (CORE-2), distancia 110.
- Loopbacks por OSPF: 1.1.1.1/32 y 7.7.7.7/32 con ECMP; 4.4.4.4/32 solo por ether1 (CORE-1) y 5.5.5.5/32 solo por ether2 (CORE-2); 6.6.6.6/32 conectada (`lo`).
- Enlaces /30 de infraestructura: los directamente conectados (10.0.0.12/30 y 10.0.0.20/30) como `Ac`, el resto aprendido por OSPF.
- LAN: 192.168.10.0/24 conectada por `ether3` y `vrrp10`; 192.168.20.0/24 conectada por `ether4`.
- DIST-1 **no** tiene rutas BGP: el acceso a 2.2.2.2 y 3.3.3.3 pasa por el default que EDGE origina por OSPF (`originate-default=if-installed`).

## 5. Post-mortem

- **Qué funcionó:** los chequeos detectaron la caída del camino a ISP-1 en ≈ 8 s y la recuperación en ≈ 10 s, sin falsos positivos en los otros destinos. Es notablemente más rápido que el hold-time BGP (≈ 129 s, Drill 3).
- **Qué aprendimos:** un chequeo end-to-end depende de la ruta de vuelta. El filtro de salida de EDGE limita lo que los ISP conocen, por lo que el origen del sondeo debe estar en un prefijo anunciado.
- **Limitaciones:** el monitoreo vive en un solo router y no envía alertas externas (solo log local); no hay métricas históricas.
- **Mejoras posibles (no implementadas):** exportar el log a un servidor syslog y habilitar SNMPv3 con un cliente de consulta.

## 6. Evidencias

Carpeta `capturas/F4/`:

- `F4-monitoreo-config-DIST-1.png`
- `F4-monitoreo-rutas-DIST-1.png`
- `F4-monitoreo-down-DIST-1.png`, `F4-monitoreo-up-DIST-1.png`
- `F4-monitoreo-falla-ISP-1.png`, `F4-monitoreo-recuperacion-ISP-1.png` (si se tomaron)
