# Failover Routing

## Materia

Gestión Operativa y Seguridad en Redes (GOYS) — UTN FRLP

## Proyecto

Laboratorio grupal de una red empresarial de cinco capas en GNS3, con redundancia de gateway mediante VRRP, enrutamiento interno OSPF y dos proveedores conectados mediante eBGP.

**Grupo:** 3  
**Fecha limite de entrega:** viernes 23/10/2026  
**Plataforma:** GNS3 y MikroTik CHR con RouterOS 7.16.

## Integrantes y roles

| Integrante | Responsabilidades |
|------------|-------------------|
| Facundo Daza | R1: Edge-WAN; R2: Proveedores; R5: QA/Ops en F1 y F3. |
| Irineo Hiriart | R3: Core; R4: Distribución; R5: QA/Ops en F2 y F4. |

## Estado del proyecto

Se ha completado las 5 Fases del laboratorio.

| Fase | Resultado |
|------|-----------|
| F0 — Diseño | IPAM, corrección del diagrama, políticas y repositorio. |
| F1 — Topología y hardening | 7 CHR, 2 switches y 2 hosts conectados mediante 15 enlaces. Direccionamiento, hardening, exports y snapshot BASE documentados. |
| F2 — VRRP y OSPF | Dos grupos VRRP con reparto de carga y autenticación AH. OSPF área 0 con MD5, incluido core-core. Conectividad entre LAN verificada. |
| F3 — BGP y firewall | Dos sesiones eBGP con TCP-MD5, anuncios de las LAN filtrados, conectividad hacia las loopbacks de ambos ISP y firewall con gestión restringida en EDGE. |
| F4 — Drills y monitoreo | Cinco escenarios documentados con runbooks y post-mortem; tiempos registrados en los escenarios con falla. Prueba de clave OSPF incorrecta y monitoreo con Netwatch. |
| F5 — Cierre y defensa | Siete configuraciones finales organizadas, VIP VRRP corregidas a /32, verificaciones funcionales documentadas y memoria final con conclusiones y trazabilidad de cambios. |

Se documentaron backups binarios cifrados y pruebas de restauración desde exports: CORE-1 durante F2 e ISP-2 durante F3.

## Documentación y archivos

- [Memoria técnica](docs/memoria.md): diseño, configuración, verificaciones, conclusiones y change log.
- [Backlog](backlog.md): tareas, responsables y estados.
- [Configuraciones finales](configs/final/): exports de los siete routers correspondientes a sus últimos estados documentados.
- [Configuraciones por fase](configs/): scripts y configuraciones de implementación.
- [Backups](backups/): exports fechados con claves visibles censuradas.
- [Capturas](capturas/): evidencias organizadas por fase, incluidas las verificaciones finales de F5.
- [Runbooks](runbooks/): procedimientos, resultados y limitaciones de los drills, verificación de seguridad, monitoreo y post-mortem global.

## Restauración

Los archivos de `configs/final/` son exports completos y no scripts incrementales para ejecutar sobre una configuración existente.

La restauración requiere reponer las claves omitidas o censuradas y recrear los usuarios y sus contraseñas, conforme al procedimiento documentado en la memoria.

Los backups binarios contienen información sensible, no se versionan y permanecen en el almacenamiento de los routers.

## Alcance y limitaciones

- Los ISP simulan proveedores externos y las pruebas no requieren acceso a Internet real.
- EDGE constituye un punto único de falla.
- La loopback de cada ISP depende de ese proveedor. El cambio de la ruta por defecto demuestra la selección del proveedor alternativo, pero no la continuidad hacia un destino común.
- Netwatch registra cambios de disponibilidad localmente; no se configuraron alertas externas ni acciones automáticas de failover.
- Los tiempos de convergencia documentados corresponden a los drills de F4. Tras ajustar las máscaras de las VIP en F5, se verificaron los roles VRRP, las adyacencias OSPF y la conectividad.

## Entrega

la fecha límite era el viernes 23/10/2026, nosotros lo entregamos e informamos el 22/10/2026, es decir acorde al tiempo definido.

La memoria, los respaldos textuales, las configuraciones finales, las evidencias y los runbooks se encuentran organizados en este repositorio. El cumplimiento de las tareas se registra en `backlog.md`.

La defensa comprende la explicación de la parte propia y de una parte realizada por el otro integrante.