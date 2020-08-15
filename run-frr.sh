#!/bin/sh

_abort(){ echo; echo $@; echo; exit 1; }

# Variaveis
    IMAGE=nuva-frr
    NAME=$IMAGE
    DOMAIN=intranet.br
    UUID=$(uuid -1)
    ROOT_PASSWORD=tulipa
    DNS=8.8.8.8,1.1.1.1
    MAC=""
    IPV4=""
    IPV6=""
    LOOPBACK4=""
    LOOPBACK6=""
    NETWORK=docker0
    VLANS=""
    WEB_PORT=0
    SSH_PORT=0
    DEBUG=no
    STORAGE="/storage"
    DELETEGATEWAY=yes
    DELETEIPS=yes

# Funcoes
    _empty_help(){ if [ "x$1" = "x" ]; then _help; exit $2; fi; }
    PROGNAME="$0"
    _help(){
        echo
        echo "$PROGNAME [options]"
        echo
        echo "Criar container FRR:"
        echo
        echo "Argumentos:"
        echo "  -i    IMAGE          : Nome da imagem, padrao: $IMAGE"
        echo "  -n    NAME           : Nome do container, padrao: $NAME"
        echo "  -r    ROOT-PASSWORD  : Senha de root, padrao: $ROOT_PASSWORD"
        echo "  -D    DOMAINNAME     : Nome de dominio, padrao: $DOMAIN"
        echo "  -d    DNS            : Servidor DNS, padrao: $DNS"
        echo "  -N    NETWORK-NAME   : Nome da rede Docker, padrao: $NETWORK"
        echo "  -m    MAC-ADDRESS    : Endereco MAC da interface, padrao: automatico"
        echo "  -4    IPv4           : Endereco IPv4 fixo, padrao: automatico"
        echo "  -6    IPv6           : Endereco IPv6 fixo, padrao: automatico"
        echo "  -lo4  Loopback IPv4  : Endereco de loopback IPv4, padrao: ausente"
        echo "  -lo6  Loopback IPv6  : Endereco de loopback IPv6, padrao: ausente"
        echo "  -v    VLANDEF        : Definicao de VLAN e IPs, formato: vlanid|ipv4/nn|ipv6/nn"
        echo "  -w    WEB-HTTP-PORT  : Porta de redirecionamento WEB HTTP, padrao 0 (desativado)"
        echo "  -s    SSH-PORT       : Porta de redirecionamento SSH, padrao 0 (desativado)"
        echo "  -x    STORAGE-DIR    : Pasta de storage para sub-pasta com nome do container, padrao: $STORAGE"
        echo "  -g                   : Manter gateway padrao do container, padrao: remover gateway"
        echo "  -a                   : Manter IPs da rede padrao, padrao: remover enderecos iniciais"
        echo "  -X                   : Ativar DEBUG, nao efetivar criacao do container"
        echo
        echo "Exemplo:"
        echo "# Dois roteadores na mesma rede padrao:"
        echo "  ./run.sh -n bgp-01 -r SuperSenha2020 -d 8.8.8.8,1.1.1.1 -w 1080 -s 1022"
        echo "  ./run.sh -n bgp-02 -r SuperSenha2020 -d 8.8.8.8,1.1.1.1 -w 2080 -s 2022"
        echo
        echo "# Roteador numa rede especifica:"
        echo "  ./run.sh -n bgp    -r SuperSenha2020 -d 8.8.8.8,1.1.1.1 -w 1080 -s 1022 -v '70|192.168.12.1/30|2001:db8:192:168:12::1/126'"
        echo
        echo "# Roteadores participando de duas redes VLANs:"
        echo "  ./run.sh -n bgp    -r SuperSenha2020 -w 1080 -s 1022 -v '8|10.8.0.1/30|2804:cafe:ffff:fff8::1/126' -v '9|10.9.0.1/30|2804:cafe:ffff:fff9::1/126'"
        echo "  ./run.sh -n core   -r SuperSenha2020 -w 2080 -s 2022 -v '8|10.8.0.2/30|2804:cafe:ffff:fff8::2/126'"
        echo "  ./run.sh -n bras   -r SuperSenha2020 -w 3080 -s 3022 -v '9|10.9.0.2/30|2804:cafe:ffff:fff9::2/126'"
        echo
        echo
        echo
    }

