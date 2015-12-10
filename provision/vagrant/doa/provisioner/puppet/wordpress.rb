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
        @label        = DOA::Setting::PM_WP
        @hieraclasses = ['wordpress']
        @librarian    = {
          MOD_CGALVAREZ_WORDPRESS => {
            :git  => 'git://github.com/cgalvarez/puppet-wordpress.git',
            :ver  => '1.0.0',
          },
        }
        @from_path    = nil
        @to_path      = nil
        @path         = {}

        # Puppet modules parameters.
        # jfryman/nginx => https://github.com/jfryman/puppet-nginx
        @supported = {
            'instances' => {
              :maps_to  => 'wordpress::instances',
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
                    # Exclude shell patterns for rsync (used as provided)
                    'exclude' => {
                      :expect     => [:array],
                      :cb_process => "#{ self.to_s }#setup_presync_excludes",
                    },
                    # Specifies the group of the wordpress files
                    'group' => {
                      :expect  => [:string],
                      :maps_to => 'wp_group',
                      :mod_def => '0',
                      :doa_def => DOA::Guest::USER,
                    },
                    # Ignore regex patterns for ruby gem listen (appended to WordPress install dir)
                    'ignore' => {
                      :expect  => [:array],
                      :cb_process => "#{ self.to_s }#setup_listen_ignores",
                    },
                    'install' => {
                      :children => {
                        # Specifies the directory into which wordpress should be installed
                        'dir' => {
                          :expect     => [:boolean, :unix_relpath],
                          :maps_to    => 'install_dir',
                          :mod_def    => DEF_INSTALL_DIR,
                          :cb_process => "#{ self.to_s }#get_install_dir",
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
                      :maps_to => 'wp_owner',
                      :mod_def => 'root',
                      :doa_def => DOA::Guest::USER,
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
                'plugins' => {
                  :expect     => [:hash],
                  :cb_process => "#{ self.to_s }#setup_assets@#{ DOA::Setting::WP_ASSET_PLUGIN }",
                },
                'themes' => {
                  :expect     => [:hash],
                  :cb_process => "#{ self.to_s }#setup_assets@#{ DOA::Setting::WP_ASSET_THEME }",
                },
              },
            },
          }

        def self.get_path(sync)
          @from_path = "#{ DOA::Host.session.guest_projects_path }/#{ DOA::Guest.provisioner.current_project }" if @from_path.nil?
          @to_path   = get_install_dir if @to_path.nil?
          if sync.from.instance.instance_of?(Host)
            @path[:from], @path[:to] = @from_path, @to_path
          elsif sync.from.instance.instance_of?(Guest)
            @path[:from], @path[:to] = @to_path, @from_path
          end
        end

        # Adds the required parameters to the corresponding queues:
        #  - Puppet Forge modules (loaded through librarian-puppet -> Puppetfile)
        #  - Classes (loaded through Hiera -> hostname.yaml)
        #  - Relationships (chaining arrows inside -> site.pp)
        # and recursively checks all parameters for the requested software,
        # setting the appropriate values.
        def self.setup(settings)
          @provided = settings
          DOA::Provisioner::Puppet.enqueue_librarian_mods(@librarian) if @librarian.is_a?(Hash) and !@librarian.blank?
          DOA::Provisioner::Puppet.enqueue_hiera_classes(@hieraclasses) if @hieraclasses.is_a?(Array) and !@hieraclasses.blank?
          DOA::Provisioner::Puppet.enqueue_hiera_params(@label, set_params(@supported,
            (!settings.nil? and settings.is_a?(Hash)) ? {'instances' => {
              DOA::Guest.provisioner.current_project.nil? ? 'base' : DOA::Guest.provisioner.current_project => settings }
            } : {})) if !@supported.empty?

          # Install development software when installing WordPress in development
          # environment unless explicitly stated the opposite
          # --------------------------------------------------------------------
          case DOA::Guest.env
          when :dev
            # Continous listening through bidirectional rsync for WordPress installation folder with ruby gem guard/listen
            [DOA::Host.sync, DOA::Guest.sync].each do |sync|
              get_path(sync)
              if sync.from.instance.instance_of?(Host) and !File.exists?(@path[:from])
                require 'fileutils'
                FileUtils.mkdir_p @path[:from]
              end
              sync.listen_to.insert(-1, @path[:from])
              sync.conditions[@path[:from]] = [
                  "from = path.gsub('#{ @path[:from] }', '#{ DOA::SSH.escape(sync.from.os, @path[:from]) }')",
                  "to = path.gsub('#{ @path[:from] }', '#{ DOA::SSH.escape(sync.to.os, @path[:to]) }')",
                ]
              add_excludes(sync)
            end

            # XDebug (PHP extension)
            xdebug_ensure = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_PHP, 'extensions', 'xdebug', 'ensure'], DOA::Setting::PM_PHP)
            if !['absent', 'purged'].include?(xdebug_ensure)
              php      = DOA::Provisioner::Puppet.const_get(DOA::Setting::PM_PHP)
              provided = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_PHP, 'extensions', 'xdebug'], DOA::Setting::PM_PHP)
              defaults = {
                'settings' => {
                  'xdebug.remote_connect_back'      => 1,
                  'xdebug.remote_enable'            => 1,
                  'xdebug.remote_handler'           => 'dbgp',
                  'xdebug.remote_host'              => "#{ DOA::Host.ip }",
                  'xdebug.remote_port'              => 9000,
                  'xdebug.profiler_enable'          => 1,
                  'xdebug.profiler_enable_trigger'  => 1,
                  'xdebug.profiler_output_dir'      => '/var/log/xdebug',
                  'xdebug.profiler_output_name'     => 'profile.%R-%u',
                },
              }
              DOA::Provisioner::Puppet.enqueue_hiera_params(DOA::Setting::PM_PHP, set_params(php.supported, {
                  'extensions' => { 'xdebug' => provided.nil? ? defaults : defaults.merge(provided) }
                })) if !php.supported.empty?
            end
          end
        end

        def self.get_install_dir(value = nil)
          subdirectory = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_WP, 'wp', 'subdirectory'], DOA::Setting::PM_WP)
          value        = DOA::Tools.get_puppet_mod_prioritized_def_value([DOA::Setting::SW_WP, 'wp', 'install', 'dir'], DOA::Setting::PM_WP) if value.nil?
          install_dir  = value.empty? ? DEF_INSTALL_DIR : value
          install_dir  = "#{ install_dir }/#{ ['true', 'on', 'yes', '1'].include?(subdirectory.to_s) ? DOA::Guest.provisioner.current_project : subdirectory }" if !subdirectory.nil?
          return install_dir
        end

        def self.setup_presync_excludes(value)
          excludes = (value.is_a?(Array) and !value.empty?) ? value : DOA::Sync::DEFAULT_EXCLUDES
          [DOA::Host.sync, DOA::Guest.sync].each do |sync|
            get_path(sync)
            add_excludes(sync, excludes)
          end
          nil
        end

        def self.setup_listen_ignores(value)
          ignores  = (value.is_a?(Array) and !value.empty?) ? value : DOA::Sync::DEFAULT_IGNORES
          [DOA::Host.sync, DOA::Guest.sync].each do |sync|
            get_path(sync)
            from_escaped = @path[:from].gsub('/', '\/')
            sync.ignores.push(*(ignores.map { |pattern| "#{ from_escaped }\\/#{ pattern }" }))
          end
          nil
        end

        def self.add_excludes(sync, excludes = [])
          if sync.presync[:dirs].has_key?(DOA::SSH.escape(sync.from.os, @path[:from], true))
            sync.presync[:dirs][DOA::SSH.escape(sync.from.os, @path[:from], true)][:exclude].push(*excludes)
          else
            sync.presync[:dirs][DOA::SSH.escape(sync.from.os, @path[:from], true)] = {
              :to       => DOA::SSH.escape(sync.to.os, @path[:to]),
              :exclude  => excludes,
            }
          end
          nil
        end

        def self.setup_assets(value, type = DOA::Setting::WP_ASSET_PLUGIN)
          assets = {}
          if value.is_a?(Hash) and !value.empty?
            asset_defaults = {
              'install'  => 'true',
              'activate' => 'true',
              'delete'   => nil,
              'version'  => nil,
            }
            #get_path(DOA::Guest.sync)
            value.each do |slug, config|
              slug_key = "'#{ slug }'"
              # Check allowed types/values
              ctx = [DOA::Guest.sh_header, DOA::Guest.hostname, DOA::Guest.provisioner.current_project, @label.downcase]
              ['install', 'activate', 'delete'].each do |param|
                if config.has_key?(param) and !DOA::Tools::valid_boolean?(config[param])
                  puts sprintf(DOA::L10n::UNSUPPORTED_PARAM_VALUE_CTX_SW, *(ctx + [param]).colorize(:red))
                  raise SystemExit
                end
              end

              # Prepare Hiera data
              assets[slug_key] = {
                'install'  => config.has_key?('install') ? config['install'].to_s : asset_defaults['install'],
                'activate' => config.has_key?('activate') ? config['activate'].to_s : asset_defaults['activate'],
                'delete'   => config.has_key?('delete') ? config['delete'].to_s : asset_defaults['delete'],
                'version'  => "'#{ config.has_key?('version') ? config['version'] : asset_defaults['version'] }'",
              }
              assets[slug_key].delete_if { |key, value| value.nil? }
            end

            # Load WP-CLI puppet class and install it for managing assets
            DOA::Provisioner::Puppet.enqueue_hiera_classes('wordpress::wpcli')

            # Set assets up depending upon machine (host/guest)
            [DOA::Host.sync, DOA::Guest.sync].each do |sync|
              get_path(sync)
              value.each do |asset, params|
                asset_path    = "#{ @path[:from] }/wp-content/#{ type }s/#{ asset }"
                asset_ignores = (params.has_key?('ignore') and params['ignore'].is_a?(Array) and !params['ignore'].empty?) ? params['ignore'] : []
                sync.ignores.push(*(asset_ignores.map { |pattern| "#{ asset_path }\\/#{ pattern }" })) if !params['ignore'].empty?
                asset_excludes = params.has_key?('exclude') ?
                  (params['exclude'].is_a?(Array) ? params['exclude'] :
                    ((params['exclude'].is_a?(String) and !params['exclude'].strip.empty?) ? [params['exclude'].strip] : [])) : []
                add_excludes(sync, (asset_excludes - DOA::Sync::DEFAULT_EXCLUDES).map { |pattern| "#{ asset }/#{ pattern }" }) if !asset_excludes.empty?
              end
            end
          end

          Provisioner::Puppet.enqueue_hiera_params(@label, {'wordpress::instances' => {
              "'#{ DOA::Guest.provisioner.current_project.nil? ? 'base' : DOA::Guest.provisioner.current_project }'" => {
                "wp_#{ type }s" => assets
            }}}) if !assets.empty?
          nil
        end
      end
    end
  end
end
