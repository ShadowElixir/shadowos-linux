# vim: set ft=make :
# Toggle kexec
[group("System")]
toggle-kexec:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh

    SYSCTL_CONF="/etc/sysctl.d/99-kexec.conf"

    if [ -f "$SYSCTL_CONF" ]; then
        echo "${red}Re-enabling kexec (removing restriction)...${n}"
        sudo rm -f "$SYSCTL_CONF"
        sudo sysctl -w kernel.kexec_load_disabled=0
    else
        echo "${green}Disabling kexec (hardening)...${n}"
        echo "kernel.kexec_load_disabled=1" | sudo tee "$SYSCTL_CONF" > /dev/null
        sudo sysctl --system
    fi