# Processar argumentos
    ARGS="$@"
    while [ 0 ]; do
        #echo "1=[$1] 2=[$2] 3=[$3] 4=[$4] 5=[$5] 6=[$6] 7=[$7] 8=[$8]"
        # Ajuda
        if [ "$1" = "-h" -o "$1" = "--h" -o "$1" = "--help" -o "$1" = "help" ]; then
            _help; exit 0;

        # Nome da imagem
        elif [ "$1" = "-i" -o "$1" = "-img" -o "$1" = "--image" ]; then
            _empty_help "$2" 10; IMAGE="$2"; shift 2; continue

        # Nome do container
        elif [ "$1" = "-n" -o "$1" = "-name" -o "$1" = "--name" ]; then
            _empty_help "$2" 11; NAME="$2"; shift 2; continue

        # Senha de root
        elif [ "$1" = "-r" -o "$1" = "-root" -o "$1" = "--pass" -o "$1" = "--password" -o "$1" = "--root-password" ]; then
            _empty_help "$2" 12; ROOT_PASSWORD="$2"; shift 2; continue

        # DOMAIN
        elif [ "$1" = "-D" -o "$1" = "-domain" -o "$1" = "--domain" -o "$1" = "--domain-name" -o "$1" = "--dname" ]; then
            _empty_help "$2" 13; DOMAIN="$2"; shift 2; continue

        # NETWORK
        elif [ "$1" = "-N" -o "$1" = "-net" -o "$1" = "--network" ]; then
            _empty_help "$2" 14; NETWORK="$2"; shift 2; continue

        # MAC
        elif [ "$1" = "-m" -o "$1" = "-mac" -o "$1" = "--mac" -o "$1" = "-mac-addr" -o "$1" = "--mac-addr" -o "$1" = "-mac-address" -o "$1" = "--mac-address" ]; then
            _empty_help "$2" 15; MAC="$2"; shift 2; continue

        # IPV4
        elif [ "$1" = "-4" -o "$1" = "-ip" -o "$1" = "--ip" -o "$1" = "-ip4" -o "$1" = "--ip4" -o "$1" = "-ipv4" -o "$1" = "--ipv4" ]; then
            _empty_help "$2" 16; IPV4="$2"; shift 2; continue

        # IPV6
        elif [ "$1" = "-6" -o "$1" = "-ip6" -o "$1" = "--ip6" -o "$1" = "-ipv6" -o "$1" = "--ipv6" ]; then
            _empty_help "$2" 17; IPV6="$2"; shift 2; continue

        # Loopback IPV4
        elif [ "$1" = "--loopback" -o "$1" = "-lo" -o "$1" = "-l4" -o "$1" = "--l4" -o "$1" = "-lo4" -o "$1" = "--lo4" -o "$1" = "-loopback-ipv4" -o "$1" = "--loopback-ipv4" ]; then
            _empty_help "$2" 18; LOOPBACK4="$2"; shift 2; continue

        # Loopback IPV6
        elif [ "$1" = "--loopback6" -o "$1" = "-lo6" -o "$1" = "-l6" -o "$1" = "--l6" -o "$1" = "-lo6" -o "$1" = "--lo6" -o "$1" = "-loopback-ipv6" -o "$1" = "--loopback-ipv6" ]; then
            _empty_help "$2" 19; LOOPBACK6="$2"; shift 2; continue

        # VLANS
        elif [ "$1" = "-v" -o "$1" = "--v" -o "$1" = "-vlan" -o "$1" = "--vlan" ]; then
            _empty_help "$2" 20; VLANS="$VLANS $2"; shift 2; continue

        # DNS
        elif [ "$1" = "-d" -o "$1" = "-dns" -o "$1" = "--dns" -o "$1" = "--nameserver" -o "$1" = "--name-server" ]; then
            _empty_help "$2" 21; DNS="$2"; shift 2; continue

        # PORTA WEB
        elif [ "$1" = "-w" -o "$1" = "-web" -o "$1" = "--web" -o "$1" = "--webport" -o "$1" = "--web-port" -o "$1" = "--http" -o "$1" = "--http-port" ]; then
            _empty_help "$2" 22; WEB_PORT="$2"; shift 2; continue

        # PORTA SSH
        elif [ "$1" = "-s" -o "$1" = "-ssh" -o "$1" = "--ssh" -o "$1" = "--sshport" -o "$1" = "--ssh-port" ]; then
            _empty_help "$2" 23; SSH_PORT="$2"; shift 2; continue

        # Storage
        elif [ "$1" = "-x" -o "$1" = "-store" -o "$1" = "--store" -o "$1" = "--storage" -o "$1" = "--data" ]; then
            _empty_help "$2" 24; STORAGE="$2"; shift 2; continue

        # DELETEGATEWAY
        elif [ "$1" = "-g" -o "$1" = "--g" ]; then
            DELETEGATEWAY=no; shift 1; continue

        # DELETEIPS
        elif [ "$1" = "-a" -o "$1" = "--a" ]; then
            DELETEIPS=no; shift 1; continue

        # DEBUG
        elif [ "$1" = "-X" -o "$1" = "-debug" -o "$1" = "--debug" ]; then
            DEBUG=yes; shift 1; continue

        else
            # argumento padrao: NAME
            if [ "x$NAME" = "x" ]; then
                NAME="$1"
                [ "x$1" = "x" ] || { shift; continue; }
            fi
            break
        fi
    done

    # Defaults
    # - IPs sem mascara
    IPV4=$(echo "$IPV4" | cut -f1 -d'/')
    IPV6=$(echo "$IPV6" | cut -f1 -d'/')
    LOOPBACK4=$(echo "$LOOPBACK4" | cut -f1 -d'/')
    LOOPBACK6=$(echo "$LOOPBACK6" | cut -f1 -d'/')

    # - ipv4 precisa ser sintaticamente correto
    echo "$IPV4"| egrep -q '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || IPV4="auto"

    # rede padrao nao configuravel
    [ "x$NETWORK" = "x" -o "$NETWORK" = "docker" -o "$NETWORK" = "docker0" -o "$NETWORK" = "bridge" ] \
        && NETWORK="docker0"
    [ "x$IPV4" = "x" ] && IPV4="auto"
    [ "x$IPV6" = "x" ] && IPV6="auto"

    # - vlans
    VLANS=$(echo $VLANS | sed 's#,# #g')

    # - mac principal
    HMAC=$(echo $MAC | sed 's#[^a-fA-F0-9]##g')
    MAC=""
    echo "$HMAC" | egrep -q '^[a-fA-F0-9]{12}$' && {
        mp1=$(echo $HMAC | cut -b1-2)
        mp2=$(echo $HMAC | cut -b3-4)
        mp3=$(echo $HMAC | cut -b5-6)
        mp4=$(echo $HMAC | cut -b7-8)
        mp5=$(echo $HMAC | cut -b9-10)
        mp6=$(echo $HMAC | cut -b11-12)
        MAC="$mp1:$mp2:$mp3:$mp4:$mp5:$mp6"
    }

    # Exibir variaveis
    echo
    echo "[container]"
    echo "  image.....................: $IMAGE"
    echo "  name......................: $NAME"
    echo "  domain....................: $DOMAIN"
    echo "  network...................: $NETWORK"
    echo "  mac.......................: $MAC"
    echo "  ipv4......................: $IPV4"
    echo "  ipv6......................: $IPV6"
    echo "  loopback ipv4.............: $LOOPBACK4"
    echo "  loopback ipv6.............: $LOOPBACK6"
    echo "  deletegateway.............: $DELETEGATEWAY"
    echo "  deleteips.................: $DELETEIPS"
    echo "  vlans.....................: $VLANS"
    echo "  root password.............: $ROOT_PASSWORD"
    echo "  dns nameserver............: $DNS"
    echo "  http port.................: $WEB_PORT"
    echo "  ssh port..................: $SSH_PORT"
    echo "  storage directory.........: $STORAGE"
    echo

    # Criticar variaveis
    # - Nao pode ser vazio
    [ "x$IMAGE" = "x" ] && _abort "Informe o nome da imagem" 51
    [ "x$NAME" = "x" ]  && _abort "Informe o nome do container" 52
    [ "x$DOMAIN" = "x" ]  && _abort "Informe o nome do dominio" 53
    [ "x$ROOT_PASSWORD" = "x" ] && _abort "Informe a senha de root" 54
    [ "x$WEB_PORT" = "x" ] && _abort "Informe a porta web/http" 56
    [ "x$SSH_PORT" = "x" ] && _abort "Informe a porta ssh" 57
    [ "x$STORAGE" = "x" ] && _abort "Informe o caminho da pasta de storage" 58
    # - Formato
    echo "$WEB_PORT" | egrep -q '^[0-9]+$' || WEB_PORT=0; #_abort "Porta HTTP nao numerica" 61
    echo "$SSH_PORT" | egrep -q '^[0-9]+$' || SSH_PORT=0; # _abort "Porta SSH nao numerica" 62
    mkdir -p "$STORAGE" 2>/dev/null
    [ -d "$STORAGE" ] || _abort "Pasta de storage [$STORAGE] nao existe" 63

