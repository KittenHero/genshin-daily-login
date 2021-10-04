#!/bin/sh
set -e

VALID_BROWSERS='chrome firefox edge'
VALID_LANGS='zh-cn zh-tw de-de en-us es-es fr-fr id-id ja-jp ko-kr pt-pt th-th vi-vn'
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
contains() {
    echo $1 | grep -Eq "(^|[[:space:]])$2($|[[:space:]])"
}
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BOLD=$(tput bold)

echo "Setting up virtual environment..."
pipenv install


echo
echo "${BOLD}Please login and open the daily login page${RESET}:
${GREEN}https://webstatic-sea.mihoyo.com/ys/event/signin-sea/index.html?act_id=e202102251931481&lang=en-us${RESET}
on one of the following browser: (${BOLD}${VALID_BROWSERS}${RESET})"

while true
do
    read -p 'Browser (default=chrome): ' browser
    browser=${browser:-chrome}
    browser=$(echo $browser | tr '[:upper:]' '[:lower:]')
    if contains "$VALID_BROWSERS" $browser
    then
        break
    else
        echo "${RED}$browser${RESET} is not a valid browser ($VALID_BROWSERS).  Try again."
    fi
done

while true
do
    read -p 'Choose locale (default=en-us): ' locale
    locale=${locale:-en-us}
    if contains "$VALID_LANGS" $locale
    then
        break
    else
        echo "${RED}$locale${RESET} is not a valid locale ($VALID_LANGS).  Try again."
    fi
done

echo
echo "Retreiving $browser cookies"
pipenv run python main.py --browser $browser --lang $locale

echo "Installing systemd unit files"
echo "[Unit]
Description=Auto login for Genshin Impact Hoyolab

[Service]
Type=oneshot
WorkingDirectory=$(pwd)
ExecStart=$(which pipenv) run python main.py --lang $locale

[Install]
WantedBy=default.target
" > $XDG_CONFIG_HOME/systemd/user/genshin-weblogin.service

echo "[Unit]
Description=Run Hoyolab Genshin Impact Auto Login Daily

[Timer]
OnCalendar=*-*-* 08:00:00 UTC
Persistent=true

[Install]
WantedBy=timers.target
" > $XDG_CONFIG_HOME/systemd/user/genshin-weblogin.timer

echo "Activating service"
systemctl --user enable --now genshin-weblogin.timer

systemctl --user status genshin-weblogin.service
