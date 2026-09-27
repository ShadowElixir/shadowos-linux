# vim: set ft=make :

# Setup WARP via wgcf
[group("Network")]
setup-warp:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh

    echo "${green}Registering WARP account...${n}"
    wgcf register
    echo "${green}Generating WireGuard config...${n}"
    wgcf generate
    echo "${green}Copying config to /etc/wireguard/...${n}"
    sudo cp ./wgcf-profile.conf /etc/wireguard/
    echo "${green}Done! Run 'just toggle-warp' to connect.${n}"

# Toggle WARP connection
[group("Network")]
toggle-warp:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh

    if sudo wg show wgcf-profile &>/dev/null; then
        echo "${red}Disabling WARP...${n}"
        sudo wg-quick down wgcf-profile
    else
        echo "${green}Enabling WARP...${n}"
        sudo wg-quick up wgcf-profile
    fi
