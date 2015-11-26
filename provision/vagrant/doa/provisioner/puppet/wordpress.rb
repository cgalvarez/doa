#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class WordPress < PuppetModule
        # Constants.
        MOD_CGALVAREZ_WORDPRESS = 'cgalvarez/wordpress'
        DEF_INSTALL_DIR = '/opt/wordpress'

        # Class variables.
        @label        = Setting::PM_WP
        @hieraclasses = ['wordpress']
        @librarian    = {
          MOD_CGALVAREZ_WORDPRESS => {},
        }

        # Puppet modules parameters.
        # jfryman/nginx => https://github.com/jfryman/puppet-nginx
        @supported = {
            'instances' => {
              :maps_to  => 'wordpress::wp_instances',
              :children_hash  => {
                'db' => {
                  :children => {
                    'create' => {
                      :children => {
                        # Specifies whether to create the db or not
                        'db' => {
                          :expect  => [:boolean],
                          :maps_to => 'create_db',
                          :mod_def => 'true',
                        },
                        # Specifies whether to create the db user or not
                        'user' => {
                          :expect  => [:boolean],
                          :maps_to => 'create_db_user',
                          :mod_def => 'true',
                        },
                      },
                    },
                    # Specifies the database name which the wordpress module
                    # should be configured to use
                    'name' => {
                      :expect  => [:puppet_interpolable_string],
                      :mod_def => 'wordpress',
                      :maps_to => 'db_name',
                    },
                    # Specifies the database host to connect to
                    'host' => {
                      :expect  => [:puppet_interpolable_string],
                      :mod_def => 'localhost',
                      :maps_to => 'db_host',
                    },
                    # Specifies the database user
                    'user' => {
                      :expect  => [:puppet_interpolable_string],
                      :mod_def => 'wordpress',
                      :maps_to => 'db_user',
                    },
                    # Specifies the database user's password in plaintext
                    'password' => {
                      :expect  => [:puppet_interpolable_string],
                      :mod_def => 'password',
                      :maps_to => 'db_password',
                    },
                  },
                },
                'wp' => {
                  :children => {
                    # Specifies a template to include near the end of the
                    # wp-config.php file to add additional options
                    'additional_config' => {
                      :expect  => [:puppet_interpolable_uri],
                      :maps_to => 'wp_additional_config',
                      :mod_def => '',
                    },
                    # wp-config.php file to add additional options
                    'debug' => {
                      :children => {
                        # Specifies the `WP_DEBUG` value that will control debugging.
                        # This must be true if you use the next two debug extensions
                        'enable' => {
                          :expect  => [:boolean],
                          :maps_to => 'wp_debug',
                          :mod_def => 'false',
                          :doa_def => {
                            :dev  => 'true',
                            :test => 'true',
                            :prod => 'true',
                          },
                        },
                        # Specifies the `WP_DEBUG_LOG` value that extends debugging
                        # to cause all errors to also be saved to a debug.log logfile
                        # inside the /wp-content/ directory.
                        'log' => {
                          :expect  => [:boolean],
                          :maps_to => 'wp_debug_log',
                          :mod_def => 'false',
                          :doa_def => {
                            :dev  => 'true',
                            :test => 'true',
                            :prod => 'true',
                          },
                        },
                        # Specifies the `WP_DEBUG_DISPLAY` value that extends debugging
                        # to cause debug messages to be shown inline, in HTML pages
                        'display' => {
                          :expect  => [:boolean],
                          :maps_to => 'wp_debug_display',
                          :mod_def => 'false',
                          :doa_def => {
                            :dev  => 'true',
                            :test => 'true',
                            :prod => 'false',
                          },
                        },
                      },
                    },
                    'dir' => {
                      :children => {
                        # WordPress Plugin Directory. Full path, no trailing slash
                        'plugin' => {
                          :expect  => [:unix_abspath],
                          :maps_to => 'wp_plugin_dir',
                        },
                      },
                    },
                    # Specifies the group of the wordpress files
                    'group' => {
                      :expect  => [:string],
                      :mod_def => '0',
                      :maps_to => 'wp_group',
                    },
                    'install' => {
                      :children => {
                        # Specifies the directory into which wordpress should be installed
                        'dir' => {
                          #:expect     => [:unix_abspath],
                          :maps_to    => 'install_dir',
                          :mod_def    => DEF_INSTALL_DIR,
                          :cb_process => "#{ self.to_s }#set_install_dir",
                        },
                        # Specifies the url from which the wordpress tarball should be downloaded
                        'url' => {
                          :expect  => [:url],
                          :maps_to => 'install_url',
                          :mod_def => 'http://wordpress.org',
                        },
                      },
                    },
                    # WordPress Localized Language
                    'lang' => {
                      :expect  => [:string],
                      :mod_def => '',
                      :maps_to => 'wp_lang',
                    },
                    # Specifies whether to enable the multisite feature.
                    # Requires `wp_site_domain` to also be passed
                    'multisite' => {
                      :expect  => [:boolean],
                      :mod_def => 'false',
                      :maps_to => 'wp_multisite',
                    },
                    # Specifies the owner of the wordpress files. You must ensure this user
                    # exists as this module does not attempt to create it if missing.
                    'owner' => {
                      :expect  => [:string],
                      :mod_def => 'root',
                      :maps_to => 'wp_owner',
                    },
                    'proxy' => {
                      :children => {
                        # Specifies a Hostname or IP of a proxy server for
                        # Wordpress to use to install updates, plugins, etc.
                        'host' => {
                          :expect  => [:ipv4, :ipv6, :url],
                          :mod_def => '',
                          :maps_to => 'wp_proxy_host',
                        },
                        # Specifies the port to use with the proxy host
                        'port' => {
                          :expect  => [:port],
                          :mod_def => '',
                          :maps_to => 'wp_proxy_port',
                        },
                      },
                    },
                    # Specifies the `DOMAIN_CURRENT_SITE` value that will be used when configuring
                    # multisite. Typically this is the address of the main wordpress instance.
                    'site_domain' => {
                      :expect  => [:url],
                      :mod_def => '',
                      :maps_to => 'wp_site_domain',
                    },
                    # Subdirectory where WordPress must be installed
                    'subdirectory' => {
                      :expect     => [:boolean, :unix_relpath],
                      :cb_process => "#{ self.to_s }#empty",
                    },
                    # Specifies the database table prefix
                    'table_prefix' => {
                      :expect  => [:puppet_interpolable_uri],
                      :mod_def => 'wp_',
                      :maps_to => 'wp_table_prefix',
                    },
                  },
                },
              },
            },
          }

        # Adds the required parameters to the corresponding queues:
        #  - Puppet Forge modules (loaded through librarian-puppet -> Puppetfile)
        #  - Classes (loaded through Hiera -> hostname.yaml)
        #  - Relationships (chaining arrows inside -> site.pp)
        # and recursively checks all parameters for the requested software,
        # setting the appropriate values.
        def self.setup(settings)
          @provided = settings
          Provisioner::Puppet.enqueue_librarian_mods(@librarian) if @librarian.is_a?(Hash) and !@librarian.blank?
          Provisioner::Puppet.enqueue_hiera_classes(@hieraclasses) if @hieraclasses.is_a?(Array) and !@hieraclasses.blank?
          Provisioner::Puppet.enqueue_hiera_params(@label, set_params(@supported,
            (!settings.nil? and settings.is_a?(Hash)) ? {'instances' => {
              Guest.provisioner.current_project.nil? ? 'base' : Guest.provisioner.current_project => settings }
            } : {})) if !@supported.empty?

          # Install development software when installing WordPress in development
          # environment unless explicitly stated the opposite
          # --------------------------------------------------------------------
          case Guest.env
          when :dev
            # XDebug (PHP extension)
            xdebug_ensure = Tools.get_puppet_mod_prioritized_def_value([Setting::SW_PHP, 'extensions', 'xdebug', 'ensure'], Setting::PM_PHP)
            if !['absent', 'purged'].include?(xdebug_ensure)
              php      = Provisioner::Puppet.const_get(Setting::PM_PHP)
              provided = Tools.get_puppet_mod_prioritized_def_value([Setting::SW_PHP, 'extensions', 'xdebug'], Setting::PM_PHP)
              defaults = {
                'settings' => {
                  'xdebug.remote_connect_back'      => 1,
                  'xdebug.remote_enable'            => 1,
                  'xdebug.remote_handler'           => 'dbgp',
                  'xdebug.remote_host'              => "#{ Host.ip }",
                  'xdebug.remote_port'              => 9000,
                  'xdebug.profiler_enable'          => 1,
                  'xdebug.profiler_enable_trigger'  => 1,
                  'xdebug.profiler_output_dir'      => '/var/log/xdebug',
                  'xdebug.profiler_output_name'     => 'profile.%R-%u',
                },
              }
              Provisioner::Puppet.enqueue_hiera_params(Setting::PM_PHP, set_params(php.supported, {
                  'extensions' => { 'xdebug' => provided.nil? ? defaults : defaults.merge(provided) }
                })) if !php.supported.empty?
            end
          end
        end

        def self.set_install_dir(value = nil)
          subdirectory = Tools.get_puppet_mod_prioritized_def_value([Setting::SW_WP, 'wp', 'subdirectory'], Setting::PM_WP)
          value        = Tools.get_puppet_mod_prioritized_def_value([Setting::SW_WP, 'wp', 'install', 'dir'], Setting::PM_WP) if value.nil?
          install_dir  = value.empty? ? DEF_INSTALL_DIR : value
          install_dir  = "#{ install_dir }/#{ ['true', 'on', 'yes', '1'].include?(subdirectory.to_s) ? Guest.provisioner.current_project : subdirectory }" if !subdirectory.nil?
          return "'#{ install_dir }'"
        end
      end
    end
  end
end
