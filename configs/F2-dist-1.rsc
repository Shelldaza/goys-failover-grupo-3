# F2 - OSPF area 0 con MD5 - DIST-1 [R3]
# Reemplazar <CLAVE_...> por la clave vigente (no versionada) antes de pegar.
/routing ospf instance add name=ospf-main version=2 router-id=6.6.6.6
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf-main
/routing ospf interface-template add area=backbone networks=10.0.0.0/24 type=ptp auth=md5 auth-id=1 auth-key="<CLAVE_OSPF>"
/routing ospf interface-template add area=backbone networks=192.168.10.0/24 passive
/routing ospf interface-template add area=backbone networks=192.168.20.0/24 passive
/routing ospf interface-template add area=backbone networks=6.6.6.6/32 passive
