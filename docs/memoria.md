# Memoria del Laboratorio — Failover Routing

**Grupo:** 3

**Materia:** Gestión Operativa y Seguridad en Redes (GOYS)

**Fecha de entrega:** viernes 23/10/2026

## Integrantes y roles

| Integrante | Rol |
|-----------|-----|
| Facundo Daza | R1 (Líder / Edge-WAN) + R2 (Proveedores) + R5 (QA/Ops Fases 1 y 3) |
| Irineo Hiriart | R3 (Core) + R4 (Distribución) + R5 (QA/Ops Fases 2 y 4) |

---

## 1. Diseño (F0)

### 1.1 Corrección del diagrama

| # | Defecto detectado | Corrección aplicada | Justificación |
|:-:|-------------------|---------------------|---------------|
| 1 | Subredes solapadas entre segmentos de acceso del diagrama original. | Se asignó `192.168.10.0/24` para usuarios y `192.168.20.0/24` para servidores. | Evita ambigüedades de direccionamiento y permite anunciar y enrutar cada red correctamente. |
| 2 | Ausencia de enlace core-core. | Se agregó un enlace directo L3 (`10.0.0.8/30`) entre CORE-1 y CORE-2. | Proporciona un camino adicional dentro del backbone OSPF y mejora la conectividad ante determinadas fallas de enlace. |
| 3 | Redundancia de gateway ubicada en el Core. | Se desplazó la redundancia de gateway a los routers CHR DIST-1 y DIST-2 mediante VRRP. | Mantiene al Core como capa de tránsito y ubica los gateways de las LAN en Distribución. |
| 4 | Firewall sin par HA, constituyendo un punto único de falla. | Se implementó el filtrado en un único EDGE, conforme a la topología del laboratorio, y se documentó la necesidad de un par en failover con sincronización de estado en producción. | La doble conexión a ISP protege frente a la caída de un proveedor, pero no frente a la caída de EDGE. Esta es una limitación conocida del laboratorio. |
| 5 | Route Reflector iBGP mal ubicado en el diagrama original. | Se eliminó el RR. EDGE mantiene dos sesiones eBGP, una por ISP, sin iBGP. | Con un único router de borde no hay otros speakers iBGP a los que reflejar rutas. Las sesiones con los proveedores corresponden a eBGP. |

### 1.2 Plan de direccionamiento (IPAM)

Las interfaces de la tabla corresponden a sus nombres reales en RouterOS.

| Enlace / Red | Subred | Dispositivo A (IP / interfaz) | Dispositivo B (IP / interfaz) |
|--------------|--------|-------------------------------|-------------------------------|
| ISP-1 ↔ EDGE | `203.0.113.0/30` | ISP-1: `203.0.113.1`, ether1 | EDGE: `203.0.113.2`, ether1 |
| ISP-2 ↔ EDGE | `198.51.100.0/30` | ISP-2: `198.51.100.1`, ether1 | EDGE: `198.51.100.2`, ether2 |
| EDGE ↔ CORE-1 | `10.0.0.0/30` | EDGE: `10.0.0.1`, ether3 | CORE-1: `10.0.0.2`, ether1 |
| EDGE ↔ CORE-2 | `10.0.0.4/30` | EDGE: `10.0.0.5`, ether4 | CORE-2: `10.0.0.6`, ether1 |
| CORE-1 ↔ CORE-2 | `10.0.0.8/30` | CORE-1: `10.0.0.9`, ether2 | CORE-2: `10.0.0.10`, ether2 |
| CORE-1 ↔ DIST-1 | `10.0.0.12/30` | CORE-1: `10.0.0.13`, ether3 | DIST-1: `10.0.0.14`, ether1 |
| CORE-1 ↔ DIST-2 | `10.0.0.16/30` | CORE-1: `10.0.0.17`, ether4 | DIST-2: `10.0.0.18`, ether1 |
| CORE-2 ↔ DIST-1 | `10.0.0.20/30` | CORE-2: `10.0.0.21`, ether3 | DIST-1: `10.0.0.22`, ether2 |
| CORE-2 ↔ DIST-2 | `10.0.0.24/30` | CORE-2: `10.0.0.25`, ether4 | DIST-2: `10.0.0.26`, ether2 |
| USERS | `192.168.10.0/24` | DIST-1: `192.168.10.2`, ether3 | DIST-2: `192.168.10.3`, ether3 |
| SERVERS | `192.168.20.0/24` | DIST-1: `192.168.20.2`, ether4 | DIST-2: `192.168.20.3`, ether4 |

**Hosts:**

| Host | Dirección | Gateway |
|------|-----------|---------|
| PC-USER | `192.168.10.100/24` | `192.168.10.1` |
| SRV | `192.168.20.100/24` | `192.168.20.1` |

**VRRP:**

| Grupo | VRID | Master preferido | Prioridad master / backup | IP virtual |
|-------|:----:|------------------|:-------------------------:|------------|
| USERS | 10 | DIST-1 | 150 / 100 | `192.168.10.1` |
| SERVERS | 20 | DIST-2 | 150 / 100 | `192.168.20.1` |

**Loopbacks y Router-IDs:**

| Router | Loopback | Uso como Router-ID |
|--------|----------|-------------------|
| EDGE | `1.1.1.1/32` | OSPF y BGP |
| ISP-1 | `2.2.2.2/32` | BGP |
| ISP-2 | `3.3.3.3/32` | BGP |
| CORE-1 | `4.4.4.4/32` | OSPF |
| CORE-2 | `5.5.5.5/32` | OSPF |
| DIST-1 | `6.6.6.6/32` | OSPF |
| DIST-2 | `7.7.7.7/32` | OSPF |

Las loopbacks se configuraron sobre la interfaz `lo`. Estas direcciones se utilizan dentro del laboratorio aislado.

**Sistemas autónomos:**

| Equipo | AS |
|--------|----|
| EDGE | 65000 |
| ISP-1 | 65001 |
| ISP-2 | 65002 |

