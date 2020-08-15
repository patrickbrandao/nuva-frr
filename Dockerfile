
#========================================================================
#
# Container Debian 10.5 para laboratorio FRR
# * FRR
# * SNMP-Server
# * Network Tools
#
#========================================================================
#

FROM debian:10.5

# Variaveis globais (ambiente)
ENV \
	MAINTAINER="Patrick Brandao" \
	EMAIL=patrickbrandao@gmail.com \
    TERM=xterm \
    TZ=America/Sao_Paulo \
    PS1='\u@\h:\w\$ ' \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    DOMAIN=intranet.br

# Instalar pacotes
RUN ( \
    apt-get -y update || exit 11; \
    apt-get -y install \
        procps coreutils util-linux psmisc iproute2 net-tools vim \
        tcpdump whois fping nmap nmap-common \
        mtr iputils-arping iputils-ping iputils-tracepath \
        snmp snmpd \
        \
        frr \
        frr-doc \
        frr-pythontools \
        frr-rpki-rtrlib \
        frr-snmp || exit 12; \
    \
    echo "# Ativando servicos"; \
    sed -i 's#bgpd=no#bgpd=yes#' /etc/frr/daemons; \
    sed -i 's#ospfd=no#ospfd=yes#' /etc/frr/daemons; \
    sed -i 's#ospf6d=no#ospf6d=yes#' /etc/frr/daemons; \
    sed -i 's#ripd=no#ripd=yes#' /etc/frr/daemons; \
    sed -i 's#ripngd=no#ripngd=yes#' /etc/frr/daemons; \
    sed -i 's#babeld=no#babeld=yes#' /etc/frr/daemons; \
    sed -i 's#pbrd=no#pbrd=yes#' /etc/frr/daemons; \
    sed -i 's#bfdd=no#bfdd=yes#' /etc/frr/daemons; \
    \
    \
    mkdir -p /var/run/frr/; \
    chown frr:frr /var/run/frr; \
    \
    \
    echo "# Arquivos originais"; \
    mkdir -p /etc/setup/frr || exit 30; \
    cp -rav /etc/frr/daemons /etc/setup/frr/daemons || exit 31; \
    cp -rav /etc/frr/frr.conf /etc/setup/frr/frr.conf || exit 32; \
    cp -rav /etc/frr/vtysh.conf /etc/setup/frr/vtysh.conf || exit 33; \
    \
    echo "# Script de HALT"; \
    ( \
        echo '#!/bin/sh'; echo; \
        echo 'for app in watchfrr zebra bgpd ripd ripngd ospfd ospf6d babeld pbrd staticd bfdd; do killall $app; killall $app; done 2>/dev/null 1>/dev/null'; \
        echo 'exit 0'; \
    ) > /usr/sbin/frr-halt.sh; \
    chmod +x /usr/sbin/frr-halt.sh; \
    \
    \
    echo "# Script de BOOT"; \
    ( \
        echo '#!/bin/sh'; \
        echo; \
        echo 'dev=eth0'; \
        echo; \
        echo '[ "$DELETEGATEWAY" = "yes" ] && ip route del default 2>/dev/null'; echo; \
        echo; \
        echo '[ "$DELETEIPS" = "yes" ] && ip addr show dev $dev | grep "inet" | grep -v fe80 | awk "{print \$2}" | while read x; do ip addr del $x dev $dev; done'; \
        echo; \
        echo '[ "x$LOOPBACK4" = "x" ] || ip -4 addr add "$LOOPBACK4/32"  dev lo'; echo; \
        echo '[ "x$LOOPBACK6" = "x" ] || ip -6 addr add "$LOOPBACK6/128"  dev lo'; echo; \
        echo; \
        echo 'for vreg in $VLANS; do'; \
        echo '    vid=$(echo $vreg | cut -f1 -d"|")'; \
        echo '    vip4=$(echo $vreg | cut -f2 -d"|")'; \
        echo '    vip6=$(echo $vreg | cut -f3 -d"|")'; \
        echo '    vmac=$(echo $vreg | cut -f4 -d"|")'; \
        echo '    vdev="$dev.$vid"'; \
        echo; \
        echo '    ip link add link $dev name $vdev type vlan id $vid'; \
        echo '    [ "x$vmac" = "x" -o "$vmac" = "none" ] || ip link set $vdev address $vmac'; \
        echo '    ip link set up dev $vdev'; \
        echo; \
        echo '    [ "x$vip4" = "x" -o "$vip4" = "none" ] || ip -4 addr add "$vip4" dev $vdev'; \
        echo '    [ "x$vip6" = "x" -o "$vip6" = "none" ] || ip -6 addr add "$vip6" dev $vdev'; \
        echo; \
        echo 'done'; \
        echo; \
        echo '('; \
        echo '    echo "rocommunity public"'; \
        echo '    echo "rocommunity6 public"'; \
        echo '    echo "SysContact \"Admin\""'; \
        echo '    echo "SysLocation Docker"'; \
        echo '    echo "SysDescr FRR-Container"'; \
        echo '    echo "sysName $(hostname)"'; \
        echo '    echo "agentaddress unix:/run/snmpd.socket,udp:161,udp6:161,tcp6:161,tcp:161"'; \
        echo '    echo "com2sec notConfigUser  default  public"'; \
        echo '    echo "group notConfigGroup v1 notConfigUser"'; \
        echo '    echo "group notConfigGroup v2c notConfigUser"'; \
        echo '    echo "view    systemview           included      .1"'; \
        echo ') > /etc/snmp/snmpd.conf'; \
        echo; \
        echo 'service snmpd start'; \
        echo; \
        echo '# Defaults original FRR:'; \
        echo '[ -f /etc/frr/daemons ] || cp /etc/setup/frr/daemons /etc/frr/daemons'; \
        echo '[ -f /etc/frr/frr.conf ] || cp /etc/setup/frr/frr.conf /etc/frr/frr.conf'; \
        echo '[ -f /etc/frr/vtysh.conf ] || cp /etc/setup/frr/vtysh.conf /etc/frr/vtysh.conf'; \
        echo; \
        echo '# Move to /data/frr'; \
        echo 'mkdir -p "/data/frr"'; \
        echo '('; \
        echo '    cd /etc/frr'; \
        echo '    for xfile in *; do'; \
        echo '        [ -f "$xfile" ] || continue'; \
        echo '        [ -f "/data/frr/$xfile" ] && continue'; \
        echo '        cp "$xfile" "/data/frr/$xfile"'; \
        echo '    done'; \
        echo ')'; \
        echo; \
        echo '# Defaults data FRR:'; \
        echo '[ -f /data/frr/daemons ] || cp /etc/setup/frr/daemons /data/frr/daemons'; \
        echo '[ -f /data/frr/frr.conf ] || cp /etc/setup/frr/frr.conf /data/frr/frr.conf'; \
        echo '[ -f /data/frr/vtysh.conf ] || cp /etc/setup/frr/vtysh.conf /data/frr/vtysh.conf'; \
        echo; \
        echo 'rm -rf /etc/frr'; \
        echo 'ln -s /data/frr /etc/frr'; \
        echo 'chown -R frr:frr /data/frr /etc/frr'; \
        echo; \
        echo '/usr/lib/frr/watchfrr zebra bgpd ripd ripngd ospfd ospf6d babeld pbrd staticd bfdd'; \
        echo; \
    ) > /usr/sbin/frr-boot.sh; \
    chmod +x /usr/sbin/frr-boot.sh; \
)

# Script de BOOT
CMD /usr/sbin/frr-boot.sh



