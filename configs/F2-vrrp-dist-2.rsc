# F2 - VRRP vrid 20 (master) y vrid 10 (backup) con auth - DIST-2 [R4]
# Reemplazar <CLAVE_...> por la clave vigente (no versionada) antes de pegar.
/interface vrrp add name=vrrp10 interface=ether3 vrid=10 priority=100 version=2 authentication=ah password="<CLAVE_VRRP>"
/interface vrrp add name=vrrp20 interface=ether4 vrid=20 priority=150 version=2 authentication=ah password="<CLAVE_VRRP>"
/ip address add address=192.168.10.1/24 interface=vrrp10 comment="VIP USERS"
/ip address add address=192.168.20.1/24 interface=vrrp20 comment="VIP SERVERS"