### 1.3 Política de seguridad

- **Usuarios y privilegios:** usuario `admin` deshabilitado; `netadmin` con grupo `full` para configuración y `monitor` con el grupo personalizado `monitoring`, cuyos permisos son `local,read,winbox`.
- **Servicios deshabilitados:** Telnet, FTP, HTTP, HTTPS, SSH, API y API-SSL. También MAC-Telnet, MAC-Winbox y MAC-Ping.
- **Gestión permitida:** consola local de GNS3 y Winbox por IP. En EDGE, desde F3, Winbox se limita a `192.168.10.100/32` mediante el servicio y el firewall. El puerto predeterminado no constituye por sí solo una medida de seguridad.
- **Interfaces:** se deshabilitan las interfaces Ethernet que no participan en la topología.
- **Direccionamiento:** se utiliza configuración estática. Los clientes DHCP preconfigurados en ether1 se mantienen deshabilitados.
- **Claves de autenticación:** cada protocolo utiliza una clave distinta. No se versionan las claves OSPF, BGP ni VRRP. En las copias destinadas al repositorio se reemplazan los valores visibles por `<CLAVE_OSPF>`, `<CLAVE_BGP>`, `<CLAVE_VRRP>` o `REDACTED`; otros valores sensibles pueden quedar omitidos por el propio export.
- **Rotación:** las claves iniciales de F0 se publicaron por error y se retiraron. Se documentó su rotación el 15/10/2026 y se configuró una clave BGP nueva al implementar F3 el 16/10/2026.
- **Intercambio de claves:** se guardan fuera del repositorio y se comparten entre los integrantes por mensajería privada.

La mensajería privada no reemplaza a un gestor de secretos: las claves quedan en el historial y no existe una auditoría específica de acceso y rotación. Se acepta como mecanismo del laboratorio; en producción corresponde un gestor de secretos con control de acceso y auditoría.

### 1.4 Política de operación

**Gestión de cambios.** Se utiliza Conventional Commits:

`tipo(alcance): descripción [ROL]`

Cada cambio debe representar una unidad lógica y vincularse al rol correspondiente. El change log de la sección 6.1 debe reflejar el historial real del repositorio.

**Exports.** Tras estabilizar F1, F2 y F3 se ejecuta `/export file=backup-<nodo>-<fecha>` en los routers modificados. RouterOS agrega la extensión `.rsc`. Las copias para Git se guardan en `backups/`, previa revisión de claves visibles.

**Verificación de DHCP.** Antes de versionar cada export, se comprueba que el cliente DHCP de ether1 figure con `disabled=yes`. Si no coincide con la política, se revisa la configuración activa y se vuelve a exportar.

**Backups binarios.** Además del export textual, se genera `/system backup save name=backup-<nodo>-<fecha> password=<clave>`. El backup contiene usuarios y claves, por lo que se cifra con una contraseña guardada fuera del repositorio. Los archivos `.backup` permanecen en el almacenamiento de los routers y no se versionan; `*.backup` está incluido en `.gitignore`. Su existencia se documenta mediante `/file print`.

Mantener el backup únicamente dentro del router es una limitación operativa: no protege frente a la pérdida del almacenamiento del proyecto.

**Pruebas de restauración.** Al cerrar cada fase con backup se prueba la restauración de un nodo, preferentemente sobre una copia aislada del proyecto:

1. Generar el export y registrar el estado de referencia.
2. Restablecer el nodo de prueba sin configuración predeterminada.
3. Importar el `.rsc`.
4. Reponer las claves vigentes de OSPF, BGP y VRRP que correspondan. Los valores `REDACTED` no son claves válidas.
5. Recrear los usuarios `netadmin` y `monitor`, asignar sus contraseñas y deshabilitar `admin` después de comprobar el acceso administrativo.
6. Comparar direcciones, servicios, reglas y protocolos con el estado de referencia.

Revertir un commit de configuración no modifica automáticamente los routers: la reversión operativa debe ejecutarse y verificarse por separado.

---

## 2. Topología

Se implementó en GNS3 una topología de cinco capas: Internet, Edge, Core, Distribución y Acceso. Está compuesta por siete routers MikroTik CHR con RouterOS 7.16, dos switches Ethernet y dos hosts VPCS, conectados mediante 15 enlaces.

Cada switch de acceso conecta su host con ambos routers de distribución. USERS y SERVERS constituyen segmentos separados. Se incorporó el enlace L3 directo entre CORE-1 y CORE-2.

Los routers ISP simulan los proveedores externos. No se requiere conexión a Internet real para las pruebas previstas.

![Topología F1](../capturas/F1/F1-topologia.png)

---

## 3. Configuración

### 3.1 Configuración base — F1

Se configuraron las identidades, las direcciones de los enlaces /30, las direcciones reales de distribución en las LAN y las loopbacks /32 sobre la interfaz `lo`, conforme al IPAM.

PC-USER tiene `192.168.10.100/24` y gateway `192.168.10.1`. SRV tiene `192.168.20.100/24` y gateway `192.168.20.1`.

Al finalizar F1, los gateways virtuales quedaron reservados para VRRP en F2. Los clientes DHCP preconfigurados en ether1 se deshabilitaron.

Los exports de la configuración base se encuentran en `backups/`. OSPF, VRRP y BGP se implementaron posteriormente, como se describe en las secciones siguientes.

### 3.2 VRRP y OSPF — F2

**OSPF.** Se configuró la instancia `ospf-main` de OSPFv2 con área `backbone` (`0.0.0.0`) en EDGE, CORE-1, CORE-2, DIST-1 y DIST-2. El Router-ID de cada equipo corresponde a su loopback.

Una interface-template cubre `10.0.0.0/24`, con `type=ptp` y autenticación MD5. Esa selección incluye todos los enlaces /30 internos y el enlace core-core. Las loopbacks y las LAN de distribución se anuncian mediante interfaces pasivas.

