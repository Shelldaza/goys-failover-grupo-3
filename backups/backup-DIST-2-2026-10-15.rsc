# 2026-10-15 19:40:41 by RouterOS 7.16
# software id =
#
/interface ethernet
set [ find default-name=ether5 ] disabled=yes
set [ find default-name=ether6 ] disabled=yes
set [ find default-name=ether7 ] disabled=yes
set [ find default-name=ether8 ] disabled=yes
/interface vrrp
add authentication=ah interface=ether3 name=vrrp10 version=2 vrid=10
add authentication=ah interface=ether4 name=vrrp20 priority=150 version=2 \
    vrid=20
/port
set 0 name=serial0
/routing ospf instance
add disabled=no name=ospf-main router-id=7.7.7.7
/routing ospf area
add disabled=no instance=ospf-main name=backbone
/ip address
add address=10.0.0.18/30 comment="Enlace CORE-1" interface=ether1 network=\
    10.0.0.16
add address=10.0.0.26/30 comment="Enlace CORE-2" interface=ether2 network=\
    10.0.0.24
add address=192.168.10.3/24 comment="LAN USERS" interface=ether3 network=\
    192.168.10.0
add address=192.168.20.3/24 comment="LAN SERVERS" interface=ether4 network=\
    192.168.20.0
add address=7.7.7.7 comment=Loopback interface=lo network=7.7.7.7
add address=192.168.10.1/24 comment="VIP USERS" interface=vrrp10 network=\
    192.168.10.0
add address=192.168.20.1/24 comment="VIP SERVERS" interface=vrrp20 network=\
    192.168.20.0
/ip dhcp-client
add disabled=yes interface=ether1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/routing ospf interface-template
add area=backbone auth=md5 auth-id=1 auth-key=REDACTED disabled=no \
    networks=10.0.0.0/24 type=ptp
add area=backbone disabled=no networks=192.168.10.0/24 passive
add area=backbone disabled=no networks=192.168.20.0/24 passive
add area=backbone disabled=no networks=7.7.7.7/32 passive
/system identity
set name=DIST-2
/system note
set show-at-login=no
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=none
/tool mac-server ping
set enabled=no
/user group
add name=monitoring policy="local,read,winbox,!telnet,!ssh,!ftp,!reboot,!write\
    ,!policy,!test,!password,!web,!sniff,!sensitive,!api,!romon,!rest-api"
