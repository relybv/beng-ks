parse_yaml() {
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            if ($2 == "entry") {
                printf("menuentry \"", $3);
            }
            if ($2 == "menulabel") {
                printf("ks-%s\"  --class fedora --class gnu-linux --class gnu --class os {\n", $3);
                printf("  linuxefi /images/pxeboot/vmlinuz ");
            }
            if ($2 == "ks") {
                printf(" ks=%s", $3);
            }
            if ($2 == "append") {
                printf(" %s", $3);
            }
            if ($2 == "repo") {
                printf(" repo=%s", $3);
            }
            if ($2 == "ip") {
                printf(" ip=%s", $3);
            }
            if ($2 == "netmask") {
                printf(" netmask=%s", $3);
            }
            if ($2 == "gateway") {
                printf(" gateway=%s", $3);
            }
            if ($2 == "nameserver") {
                printf(" nameserver=%s\n  initrdefi /images/pxeboot/initrd.img\n}\n", $3);
            }
        }
    }' | sed 's/_=/+=/g'
}

parse_yaml templates/config.yaml