Los enlaces entre EDGE y los ISP quedan fuera de OSPF y utilizan BGP desde F3.

**VRRP.** Se configuraron dos grupos en ambos routers de distribución:

| Grupo | VRID | Interfaz | IP virtual | MAC virtual | Master preferido, prioridad 150 | Backup, prioridad 100 |
|-------|:----:|----------|------------|-------------|--------------------------------|----------------------|
| USERS | 10 | ether3 | `192.168.10.1` | `00:00:5E:00:01:0A` | DIST-1 | DIST-2 |
| SERVERS | 20 | ether4 | `192.168.20.1` | `00:00:5E:00:01:14` | DIST-2 | DIST-1 |

Se utiliza VRRPv2 con autenticación AH. Cada router es master preferido de una LAN y backup de la otra.

Los scripts aplicados en F2 están en `configs/`:

- `F2-edge.rsc`
- `F2-core-1.rsc`
- `F2-core-2.rsc`
- `F2-dist-1.rsc`
- `F2-dist-2.rsc`
- `F2-vrrp-dist-1.rsc`
- `F2-vrrp-dist-2.rsc`

### 3.3 BGP y salida al exterior — F3

EDGE pertenece al AS 65000 y mantiene dos sesiones eBGP: una con ISP-1, AS 65001, y otra con ISP-2, AS 65002. Ambas utilizan autenticación TCP-MD5.

| Conexión en EDGE | IP local | IP del vecino | AS remoto |
|-----------------|----------|---------------|-----------|
| F3-ISP-1 | `203.0.113.2` | `203.0.113.1` | 65001 |
| F3-ISP-2 | `198.51.100.2` | `198.51.100.1` | 65002 |

Se configuró `output.redistribute=ospf` en EDGE. El filtro `F3-EDGE-OUT` permite anunciar únicamente `192.168.10.0/24` y `192.168.20.0/24`, rechazando los demás prefijos.

Los filtros de entrada de los ISP aceptan únicamente esas dos LAN. Cada ISP anuncia su propia loopback mediante redistribución de conectadas, limitada por su filtro de salida, y una ruta por defecto mediante `output.default-originate=always`.

EDGE acepta desde ISP-1 `2.2.2.2/32` y la default; desde ISP-2 acepta `3.3.3.3/32` y la default. Los demás prefijos quedan rechazados.

La default recibida de ISP-1 tiene `bgp-local-pref=200`; la de ISP-2, `bgp-local-pref=100`. Se establece así una salida preferida por ISP-1 y una alternativa por ISP-2. Las rutas específicas a las loopbacks utilizan el proveedor que las anuncia.

En la instancia `ospf-main` de EDGE se configuró `originate-default=if-installed`, para anunciar una ruta por defecto al interior cuando EDGE tiene una instalada. No se redistribuye la tabla BGP completa hacia OSPF.

No se configuró NAT: los ISP aprenden las LAN mediante BGP y disponen de rutas de retorno hacia los hosts.

El exterior es simulado. Las pruebas utilizan las loopbacks de los proveedores; no representan acceso a Internet real. La loopback de cada ISP depende de ese proveedor y no constituye un destino común accesible a través de ambos.

Durante la revisión de los exports se detectaron dos conexiones BGP duplicadas en EDGE. Se deshabilitaron, se comprobó que las dos sesiones necesarias continuaban establecidas y luego se eliminaron. Finalmente se regeneró el export de EDGE.
Las configuraciones completas posteriores a F3 se encuentran en:

- configs/F3-edge.rsc
- configs/F3-isp-1.rsc
- configs/F3-isp-2.rsc

Estos archivos son exports completos del estado de cada router,
no scripts incrementales para aplicar sobre una configuración existente.
Para restaurarlos se requiere un equipo de prueba sin configuración,
reponer las claves omitidas o censuradas y recrear los usuarios.

Los mismos estados se conservan en backups/ mediante archivos fechados.

### 3.4 Firewall de EDGE — F3

Se crearon las siguientes listas:

| Lista | Miembros |
|-------|----------|
| F3-WAN | ether1 y ether2 |
| F3-CORE | ether3 y ether4 |
| F3-LANS, de direcciones | `192.168.10.0/24` y `192.168.20.0/24` |

La cadena `input` permite conexiones establecidas y relacionadas, descarta conexiones inválidas y autoriza:

- BGP TCP/179 desde cada ISP por su interfaz correspondiente.
- OSPF desde cada CORE por su interfaz correspondiente.
- ICMP para diagnóstico.
- Winbox TCP/8291 desde `192.168.10.100`, ingresando por los enlaces internos.

Una regla final descarta el resto del tráfico dirigido a EDGE. Además, el servicio Winbox se restringió a `192.168.10.100/32`.

La cadena `forward` permite conexiones establecidas y relacionadas, descarta conexiones inválidas y autoriza tráfico desde las LAN hacia los ISP. También permite tránsito entre las dos LAN por las interfaces internas si su recorrido atraviesa EDGE. Una regla final descarta el tráfico restante.

La consola local de GNS3 continúa disponible para administración.

Las reglas documentadas corresponden al tráfico IPv4 del laboratorio.

---

## 4. Verificación

### 4.1 Verificación de F1

Se verificó conectividad mediante ping en los nueve enlaces directos entre routers. También se comprobó que PC-USER alcanza `192.168.10.2` y `192.168.10.3`, y que SRV alcanza `192.168.20.2` y `192.168.20.3`.

Las pruebas se repitieron después del hardening, con resultados satisfactorios. Las evidencias se encuentran en `capturas/F1/`.

La conectividad entre redes se verificó posteriormente en F2.

### 4.2 Verificación de F2

**OSPF.** Se documentaron vecinos en estado Full sobre los enlaces /30 internos, incluido el core-core. EDGE aprendió por OSPF las redes internas, entre ellas `192.168.10.0/24` y `192.168.20.0/24`.

