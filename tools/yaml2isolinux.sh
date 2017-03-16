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
#            printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
            if ($2 == "entry") {
                printf("label ks-%s\n", $3);
            }
            if ($2 == "menulabel") {
                printf("  menu label ks-%s\n", $3);
                printf("  kernel vmlinuz\n  append");
            }
            if ($2 == "ks") {
                printf(" ks=%s", $3);
            }
            if ($2 == "append") {
                printf(" %s", $3);
            }
            if ($2 == "method") {
                printf(" method=%s", $3);
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
            if ($2 == "dns") {
                printf(" dns=%s\n", $3);
            }
        }
    }' | sed 's/_=/+=/g'
}

parse_yaml templates/config.yaml