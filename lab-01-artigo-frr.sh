#!/bin/sh

# Lab do artigo FRR do site patrickbrandao.com

    # Rede:
    docker network create frrlab \
        -d bridge \
        --subnet 198.19.128.1/17 \
        --ipv6 --subnet=2001:db8:198:19::/64 \
        --opt com.docker.network.bridge.enable_icc=true \
        --opt com.docker.network.driver.mtu=9000 \
        2>/dev/null

    # BGP
    ./run-frr.sh -N frrlab -n bgp -m 00:11:11:aa:aa:aa -g -a \
        -v '2|172.16.2.2/30|2001:48dc:1001::2/126|00:fa:da:ba:ba:00' \
        -v '12|10.0.0.1/30|2804:cafe:ffff:a001::1/126|00:be:ba:ca:fe:12' \
        -lo4 10.255.255.1 -lo6 2804:cafe:ffff:ffff::1

    # CORE
    ./run-frr.sh -N frrlab -n core -m 00:22:22:bb:bb:bb \
        -v '12|10.0.0.2/30|2804:cafe:ffff:a012::2/126|00:be:ba:ca:fe:21' \
        -v '23|10.90.0.1/30|2804:cafe:ffff:a002::1/126|00:fa:ca:da:00:23' \
        -lo4 10.255.255.2 -lo6 2804:cafe:ffff:ffff::2

    # BND
    ./run-frr.sh -N frrlab -n bng -m 00:33:33:cc:cc:cc \
        -v '23|10.90.0.2/30|2804:cafe:ffff:a002::2/126|00:fa:ca:da:00:32' \
        -v '70|none|none|00:ba:1a:1a:00:01' \
        -lo4 10.255.255.3 -lo6 2804:cafe:ffff:ffff::3

exit