# Dados persistentes

    # - pasta compartilhada entre todas as VPSs
    SHAREDIR="$STORAGE/shared"
    mkdir -p "$SHAREDIR"

    # - pasta de dados privados persistentes da VPS
    DATADIR="$STORAGE/$NAME"
    mkdir -p "$DATADIR"


# Gerar argumentos de rede principal:
    NETARG=""
    if [ "$NETWORK" = "docker0" ]; then
        # rede padrao, nao permite fixar ip
        IPV4=""
        IPV6=""
        NETWORK=""
    fi

	# rede personalizada
    [ "x$NETWORK" = "x" ] || {
        NETARG="$NETARG --network $NETWORK"
        [ "$IPV4" = "auto" ] || NETARG="$NETARG --ip=$IPV4"
        [ "$IPV6" = "auto" ] || NETARG="$NETARG --ip6=$IPV6"
    }
    # mac personalizado
    MACARG=""
    [ "x$MAC" = "x" ] || MACARG="--mac-address=$MAC"

# Gerar argumento de vlans provisionadas no boot
    VLANSARG=""
    [ "x$VLANS" = "x" ] || VLANSARG="--env VLANS='$VLANS'"

# Argumento de portas publicada externamente
    HTTPPORT_ARG=""
    SSHPORT_ARG=""
    [ "$WEB_PORT" = "0" ] || HTTPPORT_ARG="-p $WEB_PORT:80/tcp"
    [ "$SSH_PORT" = "0" ] || SSHPORT_ARG="-p $SSH_PORT:22/tcp"

