# Class: apthelper
# ===========================
#
# Helper for puppetlabs/apt module.
#
# Parameters
# ----------
#
# [*pins*]
#   (hash) Hash with configuration to setup apt::pins
#   Default: {}
#
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
#
# Examples
# --------
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
class apthelper (
  $pins = {},
) {

  validate_hash($pins)

  # Manage pins if present
  if $pins {
    $pin_defaults = {
      'packages' => 'mariadb-server',
      'ensure'   => present,
      'priority' => 1001,
      'version'  => '10.0',
    }
    $pins.each |$title, $pin_custom| {
      $pin_params = merge($pin_defaults, $pin_custom)
      apt::pin { $title:
        packages => $pin_params['packages'],
        priority => $pin_params['priority'],
        version  => "${pin_params['version']}*",
        ensure   => $pin_params['ensure'] ? {
          /(installed|present|held)/  => 'present',
          /(absent|purged|latest)/    => 'absent',
          default                     => 'present',
        },
      }
      #package { "pkg_${title}":
      #  ensure  => $pin['ensure'],
      #  require => Apt::Pin[$title],
      #}
    }
  }
}
