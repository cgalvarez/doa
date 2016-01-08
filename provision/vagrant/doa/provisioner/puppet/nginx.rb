#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class Nginx < PuppetModule
        # Constants.
        MOD_JFRYMAN_NGINX = 'jfryman/nginx'
        DEF_WWW_ROOT = '/var/www/public'
        STATIC_EXTS = [
          'atom',
          'bmp',
          'bz2',
          'css',
          'doc',
          'eot',
          'exe',
          'gif',
          'gz',
          'htm',
          'html',
          'ico',
          'jpeg',
          'jpg',
          'js',
          'mid',
          'midi',
          'mp4',
          'ogg',
          'ogv',
          'otf',
          'png',
          'ppt',
          'rar',
          'rss',
          'rtf',
          'svg',
          'svgz',
          'tar',
          'tgz',
          'ttf',
          'wav',
          'woff',
          'xls',
          'zip',
        ]

        # Class variables.
        @label        = DOA::Setting::SW_NGINX_LABEL
        @hieraclasses = ['nginx']
        @librarian    = {
          MOD_JFRYMAN_NGINX => {},
        }

        # Puppet modules parameters.
        # jfryman/nginx => https://github.com/jfryman/puppet-nginx
        @supported = {
            'confd_purge' => {
              :expect  => [:boolean],
              :maps_to => 'nginx::confd_purge',
              :mod_def => 'false',
            },
            'daemon_user' => {
              :expect  => [:puppet_interpolable_string],
              :maps_to => 'nginx::daemon_user',
              :mod_def => {
                'default'   => 'nginx',
                'archlinux' => 'http',
                'debian'    => 'www-data',
                'freebsd'   => 'www',
                'openbsd'   => 'www',
                'smartos'   => 'www',
                'solaris'   => 'webservd',
              },
            },
            'events_use' => {
              :expect  => [:puppet_interpolable_string],
              :maps_to => 'nginx::events_use',
              :mod_def => 'false',
            },
            'gzip' => {
              :expect  => [:flag],
              :maps_to => 'nginx::gzip',
              :mod_def => 'on',
            },
            'keepalive_timeout' => {
              :expect  => [:integer],
              :maps_to => 'nginx::keepalive_timeout',
              :mod_def => '65',
            },
            'mail' => {
              :expect  => [:boolean],
              :maps_to => 'nginx::mail',
              :mod_def => 'false',
            },
            'manage_repo' => {
              :maps_to => 'nginx::manage_repo',
              :mod_def => {
                'default' => 'false',
                'debian'  => {
                  'debian' => 'true',
                  'ubuntu' => {
                    'lucid'   => 'true',
                    'precise' => 'true',
                    'trusty'  => 'true',
                  },
                },
                'redhat'  => {
                  'centos' => 'true',
                  'redhat' => 'true',
                },
              },
            },
            'multi_accept' => {
              :expect  => [:flag],
              :maps_to => 'nginx::multi_accept',
              :mod_def => 'off',
            },
            'pid' => {
              :expect  => [:unix_abspath, :boolean],
              :maps_to => 'nginx::pid',
              :mod_def => {
                'default'   => '/var/run/nginx.pid',
                'archlinux' => 'false',
              }
            },
            'root_group' => {
              :expect  => [:puppet_interpolable_string],
              :maps_to => 'nginx::root_group',
              :mod_def => {
                'default' => 'root',
                'freebsd' => 'wheel',
                'openbsd' => 'wheel',
              },
            },
            'sendfile' => {
              :expect  => [:flag],
              :maps_to => 'nginx::sendfile',
              :mod_def => 'on',
            },
            'server_tokens' => {
              :expect  => [:flag],
              :maps_to => 'nginx::server_tokens',
              :mod_def => 'on',
            },
            'spdy' => {
              :expect  => [:flag],
              :maps_to => 'nginx::spdy',
              :mod_def => 'off',
            },
            'super_user' => {
              :expect  => [:boolean],
              :maps_to => 'nginx::super_user',
              :mod_def => 'true',
            },
            'vhost_purge' => {
              :expect  => [:boolean],
              :maps_to => 'nginx::vhost_purge',
              :mod_def => 'false',
            },
            'client' => {
              :children => {
                'body' => {
                  :children => {
                    'buffer_size' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::client_body_buffer_size',
                      :mod_def => '128k',
                    },
                    'temp_path' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'nginx::client_body_temp_path',
                      :mod_def => {
                        'default' => '/var/nginx/client_body_temp',
                        'openbsd' => '/var/www/client_body_temp',
                      },
                    },
                    'max_size' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::client_max_body_size',
                      :mod_def => '10m',
                    },
                  },
                },
              },
            },
            'dir' => {
              :children => {
                'conf' => {
                  :expect  => [:unix_abspath],
                  :maps_to => 'nginx::conf_dir',
                  :mod_def => {
                    'default' => '/etc/nginx',
                    'freebsd' => '/usr/local/etc/nginx',
                    'smartos' => '/usr/local/etc/nginx',
                  },
                },
                'log' => {
                  :expect  => [:unix_abspath],
                  :maps_to => 'nginx::logdir',
                  :mod_def => {
                    'default' => '/var/log/nginx',
                    'openbsd' => '/var/www/logs',
                  },
                },
                'run' => {
                  :expect  => [:unix_abspath],
                  :maps_to => 'nginx::run_dir',
                  :mod_def => {
                    'default' => '/var/nginx',
                    'openbsd' => '/var/www',
                  },
                },
                'temp' => {
                  :expect  => [:unix_abspath],
                  :maps_to => 'nginx::temp_dir',
                  :mod_def => '/tmp',
                },
              },
            },
            'fastcgi' => {
              :children => {
                'cache' => {
                  :children => {
                    'inactive' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::fastcgi_cache_inactive',
                      :mod_def => '20m',
                    },
                    'key' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::fastcgi_cache_key',
                      :mod_def => 'false',
                    },
                    'keys_zone' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::fastcgi_cache_keys_zone',
                      :mod_def => 'd3:100m',
                    },
                    'levels' => {
                      :expect  => [:level],
                      :maps_to => 'nginx::fastcgi_cache_levels',
                      :mod_def => '1',
                    },
                    'max_size' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::fastcgi_cache_max_size',
                      :mod_def => '500m',
                    },
                    'path' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'nginx::fastcgi_cache_path',
                      :mod_def => 'false',
                    },
                    'use_stale' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::fastcgi_cache_use_stale',
                      :mod_def => 'false',
                    },
                  },
                },
              },
            },
            'global' => {
              :children => {
                'owner' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::global_owner',
                  :mod_def => 'root',
                },
                'group' => {
                  :expect  => [:chmod],
                  :maps_to => 'nginx::global_group',
                  :mod_def => {
                    'default' => 'root',
                    'freebsd' => 'wheel',
                    'openbsd' => 'wheel',
                  },
                },
                'mode' => {
                  :expect  => [:chmod],
                  :maps_to => 'nginx::global_mode',
                  :mod_def => '0644',
                },
              },
            },
            'http' => {
              :children => {
                'cfg_append' => {
                  :expect  => [:array, :hash_values],
                  :maps_to => 'nginx::http_cfg_append',
                  :mod_def => 'false',
                },
                'tcp' => {
                  :children => {
                    'nodelay' => {
                      :expect  => [:flag],
                      :maps_to => 'nginx::http_tcp_nodelay',
                      :mod_def => 'on',
                    },
                    'nopush' => {
                      :expect  => [:flag],
                      :maps_to => 'nginx::http_tcp_nopush',
                      :mod_def => 'off',
                    },
                  },
                },
              },
            },
            'log' => {
              :children => {
                'access' => {
                  :expect  => [:unix_abspath],
                  :maps_to => 'nginx::http_access_log',
                  :mod_def => {
                    'default' => '/var/log/nginx/access.log',
                    'openbsd' => '/var/www/logs/access.log',
                  },
                },
                'error' => {
                  :expect  => [:unix_abspath],
                  :maps_to => 'nginx::nginx_error_log',
                  :mod_def => {
                    'default' => '/var/log/nginx/error.log',
                    'openbsd' => '/var/www/logs/error.log',
                  },
                },
                'format' => {
                  :expect  => [:hash_values],
                  :maps_to => 'nginx::log_format',
                },
              },
            },
            'names_hash' => {
              :children => {
                'bucket_size' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::names_hash_bucket_size',
                  :mod_def => '64',
                },
                'max_size' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::names_hash_max_size',
                  :mod_def => '512',
                },
              },
            },
            'package' => {
              :children => {
                'ensure' => {
                  :expect  => [:puppet_interpolable_string],
                  :allow   => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :maps_to => 'nginx::package_ensure',
                  :mod_def => 'present',
                  :doa_def => {
                    :dev   => 'latest',
                    :test  => 'latest',
                    :prod  => 'present',
                  },
                },
                'name' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::package_name',
                  :mod_def => {
                    'default' => 'nginx',
                    'gentoo'  => 'www-servers/nginx',
                    'solaris' => nil,
                  },
                },
                'source' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::package_source',
                  :mod_def => 'nginx',
                },
                'flavor' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::package_flavor',
                },
              },
            },
            'proxy' => {
              :children => {
                'buffers' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::proxy_buffers',
                  :mod_def => '32 4k',
                },
                'buffer_size' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::proxy_buffer_size',
                  :mod_def => '8k',
                },
                'cache' => {
                  :children => {
                    'inactive' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::proxy_cache_inactive',
                      :mod_def => '20m',
                    },
                    'keys_zone' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::proxy_cache_keys_zone',
                      :mod_def => 'd2:100m',
                    },
                    'levels' => {
                      :expect  => [:level],
                      :maps_to => 'nginx::proxy_cache_levels',
                      :mod_def => '1',
                    },
                    'max_size' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'nginx::proxy_cache_max_size',
                      :mod_def => '500m',
                    },
                    'path' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'nginx::proxy_cache_path',
                      :mod_def => 'false',
                    },
                  },
                },
                'connect_timeout' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::proxy_connect_timeout',
                  :mod_def => '90',
                },
                'headers_hash_bucket_size' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::proxy_headers_hash_bucket_size',
                  :mod_def => '64',
                },
                'http_version' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::proxy_http_version',
                },
                'read_timeout' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::proxy_read_timeout',
                  :mod_def => '90',
                },
                'redirect' => {
                  :expect  => [:flag],
                  :maps_to => 'nginx::proxy_redirect',
                  :mod_def => 'off',
                },
                'send_timeout' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::proxy_send_timeout',
                  :mod_def => '90',
                },
                'set_header' => {
                  :expect  => [:array],
                  :maps_to => 'nginx::proxy_set_header',
                  :mod_def => [
                    'Host $host',
                    'X-Real-IP $remote_addr',
                    'X-Forwarded-For $proxy_add_x_forwarded_for',
                  ],
                },
                'temp_path' => {
                  :maps_to => 'nginx::proxy_temp_path',
                },
              },
            },
            'service' => {
              :children => {
                'configtest_enable' => {
                  :expect  => [:boolean],
                  :maps_to => 'nginx::configtest_enable',
                  :mod_def => 'false',
                },
                'ensure' => {
                  :expect  => [:puppet_interpolable_string],
                  :allow   => ['running', 'stopped', 'absent'],
                  :maps_to => 'nginx::service_ensure',
                  :mod_def => 'running'
                },
                # Specify a string of flags to pass to the startup script
                'flags' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::service_flags',
                },
                'name' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::service_name',
                  :mod_def => 'nginx',
                },
                'restart' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::service_restart',
                  :mod_def => '/etc/init.d/nginx configtest && /etc/init.d/nginx restart',
                },
              },
            },
            'sites_available' => {
              :children => {
                'owner' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::sites_available_owner',
                  :mod_def => 'root',
                },
                'group' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'nginx::sites_available_group',
                  :mod_def => {
                    'default' => 'root',
                    'freebsd' => 'wheel',
                    'openbsd' => 'wheel',
                  },
                },
                'mode' => {
                  :expect  => [:chmod],
                  :maps_to => 'nginx::sites_available_mode',
                  :mod_def => '0644',
                },
              },
            },
            'template' => {
              :children => {
                'conf' => {
                  :expect  => [:unix_relpath],
                  :maps_to => 'nginx::conf_template',
                  :mod_def => 'nginx/conf.d/nginx.conf.erb',
                },
                'proxy_conf' => {
                  :expect  => [:unix_relpath],
                  :maps_to => 'nginx::proxy_conf_template',
                  :mod_def => 'nginx/conf.d/proxy.conf.erb',
                },
              },
            },
            'types_hash' => {
              :children => {
                'bucket_size' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::types_hash_bucket_size',
                  :mod_def => '512',
                },
                'max_size' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::types_hash_max_size',
                  :mod_def => '1024',
                },
              },
            },
            'worker' => {
              :children => {
                'connections' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::worker_connections',
                  :mod_def => '1024',
                },
                'processes' => {
                  :expect  => [:integer, :auto],
                  :maps_to => 'nginx::worker_processes',
                  :mod_def => '1',
                },
                'rlimit_nofile' => {
                  :expect  => [:integer],
                  :maps_to => 'nginx::worker_rlimit_nofile',
                  :mod_def => '1024',
                },
              },
            },
            'vhosts' => {
              :maps_to  => 'nginx::nginx_vhosts',
              :children_hash  => {
                # Adds headers to the HTTP response when response code is equal to 200, 204, 301, 302 or 304.
                'add_header' => {
                  :expect  => [:hash_values],
                },
                'auth_basic' => {
                  :children => {
                    # This directive includes testing name and password with HTTP Basic Authentication.
                    'include' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'auth_basic',
                    },
                    # This directive sets the htpasswd filename for the authentication realm.
                    'user_file' => {
                      :expect  => [:puppet_interpolable_uri],
                      :maps_to => 'auth_basic_user_file',
                    },
                  },
                },
                # Set it on 'on' or 'off 'to activate/deactivate autoindex directory listing
                'auto_index' => {
                  :expect  => [:flag],
                },
                'cfg' => {
                  :children => {
                    'vhost' => {
                      :children => {
                        # Custom directives to put after everything else inside vhost
                        'append' => {
                          :expect  => [:hash_values],
                          :maps_to => 'vhost_cfg_append',
                        },
                        # Custom directives to put before everything else inside vhost
                        'prepend' => {
                          :expect  => [:hash_values],
                          :maps_to => 'vhost_cfg_prepend',
                        },
                      },
                    },
                    'vhost_ssl' => {
                      :children => {
                        # Custom directives to put after everything else inside vhost ssl
                        'append' => {
                          :expect  => [:hash_values],
                          :maps_to => 'vhost_cfg_ssl_append',
                        },
                        # Custom directives to put before everything else inside vhost ssl
                        'prepend' => {
                          :expect  => [:hash_values],
                          :maps_to => 'vhost_cfg_ssl_prepend',
                        },
                      },
                    },
                    'location' => {
                      :children => {
                        'append' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_cfg_append',
                        },
                        'prepend' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_cfg_prepend',
                        },
                      },
                    },
                    'location_custom' => {
                      :children => {
                        'directives' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_custom_cfg',
                        },
                        'append' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_custom_cfg_append',
                        },
                        'prepend' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_custom_cfg_prepend',
                        },
                      },
                    },
                  },
                },
                'client' => {
                  :children => {
                    'body' => {
                      :children => {
                        # This directive sets client_max_body_size.
                        'max_size' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'client_max_body_size',
                        },
                        # Sets how long the server will wait for a client body.
                        'timeout' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'client_body_timeout',
                        },
                      },
                    },
                    'header' => {
                      :children => {
                        # Sets how long the server will wait for a client header.
                        'timeout' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'client_header_timeout',
                        },
                      },
                    },
                  },
                },
                # Enables or disables the specified vhost
                'ensure' => {
                  :expect  => [:puppet_interpolable_string],
                  :allow   => ['absent', 'present'],
                  :mod_def => 'present',
                },
                'fastcgi' => {
                  :children => {
                    # Location of fastcgi (host:port)
                    'location' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'fastcgi',
                    },
                    # Optional alternative fastcgi_params file to use
                    'params_file' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'fastcgi_params',
                      :mod_def => {
                        'default' => '/etc/nginx/fastcgi_params',
                        'freebsd' => '/usr/local/etc/nginx/fastcgi_params',
                        'smartos' => '/usr/local/etc/nginx/fastcgi_params',
                      },
                    },
                    # DEPRECATED: fastcgi_script => Optional SCRIPT_FILE parameter
                  },
                },
                # Defines group of the .conf file
                'group' => {
                  :expect  => [:chmod],
                  :maps_to => 'group',
                  :mod_def => {
                    'default' => 'root',
                    'freebsd' => 'wheel',
                    'openbsd' => 'wheel',
                  },
                },
                # Defines gzip_types, nginx default is text/html
                'gzip_types' => {
                  :expect  => [:string],
                },
                # Adds include files to vhost
                'include_files' => {
                  :expect  => [:array],
                },
                # Default index files for NGINX to read when traversing a directory
                'index_files' => {
                  :expect  => [:array],
                  :mod_def => [
                    'index.html',
                    'index.htm',
                    'index.php'
                  ],
                },
                'listen' => {
                  :children => {
                    'ipv4' => {
                      :children => {
                        # Default IP Address for NGINX to listen with this vHost on
                        'ip' => {
                          :expect  => [:ipv4, :array_ipv4],
                          :maps_to => 'listen_ip',
                          :mod_def => '*',
                        },
                        # Extra options for listen directive like 'default' to catchall.
                        'options' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'listen_options',
                        },
                        # Default IP Address for NGINX to listen with this vHost on
                        'port' => {
                          :expect  => [:port],
                          :maps_to => 'listen_port',
                          :mod_def => '80',
                        },
                      },
                    },
                    'ipv6' => {
                      :children   => {
                        # Enable/disable IPv6 support. Module will check to see
                        # if IPv6 support exists on your system before enabling.
                        'enable' => {
                          :expect  => [:boolean],
                          :maps_to => 'ipv6_enable',
                          :mod_def => 'false',
                        },
                        # Default IPv6 Address for NGINX to listen with this vHost on.
                        'ip' => {
                          :expect  => [:ipv6, :array_ipv6],
                          :maps_to => 'ipv6_listen_ip',
                          :mod_def => '::',
                        },
                        # Extra options for listen directive like 'default' to catchall. Template will
                        # allways add ipv6only=on. While issue jfryman/puppet-nginx#30 is discussed.
                        'options' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'ipv6_listen_options',
                          :mod_def => 'default ipv6only=on',
                        },
                        # Default IPv6 Port for NGINX to listen with this vHost on
                        'port' => {
                          :expect  => [:port],
                          :maps_to => 'ipv6_listen_port',
                          :mod_def => '80',
                        },
                      },
                    },
                  },
                },
                # Enables or disables the specified vhost
                'location' => {
                  :children => {
                    # Locations to allow connections from.
                    'allow' => {
                      :expect  => [:array],
                      :maps_to => 'location_allow',
                    },
                    # Locations to deny connections from.
                    'deny' => {
                      :expect  => [:array],
                      :maps_to => 'location_deny',
                    },
                    'use_default' => {
                      :expect  => [:boolean],
                      :maps_to => 'use_default_location',
                      :mod_def => 'true',
                    },
                  },
                },
                'log' => {
                  :children => {
                    # Where to write access log. May add additional options like log format to the end.
                    'access' => {
                      :expect  => [:flag, :string],  # Keep an eye: abspath followed by format
                      :maps_to => 'access_log',
                      :mod_def => {
                        'default' => '/var/log/nginx/access.log',
                        'openbsd' => '/var/www/logs/access.log',
                      },
                    },
                    # Where to write error log. May add additional options like error level to the end.
                    'error' => {
                      :expect  => [:string],
                      :maps_to => 'error_log',
                      :mod_def => {
                        'default' => '/var/log/nginx/error.log',
                        'openbsd' => '/var/www/logs/error.log',
                      },
                    },
                    'format' => {
                      :expect  => [:hash_values],
                      :maps_to => 'format_log',
                      :mod_def => 'combined',
                    },
                    # Run the Lua source code inlined as the <lua-script-str> at the log request
                    # processing phase. This does not replace the current access logs, but runs after.
                    'lua' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'log_by_lua',
                    },
                    # Equivalent to log_by_lua, except that the file specified by <path-to-lua-script-file> contains
                    # the Lua code, or, as from the v0.5.0rc32 release, the Lua/LuaJIT bytecode to be executed.
                    'lua_file' => {
                      :expect  => [:puppet_interpolable_uri],
                      :maps_to => 'log_by_lua_file',
                    },
                  },
                },
                'maintenance' => {
                  :children => {
                    # A boolean value to set a vhost in maintenance
                    'enabled' => {
                      :expect  => [:boolean],
                      :maps_to => 'maintenance',
                      :mod_def => 'false',
                    },
                    # Value to return when maintenance is on.
                    'value' => {
                      :expect  => [:string],
                      :maps_to => 'maintenance_value',
                      :mod_def => 'return 503',
                    },
                  },
                },
                'mappings' => {
                  :children => {
                    'geo' => {
                      :expect  => [:hash_values],
                      :maps_to => 'geo_mappings',
                    },
                    'string' => {
                      :expect  => [:hash_values],
                      :maps_to => 'string_mappings',
                    },
                  },
                },
                # Defines mode of the .conf file
                'mode' => {
                  :expect  => [:chmod],
                  :maps_to => 'mode',
                  :mod_def => '0644',
                },
                # Defines owner of the .conf file
                'owner' => {
                  :expect  => [:puppet_interpolable_string],
                  :maps_to => 'owner',
                  :mod_def => 'root',
                },
                # Allows one to define additional CGI environment variables to pass to the backend application
                'passenger_cgi_param' => {
                  :expect  => [:hash],
                },
                'proxy' => {
                  :children => {
                    'cache' => {
                      :children => {
                        # This directive sets name of zone for caching.
                        # The same zone can be used in multiple places.
                        'zone_name' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'proxy_cache',
                          :mod_def => 'false',
                        },
                        # This directive sets the time for caching different replies.
                        'valid' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'proxy_cache_valid',
                          :mod_def => 'false',
                        },
                      },
                    },
                    # Proxy server(s) for the root location to connect to.  Accepts a single
                    # value, can be used in conjunction with nginx::resource::upstream
                    'location' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy',
                    },
                    # If defined, overrides the HTTP method of the request to be passed to the backend.
                    'method' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy_method',
                    },
                    # Override the default proxy_redirect value of off.
                    'redirect' => {
                      :expect  => [:flag],
                      :maps_to => 'proxy_redirect',
                    },
                    # If defined, sets the body passed to the backend.
                    'set_body' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy_set_body',
                    },
                    # Array of vhost headers to set
                    'set_header' => {
                      :expect  => [:array],
                      :maps_to => 'proxy_set_header',
                    },
                    'timeout' => {
                      :children => {
                        # Override the default the proxy read timeout value of 90 seconds
                        'read' => {
                          :expect  => [:integer],
                          :maps_to => 'proxy_read_timeout',
                          :mod_def => '90',
                        },
                        # Override the default the proxy connect timeout value of 90 seconds
                        'connect' => {
                          :expect  => [:integer],
                          :maps_to => 'proxy_connect_timeout',
                          :mod_def => '90',
                        },
                      },
                    },
                  },
                },
                'raw' => {
                  :children => {
                    'location' => {
                      :children => {
                        # A single string, or an array of strings to append to the location directive (after custom_cfg directives).
                        # NOTE: YOU are responsible for a semicolon on each line that requires one.
                        'append' => {
                          :expect  => [:puppet_interpolable_string, :array],
                          :maps_to => 'location_raw_append',
                        },
                        # A single string, or an array of strings to prepend to the location directive (after custom_cfg directives).
                        # NOTE: YOU are responsible for a semicolon on each line that requires one.
                        'prepend' => {
                          :expect  => [:puppet_interpolable_string, :array],
                          :maps_to => 'location_raw_prepend',
                        },
                      },
                    },
                    'server' => {
                      :children => {
                        # A single string, or an array of strings to append to the server directive (after cfg append directives).
                        # NOTE: YOU are responsible for a semicolon on each line that requires one.
                        'append' => {
                          :expect  => [:puppet_interpolable_string, :array],
                          :maps_to => 'raw_append',
                        },
                        # A single string, or an array of strings to prepend to the server directive (after cfg prepend directives).
                        # NOTE: YOU are responsible for a semicolon on each line that requires one.
                        'prepend' => {
                          :expect  => [:puppet_interpolable_string, :array],
                          :maps_to => 'raw_prepend',
                        },
                      },
                    },
                  },
                },
                'rewrite' => {
                  :children => {
                    # Adds a server directive and rewrite rule to rewrite to ssl
                    'http_to_https' => {
                      :expect  => [:boolean],
                      :maps_to => 'rewrite_to_https',
                    },
                    'rules' => {
                      :expect  => [:array],
                      :maps_to => 'rewrite_rules',
                    },
                    # Adds a server directive and rewrite rule to rewrite www.domain.com
                    # to domain.com in order to avoid duplicate content (SEO);
                    'www_to_non_www' => {
                      :expect  => [:boolean],
                      :maps_to => 'rewrite_www_to_non_www',
                      :mod_def => 'false',
                    },
                  },
                },
                # Configures name servers used to resolve names of upstream servers into addresses.
                'resolver' => {
                  :expect  => [:array],
                },
                # List of vhostnames for which this vhost will respond.
                'server_name' => {
                  :expect  => [:array],
                },
                # Toggles SPDY protocol.
                'spdy' => {
                  :expect  => [:flag],
                  :mod_def => 'off',
                },
                'ssl' => {
                  :children => {
                    # Indicates whether to setup SSL bindings for this vhost.
                    'bind' => {
                      :expect  => [:boolean],
                      :maps_to => 'ssl',
                      :mod_def => 'false',
                    },
                    'cache' => {
                      :expect  => [:string],
                      :maps_to => 'ssl_cache',
                      :mod_def => 'shared:SSL:10m',
                    },
                    'cert' => {
                      :children => {
                        # Pre-generated SSL Certificate file to reference for SSL Support (not generated).
                        'cert' => {
                          :expect  => [:puppet_interpolable_uri],
                          :maps_to => 'ssl_cert',
                        },
                        # Pre-generated SSL Certificate file to reference for client verify SSL Support (not generated).
                        'client' => {
                          :expect  => [:puppet_interpolable_uri],
                          :maps_to => 'ssl_client_cert',
                        },
                        # Specifies a file with trusted CA certificates in the PEM format used to
                        # verify client certificates and OCSP responses if ssl_stapling is enabled.
                        'trusted' => {
                          :expect  => [:puppet_interpolable_uri],
                          :maps_to => 'ssl_trusted_cert',
                        },
                      },
                    },
                    # SSL ciphers enabled.
                    'ciphers' => {
                      :expect  => [:puppet_interpolable_uri],
                      :maps_to => 'ssl_ciphers',
                      :mod_def => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
                    },
                    # This directive specifies a file containing Diffie-Hellman key agreement protocol cryptographic
                    # parameters, in PEM format, utilized for exchanging session keys between server and client.
                    'dhparam' => {
                      :expect  => [:puppet_interpolable_uri],
                      :maps_to => 'ssl_dhparam',
                    },
                    # Pre-generated SSL Key file to reference for SSL Support (not generated).
                    'key' => {
                      :expect  => [:puppet_interpolable_uri],
                      :maps_to => 'ssl_key',
                    },
                    'listen_option' => {
                      :expect  => [:boolean],
                      :maps_to => 'ssl_listen_option',
                      :mod_def => 'true',
                    },
                    # Default IP Port for NGINX to listen with this SSL vHost on.
                    'port' => {
                      :expect  => [:port],
                      :maps_to => 'ssl_port',
                      :mod_def => '443',
                    },
                    # SSL protocols enabled. Defaults to 'TLSv1 TLSv1.1 TLSv1.2'.
                    'protocols' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'ssl_protocols',
                      :mod_def => 'TLSv1 TLSv1.1 TLSv1.2',
                    },
                    # Specifies a time during which a client may reuse the session parameters stored in a cache.
                    'session_timeout' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'ssl_session_timeout',
                      :mod_def => '5m',
                    },
                    'stapling' => {
                      :children => {
                        # Enables or disables stapling of OCSP responses by the server.
                        'enabled' => {
                          :expect  => [:boolean],
                          :maps_to => 'ssl_stapling',
                          :mod_def => 'false',
                        },
                        # When set, the stapled OCSP response will be taken from the specified file
                        # instead of querying the OCSP responder specified in the server certificate.
                        'file' => {
                          :expect  => [:puppet_interpolable_uri],
                          :maps_to => 'ssl_stapling_file',
                        },
                        # Overrides the URL of the OCSP responder specified in the
                        # Authority Information Access certificate extension.
                        'responder' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'ssl_stapling_responder',
                        },
                        # Enables or disables verification of OCSP responses by the server.
                        'verify' => {
                          :expect  => [:boolean],
                          :maps_to => 'ssl_stapling_verify',
                          :mod_def => 'false',
                        },
                      },
                    },
                  },
                },
                # Specifies the locations for files to be checked as an array. Cannot be used in conjuction with $proxy.
                'try_files' => {
                  :exclude => ['proxy->location'],
                  :expect  => [:array],
                },
                # Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy
                'www_root' => {
                  :exclude => ['proxy->location'],
                  :expect  => [:unix_abspath],
                },
              },
            },
            'locations' => {
              :maps_to  => 'nginx::nginx_locations',
              :children_hash  => {
                'auth_basic' => {
                  :children => {
                    # This directive includes testing name and password with HTTP Basic Authentication.
                    'include' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'auth_basic',
                    },
                    # This directive sets the htpasswd filename for the authentication realm.
                    'user_file' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'auth_basic_user_file',
                    },
                  },
                },
                # Set it on 'on' to activate autoindex directory listing.
                'autoindex' => {
                  :expect  => [:flag],
                },
                # Enables or disables the specified location
                'ensure' => {
                  :expect  => [:puppet_interpolable_string],
                  :allow   => ['absent', 'present'],
                  :mod_def => 'present',
                },
                # Default index files for NGINX to read when traversing a directory
                'index_files' => {
                  :expect  => [:boolean],
                  :mod_def => ['index.html', 'index.htm', 'index.php'],
                },
                # Indicates whether or not this loation can be used for internal requests only
                'internal' => {
                  :expect  => [:boolean],
                  :mod_def => 'false',
                },
                'proxy' => {
                  :children => {
                    'cache' => {
                      :children => {
                        # This directive sets name of zone for caching.
                        # The same zone can be used in multiple places.
                        'zone_name' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'proxy_cache',
                          :mod_def => 'false',
                        },
                        # This directive sets the time for caching different replies.
                        'valid' => {
                          :expect  => [:puppet_interpolable_string],
                          :maps_to => 'proxy_cache_valid',
                          :mod_def => 'false',
                        },
                      },
                    },
                    # Proxy server(s) for a location to connect to. Accepts a single
                    # value, can be used in conjunction with nginx::resource::upstream
                    'location' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy',
                    },
                    # If defined, overrides the HTTP method of the request to be passed to the backend.
                    'method' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy_method',
                    },
                    # Sets the text, which must be changed in response-header
                    # "Location" and "Refresh" in the response of the proxied server
                    'redirect' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy_redirect',
                      :mod_def => 'off',
                    },
                    # If defined, sets the body passed to the backend.
                    'set_body' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'proxy_set_body',
                    },
                    # Array of vhost headers to set
                    'set_header' => {
                      :expect  => [:array],
                      :maps_to => 'proxy_set_header',
                      :mod_def => [
                        'Host $host',
                        'X-Real-IP $remote_addr',
                        'X-Forwarded-For $proxy_add_x_forwarded_for',
                      ],
                    },
                    'timeout' => {
                      :children => {
                        # Override the default the proxy read timeout value of 90 seconds
                        'read' => {
                          :expect  => [:integer],
                          :maps_to => 'proxy_read_timeout',
                          :mod_def => '90',
                        },
                        # Override the default the proxy connect timeout value of 90 seconds
                        'connect' => {
                          :expect  => [:integer],
                          :maps_to => 'proxy_connect_timeout',
                          :mod_def => '90',
                        },
                      },
                    },
                  },
                },
                # Defines the default vHost for this location entry to include with
                'vhost' => {
                  :expect  => [:puppet_interpolable_string],
                },
                # Specifies the location on disk for files to be read from. Cannot be set in conjunction with $proxy
                'www_root' => {
                  :expect  => [:puppet_interpolable_string],
                  :exclude => ['proxy->cache->zone_name'],
                },
                'location' => {
                  :children => {
                    # Path to be used as basis for serving requests for this location
                    'alias' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'location_alias',
                    },
                    # Array: Locations to allow connections from.
                    'allow' => {
                      :expect  => [:array],
                      :maps_to => 'location_allow',
                    },
                    # Location of fastcgi (host:port)
                    'cfg' => {
                      :children => {
                        # Expects a hash with extra directives to put before anything else
                        # inside location (used with all other types except custom_cfg)
                        'prepend' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_cfg_prepend',
                        },
                        # Expects a hash with extra directives to put after everything else
                        # inside location (used with all other types except custom_cfg)
                        'append' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_cfg_append',
                        },
                      }
                    },
                    'custom_cfg' => {
                      :children => {
                        # Expects a hash with custom directives, cannot be used with
                        # other location types (proxy, fastcgi, root, or stub_status)
                        'directives' => {
                          :expect  => [:hash_values],
                          :exclude => ['fastcgi->location', 'proxy->location', 'www_root', 'stub_status'],
                          :maps_to => 'location_custom_cfg',
                        },
                        # Expects a array with extra directives to put before anything else inside location
                        # (used with all other types except custom_cfg). Used for logical structures such as if.
                        'prepend' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_custom_cfg_prepend',
                        },
                        # Expects a array with extra directives to put after anything else inside location
                        # (used with all other types except custom_cfg). Used for logical structures such as if.
                        'append' => {
                          :expect  => [:hash_values],
                          :maps_to => 'location_custom_cfg_append',
                        },
                      },
                    },
                    # Array: Locations to deny connections from.
                    'deny' => {
                      :expect  => [:array],
                      :maps_to => 'location_deny',
                    },
                    # Specifies the URI associated with this location
                    'uri' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'location',
                    },
                  },
                },
                'fastcgi' => {
                  :children => {
                    # Location of fastcgi (host:port)
                    'location' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'fastcgi',
                    },
                    # Set additional custom fastcgi_params
                    'param' => {
                      :expect  => [:hash_values],
                      :maps_to => 'fastcgi_param',
                    },
                    # Optional alternative fastcgi_params file to use
                    'params_file' => {
                      :expect  => [:unix_abspath],
                      :maps_to => 'fastcgi_params',
                      :mod_def => {
                        'default' => '/etc/nginx/fastcgi_params',
                        'freebsd' => '/usr/local/etc/nginx/fastcgi_params',
                        'smartos' => '/usr/local/etc/nginx/fastcgi_params',
                      },
                    },
                    # Allows settings of fastcgi_split_path_info so that you can
                    # split the script_name and path_info via regex
                    'split_path' => {
                      :expect  => [:puppet_interpolable_string],
                      :maps_to => 'fastcgi_split_path',
                    },
                    # DEPRECATED: fastcgi_script => Optional SCRIPT_FILE parameter
                  },
                },
                'ssl' => {
                  :children => {
                    # Indicates whether to setup SSL bindings for this location.
                    'bind' => {
                      :expect  => [:boolean],
                      :maps_to => 'ssl',
                      :mod_def => 'false',
                    },
                    # Required if the SSL and normal vHost have the same port.
                    'only' => {
                      :expect  => [:boolean],
                      :maps_to => 'ssl_only',
                      :mod_def => 'false',
                    },
                  },
                },
                'raw' => {
                  :children => {
                    # A single string, or an array of strings to prepend to the location directive (after
                    # custom_cfg directives). NOTE: YOU are responsible for a semicolon on each line that requires one.
                    'prepend' => {
                      :expect  => [:puppet_interpolable_string, :array],
                      :maps_to => 'raw_prepend',
                    },
                    # A single string, or an array of strings to append to the location directive (after
                    # custom_cfg directives). NOTE: YOU are responsible for a semicolon on each line that requires one.
                    'append' => {
                      :expect  => [:puppet_interpolable_string, :array],
                      :maps_to => 'raw_append',
                    },
                  },
                },
                # Indicates whether or not this loation can be used for flv streaming.
                'flv' => {
                  :expect  => [:boolean],
                  :mod_def => 'false',
                },
                'include' => {
                  :expect  => [:array],
                },
                # Indicates whether or not this loation can be used for mp4 streaming.
                'mp4' => {
                  :expect  => [:boolean],
                  :mod_def => 'false',
                },
                # Location priority. Default: 500. User priority 401-499, 501-599. If the priority is
                # higher than the default priority, the location will be defined after root, or before root.
                # TODO: Range => 401-899
                'priority' => {
                  :expect  => [:integer],
                  :mod_def => '500',
                },
                'rewrite_rules' => {
                  :expect  => [:array],
                },
                # If true it will point configure module stub_status to provide nginx stats on location
                'stub_status' => {
                  :expect  => [:boolean],
                },
                # An array of file locations to try
                'try_files' => {
                  :expect  => [:array],
                },
              },
            },
            'upstreams' => {
              :maps_to  => 'nginx::nginx_upstreams',
              :children_hash  => {
                # Array of member URIs for NGINX to connect to. Must follow valid NGINX syntax.
                'members' => {
                  :expect  => [:array],
                },
                # Enables or disables the specified location
                'ensure' => {
                  :expect  => [:puppet_interpolable_string],
                  :allow   => ['absent', 'present'],
                  :mod_def => 'present',
                },
                # It expects a hash with custom directives to put before anything else inside upstream
                'cfg_prepend' => {
                  :expect  => [:hash_values],
                },
                # Set the fail_timeout for the upstream
                'fail_timeout' => {
                  :expect  => [:puppet_interpolable_string],
                  :mod_def => '10s',
                },
              },
            },
          }

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

        def self.custom_setup(provided)
          if DOA::Guest.provisioner.current_project.nil?
            # Group WordPress projects by vhost root
            wp_projects = {}
            socket = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_PHP, 'fpm', 'pools', '*', 'listen', 'socket'], DOA::Setting::PM_WP)
            if DOA::Tools.valid_ipv4_port?(socket)
              upstream_member = socket
            elsif DOA::Tools.valid_unix_abspath?(socket)
              upstream_member = "unix:#{ socket }"
            else
              upstream_member = '127.0.0.1:9000'
            end
            projects = DOA::Tools.check_get(DOA::Guest.settings, DOA::Tools::TYPE_HASH,
              [DOA::Guest.hostname, DOA::Guest.hostname], DOA::Setting::PROJECTS)
            projects.each do |project, settings|
              if settings.has_key?('stack') and settings['stack'].has_key?(DOA::Setting::SW_WP)
                # The virtual host root is the installation dir of the WP instance app
                www_root = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_WP, 'wp', 'install', 'dir'], DOA::Setting::PM_WP, settings['stack'])
                www_root = DOA::Provisioner::Puppet::WordPress::DEF_INSTALL_DIR if www_root.empty?
                subdir   = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_WP, 'wp', 'subdirectory'], DOA::Setting::PM_WP, settings['stack'])
                subdir   = subdir.empty? ? '' : (['true', 'on', 'yes', '1'].include?(subdir.to_s) ? project : subdir)
                wp_projects[www_root] = {} if !wp_projects.has_key?(www_root)

                # Top installation
                if subdir.empty?
                  wp_projects[www_root][:top] = [] if !wp_projects[www_root].has_key?(:top)
                # Subdir installation
                else
                  wp_projects[www_root][:subdir] = [] if !wp_projects[www_root].has_key?(:subdir)
                  wp_projects[www_root][:subdir].insert(-1, subdir)
                end
              end
            end

            if !wp_projects.empty?
              # Add new aliases for WP & PMA and update hosts file @ host
              pma_server = "pma.#{ DOA::Guest.name }.vm"
              wp_server = "wp.#{ DOA::Guest.name }.vm"
              DOA::Guest.set_aliases(DOA::Guest.aliases.insert(-1, wp_server, pma_server))

              # PHP upstream
              DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
                @supported['upstreams'][:maps_to] => { "'php'" => {
                    'ensure'  => "'present'",
                    'members' => ["'#{ upstream_member }'"],
                  }}})

              # phpMyAdmin virtual host
              DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
                  @supported['vhosts'][:maps_to] => {
                    pma_server => {
                      'ensure'                => "'present'",
                      'listen_port'           => "'80'",
                      'spdy'                  => "'on'",
                      'use_default_location'  => 'false',
                      'www_root'              => "'#{ DEF_WWW_ROOT }/pma'",
                      'index_files'           => ["'index.html'", "'index.htm'", "'index.php'"],
                    },
                  },
                  @supported['locations'][:maps_to] => {
                    "'pma_static'" => {
                      'ensure'              => "'present'",
                      'vhost'               => pma_server,
                      'location'            => "'~* \\.(#{ STATIC_EXTS.join('|') })$'",
                      'location_custom_cfg' => {
                        "'expires'"         => "'max'",
                        "'access_log'"      => "'off'",
                      },
                    },
                    "'pma_upstream_php'" => {
                      'ensure'                      => "'present'",
                      'vhost'                       => pma_server,
                      'fastcgi'                     => "'php'",
                      'fastcgi_param'               => {
                        "'SCRIPT_FILENAME'"         => "'$document_root$fastcgi_script_name'",
                      },
                      'location'                    => "'~* \\.php$'",
                      'location_cfg_append'         => {
                        "'fastcgi_connect_timeout'" => "'3m'",
                        "'fastcgi_read_timeout'"    => "'3m'",
                        "'fastcgi_send_timeout'"    => "'3m'",
                        "'fastcgi_index'"           => "'index.php'",
                      },
                    },
                  },
                })

              # WordPress virtual host
              wp_projects.each do |root, settings|
                root_params = {}
                esc_root = root.gsub('/', '_')
                location_map = @supported['locations'][:maps_to]

                # Nginx virtual host (vhost)
                root_params[@supported['vhosts'][:maps_to]] = {
                  wp_server => {
                    'ensure'                => "'present'",
                    'listen_port'           => "'80'",
                    'spdy'                  => "'on'",
                    'use_default_location'  => 'false',
                    'www_root'              => "'#{ root }'",
                    'index_files'           => ["'index.html'", "'index.htm'", "'index.php'"],
                  },
                }

                # Nginx location for static files
                root_params[location_map] = {
                  "'wp#{ esc_root }_static'" => {
                    'ensure'              => "'present'",
                    'vhost'               => wp_server,
                    'location'            => "'~* \\.(#{ STATIC_EXTS.join('|') })$'",
                    'location_custom_cfg' => {
                      "'expires'"         => "'max'",
                      "'access_log'"      => "'off'",
                    },
                  },
                }

                # Nginx location for WordPress installations in subdirectories
                if settings.has_key?(:subdir)
                  root_params[location_map]["'wp#{ esc_root }_upstream_php'"] = {
                    'ensure'                      => "'present'",
                    'vhost'                       => wp_server,
                    'try_files'                   => [
                      "'$uri'",
                      "'$uri/'",
                      "'/$1/index.php?$args'",
                    ],
                    'fastcgi'                     => "'php'",
                    'fastcgi_param'               => {
                      "'SCRIPT_FILENAME'"         => "'$document_root$fastcgi_script_name'",
                    },
                    'location'                    => "'~ ^/(#{ wp_projects[root][:subdir].join('|') })'",
                    'location_cfg_append'         => {
                      "'fastcgi_connect_timeout'" => "'3m'",
                      "'fastcgi_read_timeout'"    => "'3m'",
                      "'fastcgi_send_timeout'"    => "'3m'",
                      "'fastcgi_index'"           => "'index.php'",
                    },
                  }
                end

                # Nginx location for top WordPress installation
                if settings.has_key?(:top)
                  root_params[location_map]["'wp#{ esc_root }_upstream_php_top'"] = {
                    'ensure'                      => "'present'",
                    'vhost'                       => wp_server,
                    'try_files'                   => [
                      "'$uri'",
                      "'$uri/'",
                      "'/index.php?$args'",
                    ],
                    'fastcgi'                     => "'php'",
                    'fastcgi_param'               => {
                      "'SCRIPT_FILENAME'"         => "'$document_root$fastcgi_script_name'",
                    },
                    'location'                    => "'/'",
                    'location_cfg_append'         => {
                      "'fastcgi_connect_timeout'" => "'3m'",
                      "'fastcgi_read_timeout'"    => "'3m'",
                      "'fastcgi_send_timeout'"    => "'3m'",
                      "'fastcgi_index'"           => "'index.php'",
                    },
                  }
                end

                # Enqueue hiera params
                DOA::Provisioner::Puppet.enqueue_hiera_params(@label, root_params) if !root_params.empty?
              end
            end
          end
        end
      end
    end
  end
end
