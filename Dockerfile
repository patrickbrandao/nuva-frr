
#========================================================================
#
# Container Debian 10.5 para laboratorio FRR
# * FRR
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
        procps coreutils util-linux psmisc iproute2 net-tools \
        tcpdump whois fping nmap nmap-common \
        mtr iputils-arping iputils-ping iputils-tracepath \
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
        echo '#!/bin/sh'; echo; echo '[ "$DELETEGATEWAY" = "yes" ] && ip route del default 2>/dev/null'; echo; \
        echo '/usr/sbin/frr-halt.sh'; \
        echo 'cd /etc/frr'; \
        echo '/usr/lib/frr/watchfrr zebra bgpd ripd ripngd ospfd ospf6d babeld pbrd staticd bfdd'; \
    ) > /usr/sbin/frr-boot.sh; \
    chmod +x /usr/sbin/frr-boot.sh; \
)

# Script de BOOT
CMD /usr/lib/frr/watchfrr zebra bgpd ripd ripngd ospfd ospf6d babeld pbrd staticd bfdd




