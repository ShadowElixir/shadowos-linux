# vim: set ft=make :
# Toggle kexec
[group("System")]
toggle-kexec:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh

    if rpm-ostree kargs | grep -q "sysctl.kernel.kexec_load_disabled=1"; then
        echo "${red}Re-enabling kexec (removing restriction)...${n}"
        sudo rpm-ostree kargs --delete-if-present=sysctl.kernel.kexec_load_disabled=1
    else
        echo "${green}Disabling kexec (hardening)...${n}"
        sudo rpm-ostree kargs --append-if-missing=sysctl.kernel.kexec_load_disabled=1
    fi