# Runbook — Drill 1: caída de DIST-1 (VRRP)

**Fecha:** 19/10/2026 · **Responsable:** R5 · **Fase:** F4
**Escenario:** apagado del router DIST-1 (master del grupo VRRP 10).

## 1. Estado base

| Router | vrrp10 (VIP 192.168.10.1) | vrrp20 (VIP 192.168.20.1) |
| :---- | :---- | :---- |
| DIST-1 | Master (prio 150) | Backup (prio 100) |
| DIST-2 | Backup (prio 100) | Master (prio 150) |

Prueba de tráfico: `ping 192.168.10.1 -t` desde PC-USER (1 paquete/s).

## 2. Detección

- **Síntoma:** PC-USER pierde respuesta del gateway virtual 192.168.10.1 (`icmp_seq=15` timeout).
- **Confirmación:** en DIST-2, `/interface vrrp print` → vrrp10 pasa de `B` a `RM`.
- **Mecanismo:** DIST-2 no recibe advertisements de DIST-1 durante 3 × 1 s + skew `(256 − 100)/256 ≈ 0,61 s` → master-down ≈ 3,6 s.

## 3. Respuesta

No requiere intervención manual. DIST-2 asume el rol Master de vrrp10 y responde por la MAC virtual `00:00:5E:00:01:0A`. DIST-2 queda como Master de ambos grupos.

## 4. Recuperación

1. Encender DIST-1 en GNS3.
2. Esperar el inicio del router y de OSPF.
3. Verificar en DIST-1: `/interface vrrp print`.

Resultado: DIST-1 recupera vrrp10 como Master por preemption (prio 150 > 100) y vrrp20 queda en Backup.

```
0 RM vrrp10  ether3  00:00:5E:00:01:0A  VRID 10  PRIO 150
1  B vrrp20  ether4  00:00:5E:00:01:14  VRID 20  PRIO 100
```

## 5. Tiempos medidos

| Fase | Medición | Resultado |
| :---- | :---- | :---- |
| Falla (DIST-1 apagado) | Paquetes perdidos | 1 (`icmp_seq=15`) |
| Falla | Interrupción estimada | ≈ 2,8 s (±1 s por resolución del ping) |
| Falla | Valor teórico | ≈ 3,6 s |
| Recuperación (DIST-1 encendido) | Paquetes perdidos | 0 |
| Recuperación | Pico de latencia | 833,9 ms en `icmp_seq=26` |

Resolución de la medición: 1 s (un paquete por segundo). El tiempo medido queda dentro del margen del valor teórico.

## 6. Post-mortem

- **Impacto:** interrupción de ≈ 3 s en la LAN 192.168.10.0/24. La LAN 192.168.20.0/24 no se vio afectada: su Master (DIST-2) no cayó.
- **Causa raíz:** apagado intencional de DIST-1 (drill).
- **Qué funcionó:** failover automático sin intervención, con autenticación AH activa; failback sin pérdida de paquetes.
- **Observación:** pico de ≈ 0,8 s en el failover (`icmp_seq=16`, 788 ms) y en el failback (`icmp_seq=26`, 834 ms). Hipótesis, no medida: reaprendizaje de la MAC virtual en el switch de acceso al cambiar de Master.
- **Riesgo residual:** timers por defecto (advertisement 1 s). Reducirlos acortaría la convergencia a costa de más tráfico de control y riesgo de flapping.
- **Mejora posible:** configurar el intervalo de advertisement a 500 ms y repetir la medición con una resolución mayor.

## 7. Evidencias

Carpeta `capturas/F4/`:

- `F4-drill1-base-DIST-1.png`, `F4-drill1-base-DIST-2.png`, `F4-drill1-base-PC-USER.png`
- `F4-drill1-falla-DIST-2.png`, `F4-drill1-falla-PC-USER.png`
- `F4-drill1-recuperacion-DIST-1.png`, `F4-drill1-recuperacion-PC-USER.png`
