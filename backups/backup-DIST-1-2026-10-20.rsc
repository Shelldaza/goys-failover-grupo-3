# 2026-10-20 05:29:21 by RouterOS 7.16
# software id =
#
/interface ethernet
set [ find default-name=ether5 ] disabled=yes
set [ find default-name=ether6 ] disabled=yes
set [ find default-name=ether7 ] disabled=yes
set [ find default-name=ether8 ] disabled=yes
/interface vrrp
add authentication=ah interface=ether3 name=vrrp10 priority=150 version=2 \
    vrid=10
add authentication=ah interface=ether4 name=vrrp20 version=2 vrid=20
/port
set 0 name=serial0
/routing ospf instance
add disabled=no name=ospf-main router-id=6.6.6.6
/routing ospf area
add disabled=no instance=ospf-main name=backbone
/ip address
add address=10.0.0.14/30 comment="Enlace CORE-1" interface=ether1 network=\
    10.0.0.12
add address=10.0.0.22/30 comment="Enlace CORE-2" interface=ether2 network=\
    10.0.0.20
add address=192.168.10.2/24 comment="LAN USERS" interface=ether3 network=\
    192.168.10.0
add address=192.168.20.2/24 comment="LAN SERVERS" interface=ether4 network=\
    192.168.20.0
add address=6.6.6.6 comment=Loopback interface=lo network=6.6.6.6
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
add area=backbone disabled=no networks=6.6.6.6/32 passive
/system identity
set name=DIST-1
/system note
set show-at-login=no
/tool mac-server
set allowed-interface-list=none
/tool mac-server mac-winbox
set allowed-interface-list=none
/tool mac-server ping
set enabled=no
/tool netwatch
add comment="F4 monitoreo" down-script=\
    ":log warning \"NETWATCH: 2.2.2.2 ISP-1 DOWN\"" host=2.2.2.2 interval=10s \
    name=ISP-1-lo src-address=192.168.10.2 timeout=1s type=icmp up-script=\
    ":log info \"NETWATCH: 2.2.2.2 ISP-1 UP\""
add comment="F4 monitoreo" down-script=\
    ":log warning \"NETWATCH: 3.3.3.3 ISP-2 DOWN\"" host=3.3.3.3 interval=10s \
    name=ISP-2-lo src-address=192.168.10.2 timeout=1s type=icmp up-script=\
    ":log info \"NETWATCH: 3.3.3.3 ISP-2 UP\""
add comment="F4 monitoreo" down-script=":log warning \"NETWATCH: SRV DOWN\"" \
    host=192.168.20.100 interval=10s name=SRV timeout=1s type=icmp up-script=\
    ":log info \"NETWATCH: SRV UP\""
add comment="F4 monitoreo" down-script=\
    ":log warning \"NETWATCH: CORE-1 DOWN\"" host=10.0.0.13 interval=10s \
    name=CORE-1 timeout=1s type=icmp up-script=\
    ":log info \"NETWATCH: CORE-1 UP\""
add comment="F4 monitoreo" down-script=\
    ":log warning \"NETWATCH: CORE-2 DOWN\"" host=10.0.0.21 interval=10s \
    name=CORE-2 timeout=1s type=icmp up-script=\
    ":log info \"NETWATCH: CORE-2 UP\""
/user group
add name=monitoring policy="local,read,winbox,!telnet,!ssh,!ftp,!reboot,!write\
    ,!policy,!test,!password,!web,!sniff,!sensitive,!api,!romon,!rest-api"
