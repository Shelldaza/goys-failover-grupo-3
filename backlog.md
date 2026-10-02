# Backlog — Laboratorio Failover Routing

**Grupo:** 3 · **Vencimiento final:** vie 23/10

## Leyenda de estado

- `[ ]` pendiente · `[~]` en curso · `[x]` hecho
- Cada tarea lleva **dueño** (rol): `[R1]`, `[R2]`, `[R3]`, `[R4]`, `[R5]`.
- **"Hecho" = criterio de aceptación cumplido** (ver spec, sección 6). No "más o menos".

---

## Epic F0 — Diseño y gestión de cambio · *vence vie 2/10*

### IPAM / direccionamiento
- [x] [R1] Diseñar direccionamiento enlaces WAN /30 y redes LAN /24.
- [x] [R3] Definir direccionamiento OSPF /30 y Router-IDs.
- [x] [R5] Verificar ausencia de solapamiento y plasmar tabla final en memoria.

### Corrección del diagrama (≥ 3 defectos)
- [x] [R3] Documentar solución al diseño colapsado (VRRP a Distribución).
- [x] [R4] Documentar agregado del enlace core-core.
- [x] [R5] Justificar uso de subredes independientes en acceso.

### Política de seguridad
- [x] [R1] Definir usuarios (netadmin/monitor) y deshabilitación de `admin`.
- [x] [R4] Deshabilitar servicios inseguros (telnet, ftp, http).
- [x] [R5] Establecer y documentar claves para MD5 (OSPF/BGP) y VRRP auth.

### Política de operación (change log + backup)
- [x] [R5] Establecer norma Conventional Commits.
- [x] [R5] Definir comando de exportación y ubicación de backups (.rsc).

### Repositorio git
- [x] [R5] Crear estructura base de carpetas en Git.
- [x] [R1] Subir Memoria F0 inicial.
- [x] [R5] Sincronizar y actualizar estado del `backlog.md`.

---

## Epic F1 — Topología + hardening + backup · *vence vie 9/10*

### Despliegue (7 CHR + 2 switches + 2 hosts)
- [ ] [R3] Importar imagen CHR y armar las 5 capas en GNS3.
- [ ] [R4] Cablear interfaces físicas según el diagrama F0.

### IPs de enlace + loopbacks
- [ ] [R1] Configurar IPs de enlaces externos en EDGE, ISP-1 e ISP-2.
- [ ] [R3] Configurar IPs y loopbacks en CORE-1, CORE-2, DIST-1 y DIST-2.
- [ ] [R5] Configurar IP/Gateway en PC-USER y SRV.

### Snapshot BASE
- [ ] [R5] Tomar snapshot en GNS3 tras validar pings directos.

### Hardening (los 7 routers)
- [ ] [R1] Aplicar script de creación de usuarios/servicios en EDGE/ISPs.
- [ ] [R4] Aplicar script de creación de usuarios/servicios en núcleo interno.

### Backup inicial (`/export`)
- [ ] [R5] Extraer archivos .rsc de los 7 equipos y comitear a Git.

---

## Epic F2 — VRRP + OSPF · *vence vie 16/10*

### VRRP (2 grupos, load-sharing, auth)
- [ ] [R4] configurar VRRP vrid 10 en DIST-1 (master)
- [ ] [R4] configurar VRRP vrid 20 en DIST-2 (master)
- [ ] [R4] activar auth simple en ambos grupos
- [ ] [R5] verificar master/backup con `/interface vrrp print`

### OSPF área 0 (con MD5, incluido core–core)
- [ ] [R3] Configurar instancias e interfaces OSPF en CORE-1, CORE-2, DIST y EDGE.
- [ ] [R3] Habilitar autenticación OSPF MD5 en todos los enlaces /30 internos.
- [ ] [R5] Verificar estado de adyacencias FULL y rutas dinámicas.

### Verificación L3 (ping intra-LAN + gateway virtual)
- [ ] [R5] Ejecutar ping continuo de PC-USER a IP Virtual 192.168.10.1.
- [ ] [R5] Probar ping de PC-USER a SRV para validar enrutamiento inter-VLAN.

---

## Epic F3 — BGP + firewall · *vence vie 16/10*

### eBGP multi-homing (2 sesiones, TCP-MD5)
- [ ] [R1] Levantar sesión BGP entre EDGE e ISP-1.
- [ ] [R1] Levantar sesión BGP entre EDGE e ISP-2.
- [ ] [R2] Aplicar contraseña TCP-MD5 y confirmar estado `established`.

### Redistribución OSPF→BGP
- [ ] [R1] Inyectar rutas LAN aprendidas por OSPF hacia BGP.
- [ ] [R2] Comprobar en tabla de ISP que conocen 192.168.10.0/24 y 20.0/24.

### Salida a "Internet" (host → loopback ISP)
- [ ] [R5] Hacer traceroute desde PC-USER a la Loopback del ISP-1.

### Firewall edge (filtro + plano de gestión)
- [ ] [R1] Configurar regla input drop en EDGE (permitiendo solo gestión).
- [ ] [R1] Configurar masquerade (NAT) si aplica.

---

## Epic F4 — Drills + monitoreo · *vence mar 20/10*

### Los 5 drills (runbook + post-mortem + tiempo)
- [ ] [R5] Ejecutar Drill 1 (apagar DIST-1) y registrar convergencia VRRP.
- [ ] [R5] Ejecutar Drill 2 (desconectar enlace CORE-1/DIST) y medir OSPF.
- [ ] [R5] Ejecutar Drill 3 (apagar enlace ISP-1) y medir BGP.
- [ ] [R5] Redactar post-mortem de los simulacros.

### Monitoreo (SNMP/chequeos)
- [ ] [R4] Documentar tablas `/routing/route/print`.

### Verificación de seguridad (clave incorrecta falla)
- [ ] [R3] Cambiar intencionalmente clave MD5 en CORE-1 y documentar caída de OSPF.

---

## Epic F5 — Memoria + defensa · *vence vie 23/10*

### Memoria (plantilla completa)
- [ ] [R5] Volcar todas las configuraciones `.rsc` al documento.
- [ ] [R5] Adjuntar capturas de GNS3 requeridas.

### Backlog cerrado (todo en "hecho")
- [ ] [R1] Revisar que no queden corchetes vacíos.

### Defensa oral (parte propia + ajena)
- [ ] [R1] Facundo: ensayar Edge, BGP y Firewall.
- [ ] [R3] Irineo: ensayar OSPF, VRRP y Drills.
- [ ] [R5] Simular cruce de preguntas.