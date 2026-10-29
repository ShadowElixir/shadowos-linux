# vim: set ft=make :
# Toggle Lockdown (Confidentiality)
[group("System")]
toggle-lockdown:
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh

    if rpm-ostree kargs | grep -q "lockdown=confidentiality"; then
        echo "${red}Disabling Lockdown (confidentiality)...${n}"
        sudo rpm-ostree kargs --delete-if-present=lockdown=confidentiality
    else
        echo "${green}Enabling Lockdown (confidentiality)...${n}"
        sudo rpm-ostree kargs --append-if-missing=lockdown=confidentiality
    fi