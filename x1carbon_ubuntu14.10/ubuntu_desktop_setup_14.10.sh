#!/bin/bash

if [[ $# != 1 ]]; then
  echo
  echo "usage: $0 [packages|dotfiles|bugfixes|wmtweaks]"
  echo
  exit 1
fi


if [[ $1 == "packages" ]]; then
  wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
  sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list'
  sudo apt-get update
  sudo apt-get -y install google-chrome-stable

  #TODO: build out more complete list of packages to install
  sudo apt-get -y install git vim ttf-anonymous-pro indicator-multiload

  #TODO: find more crap to purge
  sudo apt-get -y purge cups cups-server-common cups-daemon cups-common cups-browsed cups-pk-helper libreoffice-core libreoffice-common libreoffice-style-human thunderbird account-plugin-aim account-plugin-facebook account-plugin-flickr account-plugin-google account-plugin-jabber account-plugin-salut account-plugin-windows-live account-plugin-yahoo evolution-data-server-online-accounts evolution-data-server brasero-common rhythmbox rhythmbox-data firefox firefox-locale-en flashplugin-installer empathy-common webaccounts-extension-common transmission-common totem-common libtotem0 libtotem-plparser18 indicator-messages libwhoopsie0 libwhoopsie-preferences0 libgoa-1.0-common unity-lens-music unity-lens-video unity-lens-files unity-scopes-runner unity-scope-musicstores unity-scope-video-remote zeitgeist-core avahi-daemon avahi-autoipd 
fi

if [[ $1 == "dotfiles" ]]; then
  #BEFORE RUNNING:
  #CREATE A KEY:
  #  ssh-keygen -t rsa -C whbeers@gmail.com -f id_rsa_$(hostname -s)
  #ADD TO GITHUB
  #  cat ~/.ssh/id_rsa_$(hostname -s).pub  
  #ADD TO AGENT
  #  ssh-add id_rsa_$(hostname -s)
  
  GITROOT=~/src
  mkdir -p $GITROOT
  for repo in laptop-configs homenas-configs appengine; do
    if [[ ! -d ${GITROOT}/${repo} ]]; then
      (cd $GITROOT && git clone git@github.com:whbeers/${repo}.git)
    fi
  done  

  if [[ ! -d $GITROOT/solarized ]]; then 
    (cd $GITROOT && git clone git://github.com/altercation/solarized.git)
  fi
  if [[ ! -d $GITROOT/gnome-terminal-colors-solarized ]]; then  
    (cd $GITROOT && git clone git://github.com/sigurdga/gnome-terminal-colors-solarized)
  fi

  mkdir -p ~/.ssh
  mkdir -p ~/.vim/colors
  mkdir -p ~/.config/autostart

  if [[ -d $GITROOT/laptop-configs/dotfiles ]]; then
    cp $GITROOT/laptop-configs/dotfiles/.vimrc ~
    cp $GITROOT/laptop-configs/dotfiles/.bash* ~
    cp $GITROOT/laptop-configs/dotfiles/.profile* ~
    cp $GITROOT/laptop-configs/dotfiles/.gitconfig ~
    cp $GITROOT/laptop-configs/dotfiles/.Xresources ~
    cp $GITROOT/laptop-configs/dotfiles/XTerm ~
    cp $GITROOT/laptop-configs/dotfiles/.ssh/config ~/.ssh/
    cp $GITROOT/laptop-configs/dotfiles/desktopOpen.conf ~/.config/upstart/
  fi

  if [[ -d $GITROOT/solarized ]]; then
    cp $GITROOT/solarized/vim-colors-solarized/colors/solarized.vim ~/.vim/colors
  fi
fi



if [[ $1 == "bugfixes" ]]; then
  #BUG: https://bugs.freedesktop.org/show_bug.cgi?id=88609
  # a complete workaround for my (trackpad-disabled) usage!
  if [[ "$(cat /sys/module/psmouse/parameters/proto)" != "ImPS/2" ]]; then
    sudo modprobe -r psmouse
    sudo modprobe psmouse proto=imps
    sudo sh -c 'echo "options psmouse proto=imps" > /etc/modprobe.d/psmouse.conf'
    sudo update-initramfs -u
    # Sync just in case I reboot soon after
    sync
  else
    echo
    echo "Already forcing imps protocol for psmouse module."
  fi

  #BUG: rendering issues with HD5500 (characters missing from xterms, missing window decorations 
  # fix under evaluation - use newer drivers from well-known oibaf PPA:
  if [[ ! -f /etc/apt/sources.list.d/oibaf-ubuntu-graphics-drivers-utopic.list ]]; then
    sudo apt-add-repository ppa:oibaf/graphics-drivers
    sudo apt-get update
    sudo apt-get dist-upgrade
  else
    echo
    echo "Already using newer intel drivers."
  fi

  #BUG: slow wifi with iwlwifi
  # fix under investigation: newer firmware.
  if [[ -n "$(uname -r | awk '$1~/3.1[0-6]/')" || ! -f /lib/firmware/iwlwifi-7265D-10.ucode ]]; then
    echo
    echo "Consider updating to a newer kernel and iwlwifi firmware for better performance:"
    echo "  git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
    echo "  sudo cp linux-firmware/iwlwifi-7265* /lib/firmware/"
    echo "then, update to a newer mainline, such as:"
    echo "  http://kernel.ubuntu.com/~kernel-ppa/mainline/v3.19-rc6-vivid/"
  else
    echo
    echo "Already using a >=3.17 kernel and newer iwlwifi-7265 firmware."
  fi
  echo
fi

if [[ $1 == "wmtweaks" ]]; then
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal '<Alt>t'
  gsettings set org.gnome.desktop.default-applications.terminal exec 'xterm'

  gsettings set com.canonical.desktop.interface scrollbar-mode 'normal'

  gsettings set com.canonical.unity-greeter play-ready-sound false
  gsettings set com.canonical.Unity.ApplicationsLens display-recent-apps false
  gsettings set com.canonical.Unity.ApplicationsLens display-available-apps false
  gsettings set com.canonical.Unity.Lenses home-lens-priority '["applications.scope"]'
  gsettings set com.canonical.Unity.Dash scopes '["applications.scope"]'
  gsettings set com.canonical.Unity.Dash favorite-scopes '["scope://applications"]'
  gsettings set com.canonical.Unity.Lenses home-lens-default-view '["applications.scope"]'
  gsettings set com.canonical.Unity.Lenses always-search '["applications.scope"]'
  gsettings set com.canonical.Unity.Lenses remote-content-search 'none'
  gsettings set com.canonical.Unity.Lenses disabled-scopes '["more_suggestions-amazon.scope", "help-askubuntu.scope", "commands.scope", "graphics-deviantart.scope", "reference-dictionary.scope", "info-ddg_related.scope", "more_suggestions-ebay.scope", "reference-europeana.scope", "info-foursquare.scope", "books-gallica.scope", "code-github.scope", "books-googlebooks.scope", "news-googlenews.scope", "music-grooveshark.scope", "reference-jstor.scope", "info-medicines.scope", "more_suggestions-u1ms.scope", "more_suggestions-populartracks.scope", "reference-pubmed.scope", "recipes-recipepuppy.scope", "info-reddit.scope", "reference-googlescholar.scope", "reference-sciencedirect.scope", "more_suggestions-skimlinks.scope", "info-songkick.scope", "music-songsterr.scope", "music-soundcloud.scope", "reference-stackexchange.scope", "reference-themoviedb.scope", "more_suggestions-ubuntushop.scope", "weather-weatherchannel.scope", "reference-wikipedia.scope", "news-yahoostock.scope"]'

  gsettings set org.gnome.settings-daemon.peripherals.mouse motion-threshold 4
  gsettings set org.gnome.settings-daemon.peripherals.mouse motion-acceleration 9.2
  gsettings set org.gnome.settings-daemon.peripherals.mouse middle-button-enabled true
  gsettings set org.gnome.settings-daemon.peripherals.touchpad motion-threshold 4
  gsettings set org.gnome.settings-daemon.peripherals.touchpad motion-acceleration 6.5

  gsettings set org.gnome.desktop.background picture-options 'none'
  gsettings set org.gnome.desktop.background picture-uri ''
  gsettings set org.gnome.desktop.background primary-color '#222222'
  gsettings set org.gnome.desktop.background secondary-color '#333333'
  gsettings set org.gnome.desktop.background color-shading-type 'solid'
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 4

  gsettings set org.gnome.desktop.media-handling autorun-never true

  gsettings set com.canonical.indicator.power show-percentage true
  gsettings set com.canonical.indicator.power show-time true
  gsettings set de.mh21.indicator-multiload.general color-scheme 'traditional'
  gsettings set de.mh21.indicator-multiload.general background-color 'ambiance:background'
  gsettings set de.mh21.indicator-multiload.graphs.disk enabled true
  gsettings set de.mh21.indicator-multiload.graphs.load enabled true
  gsettings set de.mh21.indicator-multiload.graphs.mem enabled true
  gsettings set de.mh21.indicator-multiload.graphs.net enabled true
  gsettings set de.mh21.indicator-multiload.traces.cpu1 color 'traditional:cpu1'
  gsettings set de.mh21.indicator-multiload.traces.cpu2 color 'traditional:cpu2'
  gsettings set de.mh21.indicator-multiload.traces.cpu3 color 'traditional:cpu3'
  gsettings set de.mh21.indicator-multiload.traces.cpu4 color 'traditional:cpu4'
  gsettings set de.mh21.indicator-multiload.traces.load1 color 'traditional:load1'
  gsettings set de.mh21.indicator-multiload.traces.swap1 color 'traditional:swap1'
  gsettings set de.mh21.indicator-multiload.traces.disk1 color 'traditional:disk1'
  gsettings set de.mh21.indicator-multiload.traces.disk2 color 'traditional:disk2'
  gsettings set de.mh21.indicator-multiload.traces.mem1 color 'traditional:mem1'
  gsettings set de.mh21.indicator-multiload.traces.mem2 color 'traditional:mem2'
  gsettings set de.mh21.indicator-multiload.traces.mem3 color 'traditional:mem3'
  gsettings set de.mh21.indicator-multiload.traces.mem4 color 'traditional:mem4'
  gsettings set de.mh21.indicator-multiload.traces.net1 color 'traditional:net1'
  gsettings set de.mh21.indicator-multiload.traces.net2 color 'traditional:net2'
  gsettings set de.mh21.indicator-multiload.traces.net3 color 'traditional:net3'

  gsettings set com.canonical.indicator.datetime show-date true
  gsettings set com.canonical.indicator.datetime show-seconds false
  gsettings set com.canonical.indicator.datetime show-day false
  gsettings set com.canonical.indicator.datetime show-year false
  gsettings set com.canonical.indicator.datetime time-format 'custom'
  gsettings set com.canonical.indicator.datetime custom-time-format '  %Y/%m/%d  |  %H:%M (%Z/%z) '
fi
