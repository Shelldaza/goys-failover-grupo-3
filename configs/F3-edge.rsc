# 2026-10-16 19:03:50 by RouterOS 7.16
# software id =
#
/interface ethernet
set [ find default-name=ether5 ] disabled=yes
set [ find default-name=ether6 ] disabled=yes
set [ find default-name=ether7 ] disabled=yes
set [ find default-name=ether8 ] disabled=yes
/interface list
add name=F3-WAN
add name=F3-CORE
/port
set 0 name=serial0
/routing ospf instance
add disabled=no name=ospf-main originate-default=if-installed router-id=\
    1.1.1.1
/routing ospf area
add disabled=no instance=ospf-main name=backbone
/interface list member
add interface=ether1 list=F3-WAN
add interface=ether2 list=F3-WAN
add interface=ether3 list=F3-CORE
add interface=ether4 list=F3-CORE
/ip address
add address=203.0.113.2/30 comment="Enlace ISP-1" interface=ether1 network=\
    203.0.113.0
add address=198.51.100.2/30 comment="Enlace ISP-2" interface=ether2 network=\
    198.51.100.0
add address=10.0.0.1/30 comment="Enlace CORE-1" interface=ether3 network=\
    10.0.0.0
add address=10.0.0.5/30 comment="Enlace CORE-2" interface=ether4 network=\
    10.0.0.4
add address=1.1.1.1 comment=Loopback interface=lo network=1.1.1.1
/ip dhcp-client
add disabled=yes interface=ether1
/ip firewall address-list
add address=192.168.10.0/24 list=F3-LANS
add address=192.168.20.0/24 list=F3-LANS
/ip firewall filter
add action=accept chain=input comment=\
    "F3 INPUT - conexiones establecidas y relacionadas" connection-state=\
    established,related
add action=drop chain=input comment="F3 INPUT - descartar invalidas" \
    connection-state=invalid
add action=accept chain=input comment="F3 INPUT - BGP ISP-1" dst-port=179 \
    in-interface=ether1 protocol=tcp src-address=203.0.113.1
add action=accept chain=input comment="F3 INPUT - BGP ISP-2" dst-port=179 \
    in-interface=ether2 protocol=tcp src-address=198.51.100.1
add action=accept chain=input comment="F3 INPUT - OSPF CORE-1" in-interface=\
    ether3 protocol=ospf src-address=10.0.0.2
add action=accept chain=input comment="F3 INPUT - OSPF CORE-2" in-interface=\
    ether4 protocol=ospf src-address=10.0.0.6
add action=accept chain=input comment="F3 INPUT - ICMP diagnostico" protocol=\
    icmp
add action=accept chain=input comment="F3 INPUT - Winbox desde PC-USER" \
    dst-port=8291 in-interface-list=F3-CORE protocol=tcp src-address=\
    192.168.10.100
add action=drop chain=input comment="F3 INPUT - descartar resto"
add action=accept chain=forward comment=\
    "F3 FORWARD - conexiones establecidas y relacionadas" connection-state=\
    established,related
add action=drop chain=forward comment="F3 FORWARD - descartar invalidas" \
    connection-state=invalid
add action=accept chain=forward comment="F3 FORWARD - LAN hacia ISP" \
    in-interface-list=F3-CORE out-interface-list=F3-WAN src-address-list=\
    F3-LANS
add action=accept chain=forward comment=\
    "F3 FORWARD - transito entre LAN internas" dst-address-list=F3-LANS \
    in-interface-list=F3-CORE out-interface-list=F3-CORE src-address-list=\
    F3-LANS
add action=drop chain=forward comment="F3 FORWARD - descartar resto"
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set api disabled=yes
set winbox address=192.168.10.100/32
set api-ssl disabled=yes
/routing bgp connection
add address-families=ip as=65000 disabled=no input.filter=F3-FROM-ISP1 \
    local.address=203.0.113.2 .role=ebgp name=F3-ISP-1 output.filter-chain=\
    F3-EDGE-OUT .redistribute=ospf remote.address=203.0.113.1/32 .as=65001 \
    router-id=1.1.1.1 routing-table=main
add address-families=ip as=65000 disabled=no input.filter=F3-FROM-ISP2 \
    local.address=198.51.100.2 .role=ebgp name=F3-ISP-2 output.filter-chain=\
    F3-EDGE-OUT .redistribute=ospf remote.address=198.51.100.1/32 .as=65002 \
    router-id=1.1.1.1 routing-table=main
/routing filter rule
add chain=F3-EDGE-OUT rule="if (dst == 192.168.10.0/24) { accept; }"
add chain=F3-EDGE-OUT rule="if (dst == 192.168.20.0/24) { accept; }"
add chain=F3-EDGE-OUT rule="reject;"
add chain=F3-FROM-ISP1 rule=\
    "if (dst == 0.0.0.0/0) { set bgp-local-pref 200; accept; }"
add chain=F3-FROM-ISP1 rule="if (dst == 2.2.2.2/32) { accept; }"
add chain=F3-FROM-ISP1 rule="reject;"
add chain=F3-FROM-ISP2 rule=\
    "if (dst == 0.0.0.0/0) { set bgp-local-pref 100; accept; }"
add chain=F3-FROM-ISP2 rule="if (dst == 3.3.3.3/32) { accept; }"
add chain=F3-FROM-ISP2 rule="reject;"
/routing ospf interface-template
add area=backbone auth=md5 auth-id=1 auth-key="REDACTED" disabled=no \
    networks=10.0.0.0/24 type=ptp
add area=backbone disabled=no networks=1.1.1.1/32 passive
/system identity
set name=EDGE
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