# Gerar comando DOCKER
    # arquivo de cache
    runcache="/tmp/run-$IMAGE-$NAME.sh"
    (
        echo '#!/bin/sh'
        echo
        echo docker run -d --restart=always \
            -h $NAME.$DOMAIN --name=$NAME \
            $NETARG $MACARG \
            \
            --sysctl kernel.msgmnb=131072000 \
            --sysctl kernel.msgmax=131072000 \
            --sysctl kernel.msgmni=65536000 \
            \
            --sysctl net.ipv6.conf.default.disable_ipv6=0 \
            --sysctl net.ipv6.conf.default.autoconf=1 \
            --sysctl net.ipv6.conf.default.accept_ra=1 \
            --sysctl net.ipv6.conf.default.use_tempaddr=1 \
            --sysctl net.ipv6.conf.default.forwarding=1 \
            --sysctl net.ipv6.conf.all.forwarding=1 \
            \
            --user=root --cap-add=ALL --privileged \
            \
            --env ROOT_PASSWORD=$ROOT_PASSWORD --env DNS=$DNS \
            --env DELETEGATEWAY=$DELETEGATEWAY --env DELETEIPS=$DELETEIPS \
            --env LOOPBACK4=$LOOPBACK4 --env LOOPBACK6=$LOOPBACK6 \
            $VLANSARG \
            \
            $HTTPPORT_ARG $SSHPORT_ARG \
            \
            --mount type=bind,source=$SHAREDIR,destination=/shared,readonly=false \
            --mount type=bind,source=$DATADIR,destination=/data,readonly=false \
                $IMAGE
        echo 'exit $?'
        echo
    ) > $runcache
    echo
    if [ "$DEBUG" = "no" ]; then
	    echo "#> Executando: $runcache"
	    cat $runcache
	    echo
    	sh $runcache || _abort "Erro ao rodar container: $NAME, script $runcache"
	    echo
	    echo "Container criado com sucesso: $NAME"
    else
    	echo "#> Debug ativado, container nao efetivando."
    	echo "#> Comando:"
    	cat $runcache
    fi
    echo

exit 0



