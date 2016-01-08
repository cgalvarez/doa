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
          MOD_MAYFLOWER_PHP => {
            :git => 'git://github.com/mayflower/puppet-php.git',
          },
        }

        # Puppet modules parameters.
        # mayflower/php => https://github.com/mayflower/puppet-php
        @supported = {
            'params' => {
              :children   => {
                'config_root' => {
                  :expect     => [:unix_abspath],
                  :maps_to    => 'php::params::cfg_root',
                  :mod_def    => {
                    'default' => '/etc/php5',
                    'redhat'  => nil,
                    'freebsd' => '/usr/local/etc',
                  },
                },
              },
            },
            'cli' => {
              :children   => {
                # Specify which version of PHP packages to install, defaults to 'latest'.
                # Please note that 'absent' to remove packages is not supported!
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :maps_to    => 'php::ensure',
                  :mod_def    => 'latest',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
                # The path to the ini php-cli ini file.
                'inifile' => {
                  :expect     => [:puppet_interpolable_uri],
                  :maps_to     => 'php::cli::inifile',
                  :mod_def    => {
                    'default' => '/etc/php5/cli/php.ini',
                    'redhat'  => '/etc/php-cli.ini',
                    'freebsd' => '/usr/local/etc/php-cli.ini',
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
                'service_name' => {
                  :expect     => [:string],
                  :maps_to    => 'php::fpm::service::service_name',
                  :mod_def    => {
                    'default' => 'php-fpm',
                    'debian'  => 'php5-fpm',
                  },
                },
                'inifile' => {
                  :expect     => [:puppet_interpolable_uri],
                  :maps_to    => 'php::fpm::inifile',
                  :mod_def    => {
                    'default' => '/etc/php5/fpm/php.ini',
                    'redhat'  => '/etc/php.ini',
                    'freebsd' => '/usr/local/etc/php.ini',
                  },
                },
                'config' => {
                  :children  => {
                    'config_file' => {
                      :expect     => [:unix_abspath],
                      :maps_to    => 'php::fpm::config::config_file',
                      :mod_def    => {
                        'default' => '/etc/php5/fpm/php-fpm.conf',
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
                        'default' => '/etc/php5/fpm/php.ini',
                        'redhat'  => '/etc/php.ini',
                        'freebsd' => '/usr/local/etc/php.ini',
                      },
                    },
                    'settings' => {
                      :expect     => [:hash],
                      :maps_to    => 'php::fpm::config::settings',
                      #:mod_def    => '{}',
                    },
                    'pool' => {
                      :children  => {
                        'base_dir' => {
                          :expect     => [:unix_abspath],
                          :maps_to    => 'php::fpm::config::pool_base_dir',
                          :mod_def    => {
                            'default' => '/etc/php5/fpm/pool.d',
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
                        'error_filepath' => {
                          :expect     => [:unix_abspath],
                          :maps_to    => 'php::fpm::config::error_log',
                          :mod_def    => {
                            'default' => '/var/log/php5-fpm.log',
                            'redhat'  => '/var/log/php-fpm/error.log',
                            'freebsd' => '/var/log/php-fpm.log',
                          },
                        },
                      },
                    },
                    'pid_filepath' => {
                      :expect     => [:unix_abspath],
                      :maps_to    => 'php::fpm::config::pid_file',
                      :mod_def    => {
                        'default' => '/var/run/php5-fpm.pid',
                        'redhat'  => '/var/run/php-fpm/php-fpm.pid',
                        'freebsd' => '/var/run/php-fpm.pid',
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
                'settings' => {
                  :maps_to    => 'php::fpm::settings',
                  :expect     => [:hash_values],
                  :doa_def    => {
                    'Date/date.timezone'            => 'Europe/Madrid',
                    'PHP/allow_url_fopen'           => 'Off',
                    'PHP/allow_url_include'         => 'Off',
                    'PHP/cgi.fix_pathinfo'          => 0,
                    # php_uname used by phpmyadmin
                    'PHP/disable_functions'         => 'getmyuid, getmypid, passthru, leak, listen, diskfreespace, tmpfile, link, ignore_user_abord, shell_exec, dl, set_time_limit, exec, system, highlight_file, source, show_source, fpaththru, virtual, posix_ctermid, posix_getcwd, posix_getegid, posix_geteuid, posix_getgid, posix_getgrgid, posix_getgrnam, posix_getgroups, posix_getlogin, posix_getpgid, posix_getpgrp, posix_getpid, posix, _getppid, posix_getpwnam, posix_getpwuid, posix_getrlimit, posix_getsid, posix_getuid, posix_isatty, posix_kill, posix_mkfifo, posix_setegid, posix_seteuid, posix_setgid, posix_setpgid, posix_setsid, posix_setuid, posix_times, posix_ttyname, posix_uname, proc_open, proc_close, proc_get_status, proc_nice, proc_terminate',
                    'PHP/enable_dl'                 => 'Off',
                    'PHP/expose_php'                => 'Off',
                    'PHP/session.save_path'         => '/var/lib/php/sessions',
                    'PHP/session.cookie_httponly'   => 1,
                    'PHP/display_errors'            => 'On',
                    'PHP/display_startup_errors'    => 'On',
                    'PHP/track_errors'              => 'On',
                    'PHP/html_errors'               => 'On',
                  },
                },
              },
            },
            'phpunit' => {
              :maps_to    => 'php::phpunit',
              #:cb_process => "#{ self.to_s }#set_hiera_param@phpunit",
              :mod_def    => 'false',
              :children   => {
                'ensure'  => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :maps_to    => 'php::phpunit::ensure',
                  :mod_def    => 'present',
                },
              },
            },
            'config_root_ini' => {
              :maps_to    => 'php::config_root_ini',
              :expect     => [:unix_abspath],
              :mod_def    => {
                'debian'  => '/etc/php5/mods-available',
                'suse'    => '/etc/php5/conf.d',
                'redhat'  => '/etc/php.d',
                'freebsd' => '/usr/local/etc/php',
              },
            },
            'ext_tool_enable' => {
              :maps_to    => 'php::ext_tool_enable',
              :expect     => [:unix_abspath],
              :mod_def    => {
                'default' => nil,
                'debian'  => '/usr/sbin/php5enmod',
              },
            },
            'ext_tool_query' => {
              :maps_to    => 'php::ext_tool_query',
              :expect     => [:unix_abspath],
              :mod_def    => {
                'default' => nil,
                'debian'  => '/usr/sbin/php5query',
              },
            },
            'extensions' => {
              :maps_to    => 'php::extensions',
              :children_hash => {
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
                'header_packages' => {
                  :expect     => [:array],
                },
                'pecl_source' => {
                  :expect     => [:string],
                },
                'prefix' => {
                  :children => {
                    'package' => {
                      :maps_to    => 'package_prefix',
                      :expect     => [:string],
                      :mod_def    => {
                        'debian'  => 'php5-',
                        'suse'    => 'php5-',
                        'redhat'  => 'php-',
                        'freebsd' => 'php56-',
                      },
                    },
                    'settings' => {
                      :maps_to    => 'settings_prefix',
                      :expect     => [:boolean],
                      :mod_def    => 'false',
                    },
                  },
                },
                'provider' => {
                  :expect     => [:string],
                  :allow      => ['pecl', 'aix', 'appdmg', 'apt', 'aptitude',
                    'aptrpm', 'blastwave', 'dpkg', 'fink', 'freebsd', 'gem',
                    'hpux', 'macports', 'nim', 'none', 'openbsd', 'opkg',
                    'pacman', 'pip', 'pip3', 'pkg', 'pkgdmg', 'pkgin', 'pkgng',
                    'pkgutil', 'portage', 'ports', 'portupgrade', 'puppet_gem',
                    'rpm', 'rug', 'sun', 'sunfreeware', 'up2date', 'urpmi',
                    'windows', 'yum', 'zypper'
                  ],
                },
                'settings' => {
                  :expect     => [:hash_values],
                },
                'source' => {
                  :expect     => [:string],
                },
                'zend' => {
                  :expect     => [:boolean],
                  :mod_def    => 'false',
                },
              },
            },
            # This is the prefix for constructing names of php packages. This
            # defaults to a sensible default depending on your operating system,
            # like 'php-' or 'php5-'.
            'package_prefix' => {
              :maps_to    => 'php::package_prefix',
              :expect     => [:string],
              :mod_def    => {
                'default' => 'php5-',
                'freebsd' => 'php56-',
                'redhat'  => 'php-',
              },
            },
            'repo' => {
              :children => {
                'ppa' => {
                  :maps_to    => 'php::repo::ubuntu::ppa',
                  :expect     => :string,
                  :mod_def    => 'ondrej/php5',
                  :doa_def    => 'ondrej/php5-5.6',
                  :cb_process => "#{ self.to_s }#check_manage",
                },
                # Include repository (dotdeb, ppa, etc.) to install recent PHP from.
                'manage' => {
                  :maps_to    => 'php::manage_repos',
                  :expect     => :boolean,
                  #:mod_def    => {
                  #  'default' => 'false',
                  #  'debian'  => 'true',
                  #  'suse'    => 'true',
                  #},
                },
              },
            },
            'settings' => {
              :maps_to    => 'php::settings',
              :expect     => [:hash_values],
              :doa_def    => {
                :dev => {
                  'Date/date.timezone'            => 'Europe/Madrid',
                  'PHP/allow_url_fopen'           => 'On',
                  'PHP/allow_url_include'         => 'Off',
                  'PHP/cgi.fix_pathinfo'          => 0,
                  'PHP/disable_functions'         => 'getmyuid, getmypid, passthru, leak, listen, diskfreespace, tmpfile, link, ignore_user_abord, dl, set_time_limit, system, highlight_file, source, show_source, fpaththru, virtual, posix_ctermid, posix_getcwd, posix_getegid, posix_geteuid, posix_getgid, posix_getgrgid, posix_getgrnam, posix_getgroups, posix_getlogin, posix_getpgid, posix_getpgrp, posix_getpid, posix, _getppid, posix_getpwnam, posix_getpwuid, posix_getrlimit, posix_getsid, posix_getuid, posix_isatty, posix_kill, posix_mkfifo, posix_setegid, posix_seteuid, posix_setgid, posix_setpgid, posix_setsid, posix_setuid, posix_times, posix_ttyname, posix_uname',
                  'PHP/enable_dl'                 => 'Off',
                  'PHP/expose_php'                => 'Off',
                  'PHP/session.save_path'         => '/var/lib/php',
                  'PHP/session.cookie_httponly'   => 1,
                  'PHP/display_errors'            => 'On',
                  'PHP/display_startup_errors'    => 'On',
                  'PHP/track_errors'              => 'On',
                  'PHP/html_errors'               => 'On',
                },
                :prod => {
                  'Date/date.timezone'            => 'Europe/Madrid',
                  'PHP/allow_url_fopen'           => 'Off',
                  'PHP/allow_url_include'         => 'Off',
                  'PHP/cgi.fix_pathinfo'          => 0,
                  'PHP/disable_functions'         => 'php_uname, getmyuid, getmypid, passthru, leak, listen, diskfreespace, tmpfile, link, ignore_user_abord, shell_exec, dl, set_time_limit, exec, system, highlight_file, source, show_source, fpaththru, virtual, posix_ctermid, posix_getcwd, posix_getegid, posix_geteuid, posix_getgid, posix_getgrgid, posix_getgrnam, posix_getgroups, posix_getlogin, posix_getpgid, posix_getpgrp, posix_getpid, posix, _getppid, posix_getpwnam, posix_getpwuid, posix_getrlimit, posix_getsid, posix_getuid, posix_isatty, posix_kill, posix_mkfifo, posix_setegid, posix_seteuid, posix_setgid, posix_setpgid, posix_setsid, posix_setuid, posix_times, posix_ttyname, posix_uname, proc_open, proc_close, proc_get_status, proc_nice, proc_terminate',
                  'PHP/enable_dl'                 => 'Off',
                  'PHP/expose_php'                => 'Off',
                  'PHP/session.save_path'         => '/var/lib/php',
                  'PHP/session.cookie_httponly'   => 1,
                  'PHP/display_errors'            => 'On',
                  'PHP/display_startup_errors'    => 'On',
                  'PHP/track_errors'              => 'On',
                  'PHP/html_errors'               => 'On',
                },
              }
            },
          }
        # Unofficial versions and distros supported by Ondřej Surý (Ubuntu):
        #   Lucid    (10.04)       5.4.x
        #   Precise  (12.04) LTS   5.4.x   5.5.x   5.6.x           apache2
        #   Quantal  (12.10)       5.4.x
        #   Saucy    (13.10)               5.5.x
        #   Trusty   (14.04) LTS           5.5.x   5.6.x   7.0.x   apache2
        #   Utopic   (14.10)                       5.6.x           apache2
        #   Vidid    (15.04)                       5.6.x   7.0.x   apache2
        #   Wily     (15.04)                       5.6.x   7.0.x   apache2
        REPO_ONDREJ = {
            '5.4' => "'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu/'",
            '5.5' => "'http://ppa.launchpad.net/ondrej/php5/ubuntu/'",
            '5.6' => "'http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu/'",
            '7.0' => "'http://ppa.launchpad.net/ondrej/php-7.0/ubuntu/'",
          }

        def self.check_manage(value)
          @provided.recursive_set!(['repo', 'manage'], 'true') if !value.empty?
          DOA::Provisioner::Puppet.enqueue_site_content("if defined(Class['::php::repo::ubuntu']) {
  Class['::php::repo::ubuntu'] ~> Exec['apt_update'] -> Class['::php::packages']
}
")
          value
        end

        def self.set_hiera_param(value, yaml_param, set = true)
          # Check if `ensure` provided, and set it depending on environment type
          # Children settings are processed before parent, so `ensure` is already set if present
          if !DOA::Provisioner::Puppet.sw_stack.has_key?(@label) or !DOA::Provisioner::Puppet.sw_stack[@label].has_key?(@supported[yaml_param][:children]['ensure'][:maps_to])
            maps_to = @supported[yaml_param][:children]['ensure'].has_key?(:maps_to) ? @supported[yaml_param][:children]['ensure'][:maps_to] : yaml_param
            DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
              maps_to => "'#{ @supported[yaml_param][:children]['ensure'][:doa_def][DOA::Guest.env] }'"
            })
          end

          doa_def = get_default_value(@supported[yaml_param], :doa_def)
          mod_def = get_default_value(@supported[yaml_param], :mod_def)
          return doa_def ? doa_def : mod_def
        end
      end
    end
  end
end
