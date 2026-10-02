# Backlog — Laboratorio Failover Routing

> Copiar este archivo a `backlog.md` en el repo del grupo y completar.
> **Grupo:** 3 · **Vencimiento final:** vie 23/10

## Leyenda de estado

- `[ ]` pendiente · `[~]` en curso · `[x]` hecho
- Cada tarea lleva **dueño** (rol): `[R1]` … `[R5]`.
- **"Hecho" = criterio de aceptación cumplido** (ver spec, sección 6). No "más o menos".

---

## Epic F0 — Diseño y gestión de cambio · *vence vie 2/10*

### IPAM / direccionamiento
- [ ] <!-- [R#] tarea -->
- [ ] [R1] Diseñar tabla de enlaces punto a punto (/30) entre EDGE, COREs, DISTs, e ISPs sin solapamientos.
- [ ] [R1] Diseñar tabla de redes LAN (/24) y direccionamiento de hosts
- [ ] [R1] Definir IPs virtuales (VIPs) y prioridades para los grupos VRRP 10 y 20
- [ ] [R1] Asignar router-ids y loopbacks (/32) para cada uno de los 7 routers


### Corrección del diagrama (≥ 3 defectos)
- [ ] [R1] Documentar defecto 1 (punto único de falla / falta de redundancia en borde) con corrección y justificación
- [ ] [R3] Documentar defecto 2: Core sin enlace core-core (falta redundancia intra-core) con corrección y justificación
- [ ] [R4] Documentar defecto 3 (redundancia de primer salto L2/L3 / VRRP) con corrección y justificación

### Política de seguridad
- [ ] [R3] Definir política de usuarios administrativos y monitoreo (roles y privilegios)
- [ ] [R3] Listar servicios inseguros a deshabilitar en RouterOS (telnet, ftp, www, api)
- [ ] [R3] Definir claves de autenticación compartidas (TCP-MD5 para BGP y MD5 para OSPF área 0)
- [ ] [R1] Definir mitigación GTSM (TTL=255) y filtros de prefijos eBGP de borde

### Política de operación (change log + backup)
- [ ] [R5] Establecer el estándar y formato de registro para el change log (sección 6.1 de memoria)
- [ ] [R5] Definir la política de backup operativo (/export por router, versionado y fechas)

### Repositorio git
- [x] [R5] Crear estructura oficial de carpetas del repositorio según spec 9.1
- [x] [R5] Inicializar backlog.md y memoria.md desde las plantillas oficiales
- [ ] [R5] Ejecutar commit inicial siguiendo la convención Conventional Commits

---

## Epic F1 — Topología + hardening + backup · *vence vie 9/10*

### Despliegue (7 CHR + 2 switches + 2 hosts)
- [ ] <!-- [R#] tarea -->

### IPs de enlace + loopbacks
- [ ] <!-- [R#] tarea -->

### Snapshot BASE
- [ ] <!-- [R#] tarea -->

### Hardening (los 7 routers)
- [ ] <!-- [R#] tarea -->

### Backup inicial (`/export`)
- [ ] <!-- [R#] tarea -->

---

## Epic F2 — VRRP + OSPF · *vence vie 16/10*

### VRRP (2 grupos, load-sharing, auth)
- [ ] [R4] configurar VRRP vrid 10 en DIST-1 (master)
- [ ] [R4] configurar VRRP vrid 20 en DIST-2 (master)
- [ ] [R4] activar auth simple en ambos grupos
- [ ] [R5] verificar master/backup con `/interface vrrp print`

### OSPF área 0 (con MD5, incluido core–core)
- [ ] <!-- [R#] tarea -->

### Verificación L3 (ping intra-LAN + gateway virtual)
- [ ] <!-- [R#] tarea -->

---

## Epic F3 — BGP + firewall · *vence vie 16/10*

### eBGP multi-homing (2 sesiones, TCP-MD5)
- [ ] <!-- [R#] tarea -->

### Redistribución OSPF→BGP
- [ ] <!-- [R#] tarea -->

### Salida a "Internet" (host → loopback ISP)
- [ ] <!-- [R#] tarea -->

### Firewall edge (filtro + plano de gestión)
- [ ] <!-- [R#] tarea -->

---

## Epic F4 — Drills + monitoreo · *vence mar 20/10*

### Los 5 drills (runbook + post-mortem + tiempo)
- [ ] <!-- [R#] tarea -->

### Monitoreo (SNMP/chequeos)
- [ ] <!-- [R#] tarea -->

### Verificación de seguridad (clave incorrecta falla)
- [ ] <!-- [R#] tarea -->

---

## Epic F5 — Memoria + defensa · *vence vie 23/10*

### Memoria (plantilla completa)
- [ ] <!-- [R#] tarea -->

### Backlog cerrado (todo en "hecho")
- [ ] <!-- [R#] tarea -->

### Defensa oral (parte propia + ajena)
- [ ] <!-- [R#] tarea -->
