# 2026-10-16 18:58:53 by RouterOS 7.16
# software id =
#
/interface ethernet
set [ find default-name=ether2 ] disabled=yes
set [ find default-name=ether3 ] disabled=yes
set [ find default-name=ether4 ] disabled=yes
set [ find default-name=ether5 ] disabled=yes
set [ find default-name=ether6 ] disabled=yes
set [ find default-name=ether7 ] disabled=yes
set [ find default-name=ether8 ] disabled=yes
/port
set 0 name=serial0
/ip address
add address=203.0.113.1/30 comment="Enlace EDGE" interface=ether1 network=\
    203.0.113.0
add address=2.2.2.2 comment=Loopback interface=lo network=2.2.2.2
/ip dhcp-client
add disabled=yes interface=ether1
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/routing bgp connection
add address-families=ip as=65001 disabled=no input.filter=F3-ISP-IN \
    local.address=203.0.113.1 .role=ebgp name=F3-EDGE \
    output.default-originate=always .filter-chain=F3-ISP-OUT .redistribute=\
    connected remote.address=203.0.113.2/32 .as=65000 router-id=2.2.2.2 \
    routing-table=main
/routing filter rule
add chain=F3-ISP-IN rule="if (dst == 192.168.10.0/24) { accept; }"
add chain=F3-ISP-IN rule="if (dst == 192.168.20.0/24) { accept; }"
add chain=F3-ISP-IN rule="reject;"
add chain=F3-ISP-OUT rule="if (dst == 2.2.2.2/32) { accept; }"
add chain=F3-ISP-OUT rule="if (dst == 0.0.0.0/0) { accept; }"
add chain=F3-ISP-OUT rule="reject;"
/system identity
set name=ISP-1
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