![OSPF CORE-1](../capturas/F2/F2-ospf-CORE-1.png)

![OSPF CORE-2](../capturas/F2/F2-ospf-CORE-2.png)

![OSPF DIST-1](../capturas/F2/F2-ospf-DIST-1.png)

![OSPF DIST-2](../capturas/F2/F2-ospf-DIST-2.png)

![OSPF EDGE](../capturas/F2/F2-ospf-EDGE.png)

![Rutas OSPF en EDGE](../capturas/F2/F2-ospf-rutas-EDGE.png)

**VRRP.** `/interface vrrp print` mostró DIST-1 como master del grupo 10 y DIST-2 como master del grupo 20.

![VRRP DIST-1](../capturas/F2/F2-vrrp-DIST-1.png)

![VRRP DIST-2](../capturas/F2/F2-vrrp-DIST-2.png)

**Capa 3.** PC-USER alcanzó su gateway virtual, el gateway virtual de SERVERS y el host SRV. SRV alcanzó su gateway virtual y PC-USER. La tabla ARP de SRV mostró la MAC virtual `00:00:5e:00:01:14`.

Con un ping continuo desde PC-USER al gateway virtual se apagó el master del grupo 10. Se observaron pérdidas transitorias y recuperación automática del servicio. Al encender nuevamente DIST-1, recuperó el rol master.

Esta comprobación funcional de F2 no sustituye los drills con tiempos medidos, runbooks y post-mortem previstos para F4.

![L3 PC-USER](../capturas/F2/F2-l3-PC-USER.png)

![L3 SRV](../capturas/F2/F2-l3-SRV.png)

![Ping continuo con failover](../capturas/F2/F2-l3-ping-continuo.png)

### 4.3 Verificación de F3

**Sesiones BGP.** EDGE mostró dos sesiones con bandera `E`, established, una con cada ISP. Se comprobó que las cuatro conexiones configuradas entre los tres routers tienen una clave TCP-MD5 no vacía, sin mostrar sus valores en las evidencias.

![BGP EDGE](../capturas/F3/F3-bgp-EDGE.png)

![BGP ISP-1](../capturas/F3/F3-bgp-ISP-1.png)

![BGP ISP-2](../capturas/F3/F3-bgp-ISP-2.png)

![TCP-MD5 EDGE](../capturas/F3/F3-md5-EDGE.png)

![TCP-MD5 ISP-1](../capturas/F3/F3-md5-ISP-1.png)

![TCP-MD5 ISP-2](../capturas/F3/F3-md5-ISP-2.png)

**Rutas BGP.** Ambos ISP instalaron rutas BGP activas hacia las dos LAN con EDGE como siguiente salto. EDGE instaló las rutas a ambas loopbacks y seleccionó la default de ISP-1, conservando la de ISP-2 como alternativa.

![Rutas ISP-1](../capturas/F3/F3-rutas-ISP-1.png)

![Rutas ISP-2](../capturas/F3/F3-rutas-ISP-2.png)

![Rutas EDGE](../capturas/F3/F3-rutas-EDGE.png)

**Salida anunciada por OSPF.** EDGE mantuvo sus dos vecinos Full y anunció la default mediante `originate-default=if-installed`. DIST-1 y DIST-2 recibieron esa ruta con caminos de igual costo a través de ambos CORE.

![OSPF EDGE en F3](../capturas/F3/F3-ospf-EDGE.png)

![Default DIST-1](../capturas/F3/F3-default-DIST-1.png)

![Default DIST-2](../capturas/F3/F3-default-DIST-2.png)

**Conectividad.** PC-USER alcanzó `2.2.2.2` y `3.3.3.3` mediante ping y traceroute. Después de aplicar el firewall continuó alcanzando ambas loopbacks y el host SRV.

En las trazas UDP, el mensaje final ICMP Destination port unreachable provino del destino y confirmó la llegada de las sondas. Los saltos internos variaron entre caminos disponibles.

![Pings PC-USER](../capturas/F3/F3-pings-PC-USER.png)

![Traceroute PC-USER](../capturas/F3/F3-traceroute-PC-USER.png)

**Firewall.** Después de aplicar las reglas, ambas sesiones BGP permanecieron establecidas y los dos vecinos OSPF de EDGE continuaron en estado Full.

Se intentó establecer una conexión TCP desde ISP-1 hacia `203.0.113.2:8291`, utilizando el cliente Telnet con el comando `/system telnet address=203.0.113.2 port=8291`. El intento terminó por timeout.

Se registró el contador de la regla final de descarte antes y después de la prueba. Su incremento es consistente con el bloqueo, aunque la regla también puede contabilizar otro tráfico.

![Reglas firewall](../capturas/F3/F3-firewall-reglas-EDGE.png)

![Contadores firewall](../capturas/F3/F3-firewall-contadores-EDGE.png)

![Restricción de gestión y NAT](../capturas/F3/F3-gestion-NAT-EDGE.png)

![Contador antes](../capturas/F3/F3-bloqueo-contador-antes.png)

![Intento desde ISP-1](../capturas/F3/F3-bloqueo-gestion-ISP-1.png)

![Contador después](../capturas/F3/F3-bloqueo-contador-despues.png)

La prueba de caída de proveedor y la medición de convergencia permanecen pendientes para F4.

---

## 5. Seguridad aplicada

### 5.1 Hardening de F1

En los siete routers se creó `netadmin` con grupo `full` y `monitor` con el grupo personalizado `monitoring`, cuyos permisos son `local,read,winbox`. Se deshabilitó el usuario `admin`.

Se deshabilitaron Telnet, FTP, HTTP, HTTPS, SSH, API y API-SSL. Winbox por IP quedó habilitado. También se deshabilitaron MAC-Telnet, MAC-Winbox y MAC-Ping.

El cliente DHCP preconfigurado en ether1 se deshabilitó explícitamente en los siete routers. El direccionamiento del laboratorio es estático; un cliente DHCP activo podría introducir direcciones, DNS o rutas ajenas al IPAM. Su estado se registra en los exports.

