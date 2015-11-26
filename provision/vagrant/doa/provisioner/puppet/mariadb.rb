#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class MariaDB < PuppetModule
        # Constants.
        MOD_CGALVAREZ_MARIADB = 'cgalvarez/mariadb'
        NODE_TYPE_CLUSTER = 'cluster'
        NODE_TYPE_SERVER  = 'server'
        ALLOWED_BRANCHES = {
          NODE_TYPE_SERVER  => ['5.5', '10.0', '10.1'],
          NODE_TYPE_CLUSTER => ['5.5', '10.0'],
        }
        NODE_CHILDREN = {
          NODE_TYPE_SERVER  => ['client', 'server'],
          NODE_TYPE_CLUSTER => ['client', 'server', 'galera'],
        }
        HIERA_CLASSES = {
          NODE_TYPE_SERVER  => 'mariadb::server',
          NODE_TYPE_CLUSTER => 'mariadb::cluster',
        }

        # Class variables.
        @req_branches = []
        @label        = 'MariaDB'
        @librarian    = {
          MOD_CGALVAREZ_MARIADB => {
            :git  => 'git://github.com/cgalvarez/puppet-mariadb.git',
            #:ver  => '1.0.0',
          },
        }
        @supported = {
            'mirror' => {
              :expect  => :url,
              :maps_to => "mariadb::mirror",
              :mod_def => 'http://ftp.osuosl.org/pub/mariadb',
              :doa_def => {
                :dev   => 'http://ftp.osuosl.org/pub/mariadb',
                :test  => 'http://ftp.osuosl.org/pub/mariadb',
                :prod  => 'http://ftp.osuosl.org/pub/mariadb',
              },
            },
            'server' => {
              :exclude    => ['cluster'],
              :cb_process => "#{ self.to_s }#include_hieraclass@server",
              :children   => {
                'version' => {
                  :exclude    => ['server->client->version', 'server->server->version'],
                  :expect     => [:semver_version, :semver_branch],
                  :cb_process => "#{ self.to_s }#process_param@version,server",
                  :mod_def    => '',
                  :doa_def    => {
                    :dev      => '10.1',
                    :test     => '10.1',
                    :prod     => '10.0',
                  },
                },
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :cb_process => "#{ self.to_s }#process_param@ensure,server",
                  :mod_def    => 'present',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
                # server -> client
                'client' => {
                  :children => {
                    'version' => {
                      :exclude    => ['server->version'],
                      :expect     => [:semver_version, :semver_branch],
                      :maps_to    => 'mariadb::server::client_package_version',
                      :cb_process => "#{ self.to_s }#process_param@version,server->client",
                      :mod_def    => '',
                      :doa_def    => {
                        :dev      => '10.1',
                        :test     => '10.1',
                        :prod     => '10.0',
                      },
                    },
                    'ensure' => {
                      :exclude    => ['server->ensure'],
                      :expect     => [:string],
                      :maps_to    => 'mariadb::server::client_package_ensure',
                      :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                      :cb_process => "#{ self.to_s }#process_param@ensure,server->client",
                      :mod_def    => 'present',
                      :doa_def    => {
                        :dev      => 'latest',
                        :test     => 'latest',
                        :prod     => 'present',
                      },
                    },
                  },
                },
                # server -> server
                'server' => {
                  :children => {
                    'version' => {
                      :exclude    => ['server->version'],
                      :expect     => [:semver_version, :semver_branch],
                      :maps_to    => 'mariadb::server::package_version',
                      :cb_process => "#{ self.to_s }#process_param@version,server->server",
                      :mod_def    => '',
                      :doa_def    => {
                        :dev      => '10.1',
                        :test     => '10.1',
                        :prod     => '10.0',
                      },
                    },
                    'ensure' => {
                      :exclude    => ['server->ensure'],
                      :expect     => [:string],
                      :maps_to    => 'mariadb::server::package_ensure',
                      :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                      :cb_process => "#{ self.to_s }#process_param@ensure,server->server",
                      :mod_def    => 'present',
                      :doa_def    => {
                        :dev      => 'latest',
                        :test     => 'latest',
                        :prod     => 'present',
                      },
                    },
                  },
                },
              },
            },
            'cluster' => {
              :exclude  => ['server'],
              :children => {
                'version' => {
                  :expect     => [:semver_version, :semver_branch],
                  :cb_process => "#{ self.to_s }#process_param@version,cluster",
                  :mod_def    => '',
                  :doa_def    => {
                    :dev      => '10.0',
                    :test     => '10.0',
                    :prod     => '10.0',
                  },
                },
                'ensure' => {
                  :expect     => [:string],
                  :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                  :cb_process => "#{ self.to_s }#process_param@ensure,cluster",
                  :mod_def    => 'present',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
                # cluster -> client
                'client' => {
                  :children => {
                    'version' => {
                      :exclude    => ['cluster->version'],
                      :expect     => [:semver_version, :semver_branch],
                      :maps_to    => 'mariadb::galera::client_package_version',
                      :cb_process => "#{ self.to_s }#process_param@version,cluster->client",
                      :mod_def    => '',
                      :doa_def    => {
                        :dev      => '10.1',
                        :test     => '10.1',
                        :prod     => '10.0',
                      },
                    },
                    'ensure' => {
                      :exclude    => ['cluster->ensure'],
                      :expect     => [:string],
                      :maps_to    => 'mariadb::galera::client_package_ensure',
                      :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                      :cb_process => "#{ self.to_s }#process_param@ensure,cluster->client",
                      :mod_def    => 'present',
                      :doa_def    => {
                        :dev      => 'latest',
                        :test     => 'latest',
                        :prod     => 'present',
                      },
                    },
                  },
                },
                # cluster -> server
                'server' => {
                  :children => {
                    'version' => {
                      :exclude    => ['cluster->version'],
                      :expect     => [:semver_version, :semver_branch],
                      :maps_to    => 'mariadb::galera::package_version',
                      :cb_process => "#{ self.to_s }#process_param@version,cluster->server",
                      :mod_def    => '',
                      :doa_def    => {
                        :dev      => '10.1',
                        :test     => '10.1',
                        :prod     => '10.0',
                      },
                    },
                    'ensure' => {
                      :exclude    => ['cluster->ensure'],
                      :expect     => [:string],
                      :maps_to    => 'mariadb::galera::package_ensure',
                      :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                      :cb_process => "#{ self.to_s }#process_param@ensure,cluster->server",
                      :mod_def    => 'present',
                      :doa_def    => {
                        :dev      => 'latest',
                        :test     => 'latest',
                        :prod     => 'present',
                      },
                    },
                  },
                },
                # cluster -> galera
                'galera' => {
                  :children => {
                    'version' => {
                      :exclude    => ['cluster->version'],
                      :expect     => [:semver_version, :semver_branch],
                      :maps_to    => 'mariadb::galera::galera_version',
                      :cb_process => "#{ self.to_s }#process_param@version,cluster->galera",
                      :mod_def    => '',
                      :doa_def    => {
                        :dev      => '10.1',
                        :test     => '10.1',
                        :prod     => '10.0',
                      },
                    },
                    'ensure' => {
                      :exclude    => ['cluster->ensure'],
                      :expect     => [:string],
                      :maps_to    => 'mariadb::galera::galera_ensure',
                      :allow      => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
                      :cb_process => "#{ self.to_s }#process_param@ensure,cluster->galera",
                      :mod_def    => 'present',
                      :doa_def    => {
                        :dev      => 'latest',
                        :test     => 'latest',
                        :prod     => 'present',
                      },
                    },
                  },
                },
              },
            },
          }

        def self.custom_setup(provided)
          #Puppet.enqueue_relationship("Class['#{ MOD_CGALVAREZ_MARIADB }']", {'before' => "Class['#{ PHP.label }']"}) if Puppet.current_stack.has_key?(PHP.label)

          # Configure swap file when low available memory
          if DOA::Guest.mem < 1024
            Puppet.enqueue_puppetfile_mods(['petems/swap_file'])
            Puppet.enqueue_relationship("Swap_file::Files['mariadb_swapfile']", {'before' => "Class['#{ PF_MOD_MAIN_CLASS }']"})
            Puppet.enqueue_site_content("
# Swap file (required to install & run MariaDB on machines with less than 1GB memory)
swap_file::files { 'mariadb_swapfile':
  ensure        => 'present',
  swapfile      => '/mnt/mariadb_swapfile',
  swapfilesize  => '256000000',
}")
          end
        end

        def self.process_param(value, param, parent = NODE_TYPE_SERVER)
          if NODE_CHILDREN.has_key?(parent)
            # Set the version for all children parameters
            NODE_CHILDREN[parent].each do |child|
              @provided[parent][child] = {} if !@provided[parent].has_key?(child)
              @provided[parent][child][param] = value
            end
          end

          # Get branch and version, and check ensure
          if param == 'version'
            # Branch family (.x)
            if Tools::valid_version?(value, [], [], false, true)
              @branch = value.gsub(/\.[xX]/, '')
              @branch = case @branch
                when '5.5', '10.0', '10.1' then @branch
                when '10' then '10.0'
                when '5' then '5.5'
                else nil
                end
              if @branch.nil?
                tag = case parent
                  when NODE_TYPE_SERVER then 'MariaDB Server'
                  when NODE_TYPE_CLUSTER then 'MariaDB Galera Cluster'
                  end
                puts sprintf(DOA::L10n::MARIADB_NO_SUPPORT, DOA::Guest.sh_header, DOA::Guest.hostname,
                  DOA::Guest.provisioner.current_project, @label.downcase, tag, value).colorize(:red)
                raise SystemExit
              end
            # Specific version
            elsif Tools::valid_version?(value, [], [], true, false)
              @branch  = value.match(Tools::RGX_SEMVER_MINOR).captures[0]
              @version = value.match(Tools::RGX_SEMVER).captures[0]

              # ensure cannot be 'latest' when specific version provided
              parent_cfg, keys = @provided, parent.split(GLUE_KEYS)
              keys.each do |key|
                parent_cfg = parent_cfg[key]
              end
              if !parent_cfg.has_key?('ensure')
                @provided.recursive_set!(keys.push('ensure'), 'present')
              elsif parent_cfg['ensure'] == 'latest'
                puts sprintf(DOA::L10n::VERSION_INCOMP, DOA::Guest.sh_header, DOA::Guest.hostname,
                  DOA::Guest.provisioner.current_project, @label.downcase, 'ensure', 'latest').colorize(:red)
                raise SystemExit
              end
            # Allowed branch
            elsif !value.nil? and ALLOWED_BRANCHES.has_key?(parent) and ALLOWED_BRANCHES[parent].include?(value)
              @branch = value
            end
            @branch = '10.0' if @branch.nil?  # Default branch

            # All involved items must belong to the same branch
            if @req_branches.empty?
              @req_branches.insert(-1, @branch)
            elsif !@req_branches.include?(@branch)
              puts sprintf(DOA::L10n::BRANCH_INCOMP, DOA::Guest.sh_header, DOA::Guest.hostname,
                DOA::Guest.provisioner.current_project, @label.downcase).colorize(:red)
              raise SystemExit
            end

            # Set the repository branch according to the requested version/branch
            main_class = case parent
              when /^server(->)?/ then NODE_TYPE_SERVER
              when /^cluster(->)?/ then NODE_TYPE_CLUSTER
              else nil
              end
            if !main_class.nil?
              DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {"mariadb::#{ main_class }::repo_version" => "'#{ @branch }'"})
            end
          end

          if NODE_CHILDREN.has_key?(parent)
            # Remove the group parameter to avoid compatibility failure between parameters
            @provided[parent].except!(param)
            return nil
          else
            return value
          end
        end

        def self.include_hieraclass(value, node = NODE_TYPE_SERVER)
          DOA::Provisioner::Puppet.enqueue_hiera_classes("mariadb::#{ node }")
          nil
        end
      end
    end
  end
end
