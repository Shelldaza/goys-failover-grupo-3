# 2026-10-09 20:23:40 by RouterOS 7.16
# software id =
#
/interface ethernet
set [ find default-name=ether5 ] disabled=yes
set [ find default-name=ether6 ] disabled=yes
set [ find default-name=ether7 ] disabled=yes
set [ find default-name=ether8 ] disabled=yes
/port
set 0 name=serial0
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
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set ssh disabled=yes
set api disabled=yes
set api-ssl disabled=yes
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

