# F2 - OSPF area 0 con MD5 - CORE-2 [R3]
/routing ospf instance add name=ospf-main version=2 router-id=5.5.5.5
/routing ospf area add name=backbone area-id=0.0.0.0 instance=ospf-main
/routing ospf interface-template add area=backbone networks=10.0.0.0/24 type=ptp auth=md5 auth-id=1 auth-key="OspfGoys26!"
/routing ospf interface-template add area=backbone networks=5.5.5.5/32 passive
