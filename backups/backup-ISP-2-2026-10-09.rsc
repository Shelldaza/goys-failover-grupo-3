# 2026-10-09 20:22:07 by RouterOS 7.16
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
add address=198.51.100.1/30 comment="Enlace EDGE" interface=ether1 network=\
    198.51.100.0
add address=3.3.3.3 comment=Loopback interface=lo network=3.3.3.3
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
set name=ISP-2
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