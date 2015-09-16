# Class: meteor
# ===========================
#
# Installs Meteor.
#
# Parameters
# ----------
#
# Variables
# ----------
#
# Examples
# --------
#
# @example
#    class { 'meteor':
#      servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#    }
#
# Authors
# -------
#
# Carlos Alberto García Álvarez <contact@carlosgarcia.engineer>
#
# Copyright
# ---------
#
# Copyright 2015 Carlos Alberto García Álvarez, unless otherwise noted.
#
class meteor {
  exec { 'install_meteor':
    command     => '/usr/bin/curl https://install.meteor.com/ | /bin/sh',
    environment => 'HOME=/home/vagrant',
    user        => 'vagrant',
    group       => 'vagrant',
    unless      => '/usr/bin/which meteor',
  }
}
