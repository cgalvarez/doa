#!/bin/sh
PUPPET_DIR='/etc/puppet'
PUPPET_CONF="${PUPPET_DIR}/puppet.conf"

# Set global module directories available to all environments
sed -e '\#\[[mM][aA][iI][nN]\]#a \basemodulepath=/etc/puppet/modules:/usr/share/puppet/modules:/vagrant/provision/puppet/modules' $PUPPET_CONF > /tmp/puppet.tmp
mv -f /tmp/puppet.tmp $PUPPET_CONF