En los ISP se conservó activa únicamente ether1. En EDGE, CORE y DIST se conservaron ether1 a ether4 y se deshabilitaron las interfaces Ethernet restantes.

Se verificaron usuarios, permisos, servicios e interfaces en los siete routers. El ingreso con `monitor` y la consulta de direcciones se probaron en ISP-1.

La autenticación de los protocolos y el firewall se incorporaron en F2 y F3.

### 5.2 Autenticación de F2

- **OSPF:** MD5, con `auth=md5` y `auth-id=1`, en todos los enlaces /30 internos.
- **VRRP:** autenticación AH en ambos grupos, utilizando VRRPv2 en RouterOS 7.16.

Las claves vigentes se manejan conforme a la sección 1.3. La prueba con clave incorrecta se documentará en F4.

### 5.3 Seguridad de F3

Las dos sesiones eBGP utilizan TCP-MD5 con una clave específica de BGP, distinta de las claves OSPF y VRRP. La clave no se incluye en el repositorio.

Los filtros BGP limitan los anuncios de EDGE a las dos LAN y restringen los prefijos aceptados desde cada proveedor.

El firewall protege el plano de control permitiendo BGP y OSPF únicamente desde los vecinos y enlaces definidos, además de las conexiones establecidas y relacionadas. Se mantiene ICMP para diagnóstico.

Winbox queda restringido a `192.168.10.100/32` tanto en el servicio como en la cadena input. Se verificó el bloqueo del puerto de gestión desde ISP-1.

La autorización de Winbox desde PC-USER se comprobó mediante la configuración. No se realizó una sesión gráfica desde ese host, que es un VPCS. La administración efectiva durante F3 se realizó mediante la consola de GNS3.

La prueba de bloqueo de gestión no sustituye la prueba de autenticación con clave incorrecta prevista para F4.

---

## 6. Gestión operativa

### 6.1 Change log

Registro de commits de `main` hasta `4e66f19`, en orden cronológico.
El commit de esta actualización documental se incorporará en la
siguiente actualización del registro.

La columna Responsable corresponde al autor registrado en Git.
Los commits de F0 y F1 son anteriores a la convención de etiqueta de rol.

Para commits ordinarios, `git revert <hash>` crea un commit inverso
sin reescribir el historial. Los commits de merge requieren seleccionar
el padre principal. Revertir archivos del repositorio no revierte
automáticamente las configuraciones activas de los routers.

