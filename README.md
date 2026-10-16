# Failover Routing

## Materia

Gestión Operativa y Seguridad en Redes (GOYS) — UTN FRLP

## Proyecto

Laboratorio grupal de una red empresarial de cinco capas en GNS3,
con redundancia de gateway mediante VRRP, enrutamiento interno
OSPF y dos proveedores conectados mediante eBGP.

## Integrantes y roles

| Integrante | Responsabilidades |
|------------|-------------------|
| Facundo Daza | R1: Edge-WAN; R2: Proveedores; R5: QA/Ops en F1 y F3. |
| Irineo Hiriart | R3: Core; R4: Distribución; R5: QA/Ops en F2 y F4. |

## Estado del proyecto

F0, F1, F2 y F3 completadas.

| Fase | Resultado |
|------|-----------|
| F0 — Diseño | IPAM, corrección del diagrama, políticas y repositorio. |
| F1 — Topología y hardening | 7 CHR, 2 switches y 2 hosts conectados mediante 15 enlaces; IP y loopbacks configuradas. hardening, exports y snapshot BASE documentados. |
| F2 — VRRP y OSPF | Dos grupos VRRP con reparto de carga y autenticación. OSPF área 0 con MD5, incluido core-core. conectividad entre LAN verificada. |
| F3 — BGP y firewall | Dos sesiones eBGP con TCP-MD5; anuncios de las LAN filtrados; salida hacia loopbacks de ambos ISP; firewall y gestión restringida en EDGE. |

Se documentaron backups binarios cifrados y pruebas de restauración
desde exports: CORE-1 durante F2 e ISP-2 durante F3.


## Documentación y archivos

- `docs/memoria.md`: diseño, configuración, verificaciones y change log.
- `backlog.md`: tareas, responsables y estados.
- `configs/`: scripts y configuraciones por router y fase.
- `backups/`: exports fechados con claves censuradas.
- `capturas/`: evidencias organizadas por fase.
- `runbooks/`: procedimientos de los drills, pendientes para F4.

Los exports completos no deben importarse sobre equipos ya configurados
sin revisar previamente el procedimiento de restauración.

## Próximas etapas

- F4 — Drills y monitoreo: martes 20/10/2026.
- F5 — Memoria final y defensa: viernes 23/10/2026.