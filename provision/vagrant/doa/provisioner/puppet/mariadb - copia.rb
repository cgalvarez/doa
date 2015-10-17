#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class MariaDB < PuppetModule
        # Constants.
        PF_MOD_CGALVAREZ_MARIADB = 'cgalvarez/mariadb'
        PF_MOD  = 'example42/mariadb'
        DOA_MOD = 'cgalvarez/mariadbrepo'
        PF_MOD_MAIN_CLASS  = 'mariadb'
        DOA_MOD_MAIN_CLASS = 'mariadbrepo'
        NODE_TYPE_CLUSTER = 'cluster'
        NOTE_TYPE_SERVER  = 'server'
        ALLOWED_BRANCHES = {
          NOTE_TYPE_SERVER  => ['5.5', '10.0', '10.1'],
          NODE_TYPE_CLUSTER => ['5.5', '10.0'],
        }

        # Class variables.
        # example42/mariadb => https://github.com/example42/puppet-mariadb
        @label        = 'MariaDB'
        @pfmods       = [PF_MOD_CGALVAREZ_MARIADB]
        @hieraclasses = @pfmods
        @supported = {
            'apt_mirror' => {
              :expect  => :url,
              :maps_to => "#{ DOA_MOD_MAIN_CLASS }::apt_mirror",
              :mod_def => 'http://ftp.osuosl.org/pub/mariadb',
              :doa_def => {
                :dev   => 'http://ftp.osuosl.org/pub/mariadb',
                :test  => 'http://ftp.osuosl.org/pub/mariadb',
                :prod  => 'http://ftp.osuosl.org/pub/mariadb',
              },
            },
            'server' => {
              :exclude  => ['cluster'],
              :children => {
                'version' => {
                  :expect     => [:semver_version, :semver_branch],
                  :cb_process => "DOA::Provisioner::Puppet::MariaDB#{ GLUE_METHOD }process_version",
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
                  :cb_process => "DOA::Provisioner::Puppet::MariaDB#{ GLUE_METHOD }process_ensure",
                  :mod_def    => 'present',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
              }
            },
            'cluster' => {
              :exclude  => ['server'],
              :children => {
                'version' => {
                  :expect     => [:semver_version, :semver_branch],
                  :cb_process => "DOA::Provisioner::Puppet::MariaDB#{ GLUE_METHOD }process_version#{ GLUE_PARAMS }#{ NODE_TYPE_CLUSTER }",
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
                  :cb_process => "DOA::Provisioner::Puppet::MariaDB#{ GLUE_METHOD }process_ensure#{ GLUE_PARAMS }#{ NODE_TYPE_CLUSTER }",
                  :mod_def    => 'present',
                  :doa_def    => {
                    :dev      => 'latest',
                    :test     => 'latest',
                    :prod     => 'present',
                  },
                },
              },
            },
            'repo_class' => {
              :expect    => [:semver_version, :semver_branch],
              :maps_to   => "#{ PF_MOD_MAIN_CLASS }::repo_class",
              :mod_def   => "#{ PF_MOD_MAIN_CLASS }::repo",
              :doa_def   => {
                :dev     => DOA_MOD_MAIN_CLASS,
                :test    => DOA_MOD_MAIN_CLASS,
                :prod    => DOA_MOD_MAIN_CLASS,
              },
            },
          }

        def self.custom_setup(settings)
          ###@provided = settings
          ###Puppet.enqueue_puppetfile_mods(['puppetlabs/apt', 'example42/stdmod', PF_MOD])
          ###Puppet.enqueue_hiera_classes([PF_MOD])
          Puppet.enqueue_relationship("Class['#{ DOA_MOD_MAIN_CLASS }']", {'before' => "Class['#{ PF_MOD_MAIN_CLASS }']"})
          Puppet.enqueue_relationship("Class['#{ PF_MOD_MAIN_CLASS }']", {'before' => "Class['#{ PHP.label }']"}) if Puppet.current_stack.has_key?(PHP.label)
          ###Puppet.enqueue_hiera_params(@label, set_params(SUPPORTED, (!settings.nil? and settings.is_a?(Hash)) ? settings : {})) if !SUPPORTED.empty?

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

        def self.process_version(value, node = NOTE_TYPE_SERVER)
          # Branch (with .x)
          if Tools::valid_version?(value, [], [], false, true)
            @branch = value.gsub(/\.[xX]/, '')
            @branch = case @branch
              when '10' then '10.0'
              when '5' then '5.5'
              else @branch
              end
          # Specific version
          elsif Tools::valid_version?(value, [], [], true, false)
            @branch = value.match(Tools::RGX_SEMVER_MINOR).captures[0]
          # :allow value
          else
            @branch = value
          end

          # Check support for provided branch
          if ALLOWED_BRANCHES[node].include?(@branch)
            # Specific versions or branch families automatically ensure 'held'
            @version = value.match(Tools::RGX_SEMVER).captures[0].gsub('X', 'x')
            @provided[node]['ensure'] = (@branch != @version) ? 'held' :
              SUPPORTED[node][:children]['ensure'][:doa_def][DOA::Guest.env]
            Puppet.enqueue_hiera_params(@label, {
              "#{ PF_MOD_MAIN_CLASS }::version" => "'#{ @branch }'",
              "#{ DOA_MOD_MAIN_CLASS }::branch" => "'#{ @branch }'",
            })
          else
            tag = case node
              when NOTE_TYPE_SERVER then 'MariaDB Server'
              when NODE_TYPE_CLUSTER then 'MariaDB Galera Cluster'
              end
            puts sprintf(DOA::L10n::MARIADB_NO_SUPPORT, DOA::Guest.sh_header, DOA::Guest.hostname,
              DOA::Guest.provisioner.current_site, @label.downcase, tag, value).colorize(:red)
            raise SystemExit
          end
        end

        def self.process_ensure(value, node = 'server')
          pkg = case node
            when 'server'  then 'mariadb-server'
            when 'cluster' then 'mariadb-galera-server'
            else nil
            end

          # Hold when specific version or branch (.x) provided
          if !pkg.nil?
            [pkg, "#{ pkg }-#{ @branch }", "#{ pkg }-core-#{ @branch }"].each do |pkg_name|
              Puppet.enqueue_apt_pin(pkg_name, {
                'packages' => "'#{ pkg_name }'",
                'version'  => @version != @branch ? "'#{ @version }'" : "'#{ @branch }.x'",
                'ensure'   => "'#{ value }'",
              }, {'before' => "Class['#{ PF_MOD_MAIN_CLASS }']"})
            end
          end

          # example42/mariadb and cgalvarez/mariadbrepo only allows {absent|present}
          repo_ensure = case value.to_s
            when 'present', 'installed', 'latest', 'held' then 'present'
            when 'absent', 'purged' then 'absent'
            else nil
            end
          Puppet.enqueue_hiera_params(@label, {
            "#{ PF_MOD_MAIN_CLASS }::package_ensure" => "'#{ repo_ensure }'",
            "#{ DOA_MOD_MAIN_CLASS }::ensure" => "'#{ repo_ensure }'",
          }) if !repo_ensure.nil?
        end
      end
    end
  end
end