| Fecha | Fase | Commit | Responsable | Mensaje | Reversión / observación |
|:-----:|:----:|:------:|-------------|---------|------------------------|
| 2026-10-01 | F0 | `0d14cd5` | Facundo Daza | chore: crear estructura inicial del proyecto | `git revert` |
| 2026-10-02 | F0 | `32ebfb0` | Irineo Hiriart | docs(backlog): inicializo backlog con tareas y roles para F0 | Mensaje duplicado con `f90c412`. |
| 2026-10-02 | F0 | `f90c412` | Irineo Hiriart | docs(backlog): inicializo backlog con tareas y roles para F0 | Mensaje duplicado con `32ebfb0`. |
| 2026-10-02 | F0 | `dc75ea5` | Irineo Hiriart | docs(memoria): inicializo planilla de memoria tecnica | `git revert` |
| 2026-10-02 | F0 | `edff198` | Facundo Daza | docs(diseño): completar IPAM, politicas de seguridad y backlog para fase F0 | `git revert` |
| 2026-10-02 | F0 | `bf0e5fc` | Facundo Daza | chore(merge): resolver conflictos sobrescribiendo main con diseño F0 | Revisar el cambio antes de revertir. |
| 2026-10-02 | F0 | `d69c615` | Facundo Daza | Merge pull request #1 from Shelldaza/docs/f0 | Merge: `git revert -m 1 d69c615`. |
| 2026-10-09 | F1 | `6fa5e60` | Irineo Hiriart | feat(backups): agregar archivos .rsc de exportacion hardening e IPAM para core-1, core-2, dist-1 y dist-2 | Solo agrega archivos; no modifica routers. |
| 2026-10-09 | F1 | `e0ed544` | Irineo Hiriart | docs(capturas): evidencias de despliegue de topologia, conectividad L3 y hardening para F1 | `git revert` |
| 2026-10-09 | F1 | `abb80e0` | Facundo Daza | docs(f1): agrego evidencias de edge proveedores hosts y snapshot BASE | `git revert` |
| 2026-10-09 | F1 | `1753f9c` | Facundo Daza | feet(backup): agregar exports F1 de edge y proveedores | Error de escritura en el tipo `feet`. Solo agrega archivos. |
| 2026-10-09 | F1 | `2522bb2` | Facundo Daza | docs(f1): actualizo readme backlog y memoria con cierre de fase | `git revert` |
| 2026-10-15 | F2 | `6cb1dab` | Irineo Hiriart | feat(ospf): OSPF area 0 con MD5 en core-1 y core-2 [R3] | En los routers, restaurar el estado previo de OSPF con respaldo y verificación. |
| 2026-10-15 | F2 | `c8fea4c` | Irineo Hiriart | docs(capturas): evidencia OSPF core-core core-1 y core-2 [R5] | `git revert` |
| 2026-10-15 | F2 | `04fc6a3` | Irineo Hiriart | feat(ospf): OSPF area 0 con MD5 en EDGE, DIST-1 y DIST-2 [R3] | En los routers, restaurar el estado previo de OSPF con respaldo y verificación. |
| 2026-10-15 | F2 | `4b5ee96` | Irineo Hiriart | docs(capturas): evidencia OSPF en EDGE, DIST-1 y DIST-2 [R5] | `git revert` |
| 2026-10-15 | F2 | `764af58` | Irineo Hiriart | docs(capturas): actualizo evidencia OSPF de CORE-1 y CORE-2 con 4 vecinos [R5] | `git revert` |
| 2026-10-15 | F2 | `3b011a8` | Irineo Hiriart | feat(vrrp): vrid 10 master y vrid 20 backup con auth en DIST-1 [R4] | En DIST-1, restaurar el estado previo de interfaces y direcciones VRRP. |
| 2026-10-15 | F2 | `aee423a` | Irineo Hiriart | feat(vrrp): vrid 20 master y vrid 10 backup con auth en DIST-2 [R4] | En DIST-2, restaurar el estado previo de interfaces y direcciones VRRP. |
| 2026-10-15 | F2 | `60c572a` | Irineo Hiriart | docs(capturas): evidencias VRRP con auth y reparto de carga en DIST-1 y DIST-2 [R5] | `git revert` |
| 2026-10-15 | F2 | `32ba4a6` | Irineo Hiriart | docs(capturas): evidencia verificacion L3 PC-USER y SRV via VIP [5] | Rol escrito `[5]` por `[R5]`. |
| 2026-10-15 | F2 | `5d8e433` | Irineo Hiriart | docs(capturas): evidencia failover VRRP con ping continuo [R5] | `git revert` |
| 2026-10-15 | F2 | `6400ae6` | Irineo Hiriart | docs(backlog): marcar F2 (VRRP + OSPF + L3) como hecho [R5] | `git revert` |
| 2026-10-15 | F2 | `2562310` | Irineo Hiriart | docs(memoria): documentar configuracion, verificacion y seguridad de F2 [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `405e5ce` | Irineo Hiriart | docs(memoria): completar change log de F0 a F2 [R5] | `git revert` |
| 2026-10-15 | F2 | `3fd3346` | Irineo Hiriart | ops(backups): backup post-F2 de EDGE, CORE-1, CORE-2, DIST-1 Y DIST-2 [R5] | Solo agrega archivos; no modifica routers. |
| 2026-10-15 | F2 | `5ccf3af` | Irineo Hiriart | docs(memoria): documentar backup post-F2 y alcance de los exports [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `efb4578` | Irineo Hiriart | docs(memoria): documentar defectos 4 y 5 del diagrama (firewall SPOF y RR iGBP) [R5] | Error de escritura `iGBP` en el mensaje. |
| 2026-10-15 | F0/F1 (corrección) | `91fb939` | Irineo Hiriart | docs(capturas): evidencia prueba de restauracion de CORE-1 [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `e6d1aae` | Irineo Hiriart | docs(memoria): agregar restore drill a la politica de backup y documentar prueba en CORE-1 [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `6610bdb` | Irineo Hiriart | fix(seguridad): quitar claves de scripts y backups de F2 [R5] | No revertir: reintroduce las claves en los archivos. |
| 2026-10-15 | F0/F1 (corrección) | `f71d7f5` | Irineo Hiriart | docs(memoria): retirar claves de memoria y actualizar politica de claves [R5] | No revertir: reintroduce las claves en los archivos. |
| 2026-10-15 | F0/F1 (corrección) | `5e0bc40` | Irineo Hiriart | docs(memoria): explicar deshabilitacion del cliente DHCP en el hardening [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `0e84036` | Irineo Hiriart | docs(capturas): evidencia de backup binario .backup en los 7 routers [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `89d3613` | Irineo Hiriart | chore(git): ignorar backup binario en la poltiica y en 6.2 [R5] | Agrega `.gitignore` con `*.backup`; error de escritura `poltiica`. |
| 2026-10-15 | F0/F1 (corrección) | `5358d39` | Irineo Hiriart | docs(memoria): definir y documentar backup binario en la política y en 6.2 [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `3c88303` | Irineo Hiriart | docs(memoria): documentar canal para el manejo de claves [R5] | `git revert` |
| 2026-10-15 | F0/F1 (corrección) | `2bf2e5d` | Irineo Hiriart | docs(memoria): ampliar change log con fecha, responsable y reversión, y agregar verificación del dhcp-client [R5] | `git revert`; no modifica routers. |
| 2026-10-16 | F3 | `e71d222` | Facundo Daza | docs(capturas): agrego evidencias de BGP conectividad y firewall de F3 | `git revert`; elimina las evidencias incorporadas, sin modificar routers. |
| 2026-10-16 | F3 | `ce154b4` | Facundo Daza | ops(backups): agrego exports post-F3 de EDGE y proveedores con claves censuradas | Solo agrega archivos; revertirlo no modifica los routers. |
| 2026-10-16 | F3 | `d5236d8` | Facundo Daza | docs(capturas): documento backups binarios y restauracion de ISP-2 en F3 | `git revert`; elimina las evidencias incorporadas, sin modificar los routers. |
| 2026-10-16 | F3 | `a47d148` | Facundo Daza | fix(backups): completo exports post-F3 de proveedores que quedaron vacios | Corrige los archivos vacíos de ISP-1 e ISP-2 incorporados en ce154b4. Revertirlo dejaría nuevamente esos respaldos vacíos; no modifica routers. |
| 2026-10-16 | F3 | `4e66f19` | Facundo Daza | feat(configs): agrego configuraciones completas post-F3 de EDGE y proveedores | Agrega exports completos en configs/. Revertirlo elimina esas copias, sin modificar routers. |
### 6.2 Backups

#### Exports de F1

Se generaron y guardaron en `backups/` los siete exports de F1, con nombres `backup-<nodo>-2026-10-09.rsc`.

Los archivos obtenidos no incluyen los usuarios `netadmin` y `monitor`, sus contraseñas ni la deshabilitación de `admin`. Esos elementos deben reponerse al restaurar desde los exports.

#### Exports de F2

Al cerrar F2 se generaron exports de EDGE, CORE-1, CORE-2, DIST-1 y DIST-2, con nombres `backup-<nodo>-2026-10-15.rsc`. Los ISP no cambiaron durante F2 y conservaron sus exports del 09/10.

Los archivos incluyen las instancias OSPF, las interface-templates MD5 y los grupos VRRP con `authentication=ah`.

En los exports obtenidos, `auth-key` de OSPF apareció en texto plano y se reemplazó por `REDACTED` en las copias versionadas. La contraseña VRRP no apareció. Las claves deben reponerse al restaurar.

#### Backups binarios de F2

El 15/10 se generaron backups binarios `.backup` de los siete routers, incluidos ambos ISP, cifrados con una contraseña que no se versiona.

Los archivos permanecen en el almacenamiento de los routers. No se configuró un camino de gestión para descargarlos y no se subieron al repositorio. Su existencia se documentó mediante los listados de archivos.

La restauración desde esos backups binarios no se probó; el restore drill documentado utilizó un `.rsc`.

![Backup binario EDGE](../capturas/F2/F2-backup-bin-EDGE.png)

![Backup binario ISP-1](../capturas/F2/F2-backup-bin-ISP-1.png)

![Backup binario ISP-2](../capturas/F2/F2-backup-bin-ISP-2.png)

![Backup binario CORE-1](../capturas/F2/F2-backup-bin-CORE-1.png)

![Backup binario CORE-2](../capturas/F2/F2-backup-bin-CORE-2.png)

![Backup binario DIST-1](../capturas/F2/F2-backup-bin-DIST-1.png)

![Backup binario DIST-2](../capturas/F2/F2-backup-bin-DIST-2.png)

#### Snapshot BASE

Se creó el snapshot BASE en GNS3, con los nodos detenidos, después de configurar y verificar el direccionamiento y el hardening de F1.

Este snapshot conserva el estado base de F1; no representa las configuraciones posteriores de F2 y F3.

![Snapshot BASE](../capturas/F1/F1-snapshot-BASE.png)

#### Prueba de restauración de F2

El 15/10 se probó la restauración de CORE-1 con el archivo `backup-CORE-1-2026-10-15.rsc`.

Antes del reset, CORE-1 tenía cuatro vecinos OSPF Full. Se ejecutó `/system reset-configuration no-defaults=yes skip-backup=yes`; el router volvió sin configuración, con identidad MikroTik, y el archivo `.rsc` se conservó en su almacenamiento.

La importación restauró la configuración sin errores. Los usuarios se recrearon manualmente: `netadmin`, `monitor` y `admin` deshabilitado.

CORE-1 recuperó sus cuatro adyacencias OSPF Full, las cinco direcciones IP y los servicios inseguros deshabilitados. La autenticación MD5 se recuperó porque el export local utilizado incluía la clave. Las copias censuradas del repositorio requieren reponerla.

![Restore CORE-1 antes](../capturas/F2/F2-restore-CORE-1-antes.png)

![Restore CORE-1 después](../capturas/F2/F2-restore-CORE-1-despues.png)

#### Exports de F3

El 16/10/2026 se generaron los exports finales de los tres routers modificados:

- `backup-EDGE-2026-10-16.rsc`
- `backup-ISP-1-2026-10-16.rsc`
- `backup-ISP-2-2026-10-16.rsc`

Se guardaron en `backups/`. El export final de EDGE contiene únicamente las dos conexiones BGP necesarias, después de eliminar las entradas duplicadas.

La clave OSPF visible en el export de EDGE se reemplazó por `REDACTED` en la copia destinada al repositorio. Las claves TCP-MD5 no aparecen en los exports obtenidos y deben reponerse al restaurar.

CORE-1, CORE-2, DIST-1 y DIST-2 no recibieron cambios de configuración durante F3 y conservan sus exports posteriores a F2. Las rutas aprendidas dinámicamente no requieren modificar sus configuraciones.

Antes de iniciar F3 se generaron exports `pre-F3` en EDGE y ambos ISP como referencia local del estado anterior.

#### Backups binarios de F3

El 16/10/2026 se generaron backups binarios cifrados de EDGE, ISP-1 e ISP-2, posteriores a la configuración de BGP y del firewall.

Se utilizó cifrado `aes-sha256` con una contraseña guardada fuera del repositorio. Los archivos contienen usuarios y claves, permanecen en el almacenamiento de los routers y no se versionan.

Se comprobó su existencia mediante `/file print`, verificando que los archivos `.backup` tenían tamaño mayor que cero.

![Backup binario EDGE de F3](../capturas/F3/F3-backup-bin-EDGE.png)

![Backup binario ISP-1 de F3](../capturas/F3/F3-backup-bin-ISP-1.png)

![Backup binario ISP-2 de F3](../capturas/F3/F3-backup-bin-ISP-2.png)

#### Prueba de restauración de F3

El 16/10/2026 se probó la restauración de ISP-2 desde el archivo `backup-ISP-2-2026-10-16.rsc` en una copia aislada del proyecto GNS3. El proyecto original permaneció detenido durante la prueba.

Antes del reset se registraron la identidad ISP-2, las direcciones `198.51.100.1/30` y `3.3.3.3/32`, la sesión eBGP establecida con EDGE y las rutas BGP hacia `192.168.10.0/24` y `192.168.20.0/24`.

![Estado previo de ISP-2](../capturas/F3/F3-restore-ISP-2-antes.png)

Se ejecutó `/system reset-configuration no-defaults=yes skip-backup=yes`. Después del reinicio se comprobó que el router tenía identidad MikroTik, sin direcciones IP ni conexiones BGP configuradas, y que el archivo `.rsc` se conservaba en su almacenamiento.

![ISP-2 sin configuración](../capturas/F3/F3-restore-ISP-2-reset.png)

Se importó el archivo mediante `/import file-name=backup-ISP-2-2026-10-16.rsc`. La importación finalizó correctamente.

![Importación del export de ISP-2](../capturas/F3/F3-restore-ISP-2-import.png)

La clave TCP-MD5 se repuso manualmente, porque el export no la incluía. También se recrearon los usuarios `netadmin` y `monitor`, utilizando el grupo `monitoring` restaurado por el export. Después de comprobar el acceso con `netadmin`, se deshabilitó el usuario `admin`.

Se verificó la recuperación de:

- La identidad ISP-2.
- Las direcciones `198.51.100.1/30` y `3.3.3.3/32`.
- La sesión eBGP establecida con EDGE.
- Las rutas BGP hacia las dos LAN.
- Los usuarios y sus grupos.
- Los servicios deshabilitados conforme al hardening.
- Las interfaces Ethernet sin uso deshabilitadas.
- El cliente DHCP de ether1 deshabilitado.

![Estado restaurado de ISP-2](../capturas/F3/F3-restore-ISP-2-despues.png)

![Hardening restaurado de ISP-2](../capturas/F3/F3-restore-ISP-2-hardening.png)

Finalmente, PC-USER volvió a alcanzar la loopback `3.3.3.3` mediante ping y traceroute.

![Conectividad después de restaurar ISP-2](../capturas/F3/F3-restore-PC-USER.png)

La prueba verificó la restauración desde el export textual `.rsc`, con reposición manual de usuarios y clave BGP. No se probó la restauración desde los archivos binarios `.backup`.

Mantener los backups binarios únicamente dentro de los routers constituye una limitación: no protege frente a la pérdida del almacenamiento del proyecto.

### 6.3 Monitoreo

La configuración y los resultados del monitoreo continuo, mediante SNMP y chequeos de estado, se incorporarán durante F4.

---

## 7. Capturas

Las evidencias están organizadas por fase:

| Directorio | Contenido |
|------------|-----------|
| `capturas/F1/` | Topología, direccionamiento, hardening, acceso de monitor, pings directos y snapshot BASE. |
| `capturas/F2/` | OSPF, VRRP, conectividad entre LAN, comprobación funcional de failover, backups binarios y restauración de CORE-1. |
| `capturas/F3/` | Sesiones BGP, comprobación de TCP-MD5 sin revelar claves, rutas, salida por OSPF, pings, traceroutes y firewall. |

Las capturas de F4 se incorporarán al ejecutar los drills y el monitoreo.

Los nombres de archivos deben coincidir con los enlaces utilizados en esta memoria. Las imágenes no deben mostrar claves vigentes.

---

## 8. Conclusiones y lecciones aprendidas

El análisis global, los post-mortem y las conclusiones técnicas sobre la resiliencia de la arquitectura se completarán en F5, después de ejecutar los drills de F4.

Hasta F3 se verificó el funcionamiento integrado de VRRP, OSPF, eBGP y el firewall de EDGE. Esta verificación funcional no demuestra todavía los tiempos de convergencia ni el cumplimiento de los cinco escenarios de falla requeridos.

Se mantiene como limitación conocida el único router EDGE. Las dos sesiones eBGP permiten disponer de alternativas de proveedor, pero no eliminan ese punto único de falla.

---

## 9. Referencias

- Documentación oficial de MikroTik RouterOS: VRRP, OSPF, BGP, firewall y gestión de configuraciones.
- RFC 5798: Virtual Router Redundancy Protocol, versión 3.
- RFC 3768: Virtual Router Redundancy Protocol, versión 2.
- RFC 2328: OSPF Version 2.
- RFC 4271: A Border Gateway Protocol 4.
- RFC 2385: Protection of BGP Sessions via the TCP MD5 Signature Option.
- Diapositivas y material de cátedra: “Failover Routing”.
- Consigna del laboratorio: `spec-laboratorio-failover.md`.

---

## 10. Checklist de entrega

### Diseño (F0)

- [x] IPAM completo y sin solapamiento.
- [x] Corrección del diagrama justificada, con al menos tres defectos.
- [x] Política de seguridad definida: usuarios, servicios y manejo de claves.
- [x] Política de operación definida: change log y backups.

### Redes

- [x] 7 CHR, 2 switches y 2 hosts levantados y cableados.
- [x] VRRP operativo con dos grupos y reparto de carga.
- [x] OSPF área 0 con adyacencias, incluido core-core.
- [x] Dos sesiones eBGP establecidas.
- [x] Ambas LAN anunciadas a los dos ISP mediante OSPF→BGP.
- [x] PC-USER alcanza las loopbacks de ambos ISP.
- [ ] Cinco drills ejecutados y documentados con runbook, post-mortem y tiempo medido.

### Seguridad

- [x] Hardening aplicado: usuarios, contraseñas y servicios deshabilitados.
- [x] OSPF MD5 funcionando.
- [x] BGP TCP-MD5 funcionando.
- [x] Autenticación VRRP funcionando.
- [x] Firewall IPv4 de EDGE aplicado.
- [x] Winbox de EDGE restringido al origen autorizado.
- [x] Bloqueo de TCP/8291 desde ISP-1 verificado.
- [ ] Prueba de autenticación con clave incorrecta documentada.

### Operación

- [x] Change log actualizado con todos los commits reales, incluidos los de F3.
- [x] Exports posteriores a F1 y F2 generados.
- [x] Exports finales de EDGE e ISP posteriores a F3 generados y revisados.
- [x] Restauración desde export probada en CORE-1 durante F2.
- [x] Backups binarios cifrados de F2 documentados.
- [x] Backups binarios posteriores a F3 generados y documentados.
- [x] Restauración de un nodo con configuración posterior a F3 probada.
- [ ] Monitoreo habilitado y documentado.
- [ ] Runbook por drill y post-mortem global.

### Entrega

- [ ] Memoria completa, incluidas F4 y F5.
- [ ] Repositorio con estructura y trazabilidad de commits revisados para la entrega final.
- [ ] Backlog con todos los criterios de aceptación cumplidos.
- [ ] Evidencias completas de todas las fases en `capturas/`.
- [ ] Configuraciones finales organizadas en `configs/`.
- [ ] Cada integrante puede defender su parte y una parte ajena.