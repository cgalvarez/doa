#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class PHP < PuppetModule
        # Constants.
        MOD_MAYFLOWER_PHP = 'mayflower/php'

        # Class variables.
        @label        = 'PHP'
        @hieraclasses = ['php']
        @librarian    = {
          MOD_MAYFLOWER_PHP => {},
        }

        # Puppet modules parameters.
        # mayflower/php => https://github.com/mayflower/puppet-php
        @supported = {
            'core' => {
              :children   => {
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :maps_to     => 'php::ensure',
                  :mod_def    => 'latest',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
              },
            },
            'fpm' => {
              :maps_to    => 'php::fpm',
              :cb_process => "#{ self.to_s }#set_hiera_param@fpm",
              :mod_def    => 'true',
              :children   => {
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :maps_to    => 'php::fpm::ensure',
                  :mod_def    => 'latest',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
                'config' => {
                  :children  => {
                    'config_file' => {
                      :expect     => [:unix_abspath],
                      :maps_to    => 'php::fpm::config::config_file',
                      :mod_def    => {
                        'debian'  => '/etc/php5/fpm/php-fpm.conf',
                        'suse'    => '/etc/php5/fpm/php-fpm.conf',
                        'redhat'  => '/etc/php-fpm.conf',
                        'freebsd' => '/usr/local/etc/php-fpm.conf',
                      },
                    },
                    'user' => {
                      :expect     => [:string],
                      :maps_to    => 'php::fpm::config::user',
                      :mod_def    => {
                        'debian'  => 'www-data',
                        'suse'    => 'wwwrun',
                        'redhat'  => 'apache',
                        'freebsd' => 'www',
                      },
                    },
                    'group' => {
                      :expect     => [:string],
                      :maps_to    => 'php::fpm::config::group',
                      :mod_def    => {
                        'debian'  => 'www-data',
                        'suse'    => 'www',
                        'redhat'  => 'apache',
                        'freebsd' => 'www',
                      },
                    },
                    'root_group' => {
                      :expect     => [:string],
                      :maps_to    => 'php::fpm::config::root_group',
                      :mod_def    => {
                        'debian'  => 'root',
                        'suse'    => 'root',
                        'redhat'  => 'root',
                        'freebsd' => 'wheel',
                      },
                    },
                    'inifile' => {
                      :expect     => [:string],
                      :maps_to    => 'php::fpm::config::inifile',
                      :mod_def    => {
                        'debian'  => '/etc/php5/fpm/php.ini',
                        'suse'    => '/etc/php5/fpm/php.ini',
                        'redhat'  => '/etc/php.ini',
                        'freebsd' => '/usr/local/etc/php.ini',
                      },
                    },
                    'settings' => {
                      :expect     => [:hash],
                      :maps_to    => 'php::fpm::config::settings',
                      :mod_def    => '{}',
                    },
                    'pool' => {
                      :children  => {
                        'base_dir' => {
                          :expect     => [:unix_abspath],
                          :maps_to    => 'php::fpm::config::pool_base_dir',
                          :mod_def    => {
                            'debian'  => '/etc/php5/fpm/pool.d',
                            'suse'    => '/etc/php5/fpm/pool.d',
                            'redhat'  => '/etc/php-fpm.d',
                            'freebsd' => '/usr/local/etc/php-fpm.d',
                          },
                        },
                        'purge' => {
                          :expect     => [:boolean],
                          :maps_to    => 'php::fpm::config::pool_purge',
                          :mod_def    => 'false',
                        },
                      },
                    },
                    'emergency' => {
                      :children  => {
                        'restart_threshold' => {
                          :expect     => [:integer],
                          :maps_to    => 'php::fpm::config::emergency_restart_threshold',
                          :mod_def    => '0',
                        },
                        'restart_interval' => {
                          :expect     => [:string], # TODO: Improve (http://php.net/manual/en/install.fpm.configuration.php#emergency-restart-interval)
                          :maps_to    => 'php::fpm::config::emergency_restart_interval',
                          :mod_def    => '0',
                        },
                      },
                    },
                    'log' => {
                      :children  => {
                        'level' => {
                          :expect     => [:string],
                          :allow      => ['alert', 'error', 'warning', 'notice', 'debug'],
                          :maps_to    => 'php::fpm::config::log_level',
                          :mod_def    => 'notice',
                        },
                        'owner' => {
                          :expect     => [:string],
                          :maps_to    => 'php::fpm::config::log_owner',
                          :mod_def    => {
                            'debian'  => 'www-data',
                            'suse'    => 'wwwrun',
                            'redhat'  => 'apache',
                            'freebsd' => 'www',
                          },
                        },
                        'group' => {
                          :expect     => [:string],
                          :maps_to    => 'php::fpm::config::log_group',
                          :mod_def    => {
                            'debian'  => 'www-data',
                            'suse'    => 'www',
                            'redhat'  => 'apache',
                            'freebsd' => 'www',
                          },
                        },
                        'dir_mode' => {
                          :expect     => [:chmod],
                          :maps_to    => 'php::fpm::config::log_dir_mode',
                          :mod_def    => '0770',
                        },
                      },
                    },
                  },
                },
                'pools' => {
                  :maps_to    => 'php::fpm::pools',
                  :children_hash  => {
                    'ensure' => {
                      :expect     => [:string],
                      :allow      => ['absent', 'present'],
                      :mod_def    => 'present',
                    },
                    'user' => {
                      :expect     => [:string],
                      :mod_def    => {
                        'debian'  => 'www-data',
                        'suse'    => 'wwwrun',
                        'redhat'  => 'apache',
                        'freebsd' => 'www',
                      },
                    },
                    'listen' => {
                      :children => {
                        'socket' => {
                          :expect     => [:ipv4_port, :unix_abspath],
                          :maps_to    => 'listen',
                          :mod_def    => '127.0.0.1:9000',
                          :doa_def    => {
                            'debian'  => '/var/run/php5-fpm.sock',
                          },
                        },
                        'backlog' => {
                          :expect     => [:string],
                          :maps_to    => 'listen_backlog',
                          :mod_def    => '-1',
                        },
                        'allowed_clients' => {
                          :expect     => [:ipv4],
                          :maps_to    => 'listen_allowed_clients',
                          :mod_def    => '-1',
                        },
                        'owner' => {
                          :expect     => [:string],
                          :maps_to    => 'listen_owner',
                        },
                        'group' => {
                          :expect     => [:string],
                          :maps_to    => 'listen_group',
                        },
                        'mode' => {
                          :expect     => [:chmod],
                          :maps_to    => 'listen_mode',
                          :mod_def    => '0660',
                        },
                      },
                    },
                    'pm' => { # PM (Process Manager) control
                      :children => {
                        'mode' => {
                          :expect     => [:string],
                          :allow      => ['static', 'ondemand', 'dynamic'],
                          :maps_to    => 'pm',
                          :mod_def    => 'dynamic',
                        },
                        'max_children' => {
                          :expect     => [:string],
                          :maps_to    => 'pm_max_children',
                          :mod_def    => '50',
                        },
                        'start_servers' => {
                          :expect     => [:string],
                          :maps_to    => 'pm_start_servers',
                          :mod_def    => '5',
                        },
                        'min_spare_servers' => {
                          :expect     => [:string],
                          :maps_to    => 'pm_min_spare_servers',
                          :mod_def    => '5',
                        },
                        'max_spare_servers' => {
                          :expect     => [:string],
                          :maps_to    => 'pm_max_spare_servers',
                          :mod_def    => '35',
                        },
                        'max_requests' => {
                          :expect     => [:string],
                          :maps_to    => 'pm_max_requests',
                          :mod_def    => '0',
                        },
                        'status_path' => {
                          :expect     => [:uri],
                          :maps_to    => 'pm_status_path',
                        },
                      },
                    },
                    'ping' => {
                      :children => {
                        'path' => {
                          :expect     => [:unix_abspath],
                          :maps_to    => 'ping_response',
                        },
                        'response' => {
                          :expect     => [:string],
                          :maps_to    => 'ping_response',
                          :mod_def    => 'pong',
                        },
                      },
                    },
                    'request' => {
                      :children => {
                        'terminate_timeout' => {
                          :expect     => [:string],
                          :maps_to    => 'request_terminate_timeout',
                          :mod_def    => '0',
                        },
                        'slowlog_timeout' => {
                          :expect     => [:string],
                          :maps_to    => 'request_slowlog_timeout',
                          :mod_def    => '0',
                        },
                      },
                    },
                    'rlimit' => {
                      :children => {
                        'files' => {
                          :expect     => [:string],
                          :maps_to    => 'rlimit_files',
                        },
                        'core' => {
                          :expect     => [:string],
                          :maps_to    => 'rlimit_core',
                        },
                      },
                    },
                    # See http://php.net/manual/en/install.fpm.configuration.php#example-73
                    'php' => {
                      :children => {
                        'value' => {
                          :expect     => [:hash_values],
                          :maps_to    => 'php_value',
                        },
                        'flag' => {
                          :expect     => [:hash_flags],
                          :maps_to    => 'php_flag',
                        },
                        'directives' => {
                          :expect     => [:string],
                          :maps_to    => 'php_directives',
                          :mod_def    => [],
                        },
                        'admin' => {
                          :children => {
                            'value' => {
                              :expect     => [:hash_values],
                              :maps_to    => 'php_admin_value',
                            },
                            'flag' => {
                              :expect     => [:hash_flags],
                              :maps_to    => 'php_admin_flag',
                            },
                          },
                        },
                      },
                    },
                    'chroot' => {
                      :expect     => [:unix_abspath],
                    },
                    'chdir' => {
                      :expect     => [:unix_abspath],
                    },
                    'catch_workers_output' => {
                      :expect     => [:string],
                      :mod_def    => 'no',
                    },
                    #user, group, slowlog, root_group
                  },
                },
              },
            },
            'phpunit' => {
              :maps_to    => 'php::phpunit',
              :cb_process => "#{ self.to_s }#set_hiera_param@phpunit",
              :mod_def    => 'false',
              :doa_def    => {
                :dev      => 'true',
                :test     => 'true',
                :prod     => 'false',
              },
              :children  => {
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :maps_to    => 'php::phpunit::ensure',
                  :mod_def    => 'latest',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'absent',
                  },
                },
              },
            },
            'extensions' => {
              :maps_to    => 'php::extensions',
              :children_hash => {
                # package_prefix, compiler_packages
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :mod_def    => 'installed',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
                'provider' => {
                  :expect     => [:string],
                  :allow      => ['pecl', 'aix', 'appdmg', 'apt', 'aptitude', 'aptrpm', 'blastwave', 'dpkg', 'fink', 'freebsd', 'gem', 'hpux', 'macports', 'nim', 'none', 'openbsd', 'opkg', 'pacman', 'pip', 'pip3', 'pkg', 'pkgdmg', 'pkgin', 'pkgng', 'pkgutil', 'portage', 'ports', 'portupgrade', 'puppet_gem', 'rpm', 'rug', 'sun', 'sunfreeware', 'up2date', 'urpmi', 'windows', 'yum', 'zypper'],
                },
                'source' => {
                  :expect     => [:string],
                },
                'pecl_source' => {
                  :expect     => [:string],
                },
                'header_packages' => {
                  :expect     => [:array],
                },
                'zend' => {
                  :expect     => [:boolean],
                  :mod_def    => 'false',
                },
                'settings' => {
                  :expect     => [:hash_values],
                },
                'settings_prefix' => {
                  :expect     => [:boolean],
                  :mod_def    => 'false',
                },
                'compiler_packages' => {
                  :expect     => [:array],
                  :mod_def    => {
                    'debian'  => ['build-essential'],
                    'suse'    => {
                      'OpenSuSE' => ['devel_basis'],
                    },
                    'redhat'  => ['gcc', 'gcc-c++', 'make'],
                    'freebsd' => ['gcc'],
                  },
                },
                'package_prefix' => {
                  :expect     => [:string],
                  :mod_def    => {
                    'debian'  => 'php5-',
                    'suse'    => 'php5-',
                    'redhat'  => 'php-',
                    'freebsd' => 'php56-',
                  },
                },
              },
            },
            'settings' => {
              :maps_to    => 'php::settings',
              :expect     => [:hash_values],
            },
          }
        REPO_ONDREJ = {
            '5.4' => "'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu/'",
            '5.5' => "'http://ppa.launchpad.net/ondrej/php5/ubuntu/'",
            '5.6' => "'http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu/'",
            '7.0' => "'http://ppa.launchpad.net/ondrej/php-7.0/ubuntu/'",
          }

        def self.custom_setup()
          DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
            'php::manage_repos' => 'false',
          })
        end
        def self.set_hiera_param(value, yaml_param, set = true)
          # Check if `ensure` provided, and set it depending on environment type
          # Children settings are processed before parent, so `ensure` is already set if present
          if !Puppet.sw_stack.has_key?(@label) or !Puppet.sw_stack[@label].has_key?(@supported[yaml_param][:children]['ensure'][:maps_to])
            maps_to = @supported[yaml_param][:children]['ensure'].has_key?(:maps_to) ? @supported[yaml_param][:children]['ensure'][:maps_to] : yaml_param
            DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
              #@supported[yaml_param][:children]['ensure'][:maps_to] => "'#{ @supported[yaml_param][:children]['ensure'][:doa_def][DOA::Guest.env] }"
              maps_to => "'#{ @supported[yaml_param][:children]['ensure'][:doa_def][DOA::Guest.env] }'"
            })
          end

          doa_def = get_default_value(@supported[yaml_param], :doa_def)
          mod_def = get_default_value(@supported[yaml_param], :mod_def)
          return doa_def ? doa_def : mod_def
        end
          # Add repos from Ondřej Surý for PHP 5.4.x, 5.5.x, 5.6.x
          #case Puppet.os_info(OS_FAMILY)
          #when DOA::OS::LINUX_FAMILY_DEBIAN
          #  wanted_repos =
          #    case Puppet.os_info(OS_DISTRO)
          #    when DOA::OS::LINUX_UBUNTU then
          #      # Unofficial versions and distros supported by Ondřej Surý (Ubuntu):
          #      #   Lucid    (10.04)       5.4.x
          #      #   Precise  (12.04) LTS   5.4.x   5.5.x   5.6.x           apache2
          #      #   Quantal  (12.10)       5.4.x
          #      #   Saucy    (13.10)               5.5.x
          #      #   Trusty   (14.04) LTS           5.5.x   5.6.x   7.0.x   apache2
          #      #   Utopic   (14.10)                       5.6.x           apache2
          #      #   Vidid    (15.04)                       5.6.x   7.0.x   apache2
          #      #   Wily     (15.04)                       5.6.x   7.0.x   apache2
          #      case Puppet.os_info(OS_DISTRO_VER)
          #      when DOA::OS::UBUNTU_LUCID, DOA::OS::UBUNTU_QUANTAL then ['5.4']
          #      when DOA::OS::UBUNTU_SAUCY then ['5.5']
          #      when DOA::OS::UBUNTU_UTOPIC then ['5.6']
          #      when DOA::OS::UBUNTU_PRECISE then ['5.4', '5.5', '5.6']
          #      when DOA::OS::UBUNTU_TRUSTY then ['5.5', '5.6']
          #      else []
          #      end
          #    else []
          #    end
          #
          #  guest_repos = {
          #      '5.4' => "'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu/'",
          #      '5.5' => "'http://ppa.launchpad.net/ondrej/php5/ubuntu/'",
          #      '5.6' => "'http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu/'",
          #      #'7.0' => "'http://ppa.launchpad.net/ondrej/php-7.0/ubuntu/'",
          #    }#.select { |key,_| wanted_repos.include? key }
          #
          #  REPO_ONDREJ.each do |php_ver, location|
          #    escaped_php_ver = php_ver.gsub('.', '_')
          #    Puppet.enqueue_apt_repo("php_ondrej_#{ escaped_php_ver }", {
          #      'ensure'   => wanted_repos.include?(php_ver) ? "'present'" : "'absent'",
          #      'comment'  => "'PPA for latest PHP #{ php_ver }.x packages by Ondřej Surý'",
          #      'location' => location,
          #      'key'      => {'id' => "'14AA40EC0831756756D7F66C4F4EA0AAE5267A6C'"},
          #    }, {'before' => "Class['php']"})
          #  end
          #  
          #  # Add ppa:ondrej/apache2 to resolve unmet dependencies
          #  Puppet.enqueue_apt_repo('apache2_ondrej', {
          #    'ensure'   => wanted_repos.include?(php_ver) ? "'present'" : "'absent'",
          #    'comment'  => "'PPA for latest Apache 2 packages by Ondřej Surý'",
          #    'location' => "'http://ppa.launchpad.net/ondrej/apache2/ubuntu/'",
          #    'key'      => {'id' => "'14AA40EC0831756756D7F66C4F4EA0AAE5267A6C'"},
          #  }, {'before' => "Class['php']"})
          #end
      end
    end
  end
end
