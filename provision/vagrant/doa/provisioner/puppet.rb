#!/usr/bin/ruby

require 'singleton'

module DOA
  module Provisioner
    class Puppet
      include Singleton

      # Constants.
      TYPE = 'puppet'
      VER_FORMAT_SEMVER   = 'semver'
      VER_FORMAT_FAMILY   = 'family'
      VER_FORMAT_KEYWORD  = 'keyword'
      VER_FORMAT_SUBSET   = 'set'
      VER_DEFAULT         = 'default'
      
      SEMVER_REGEX = /^(\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/
      #SEMVER_REGEX = /^((\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))|(\d+\.([0-9]+\.([0-9]+|[xX])|[xX])))?$/
      FAMILY_REGEX = /^((\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))|(\d+\.([0-9]+\.([0-9]+|[xX])|[xX])))?$/
      VERSION_KEYWORDS = ['latest', 'present', 'absent']
      CONFDIR = '/etc/puppetlabs/puppet'
      MODS_PATH_3RD_PARTY = "#{ Puppet::CONFDIR }/modules"
      MODS_PATH_CUSTOM = "#{ DOA::Guest::PROVISION }/modules"
      HIERA_DATA_DIR = "#{ DOA::Guest::PROVISION }/hiera"
      MANIFESTS_DIR = "#{ DOA::Guest::PROVISION }/manifests"

      # Puppet modules
      PUPPET_MOD_ARCHIVE    = 'camptocamp/archive'
      PUPPET_MOD_MARIADB    = 'example42/mariadb'
      PUPPET_MOD_NGINX      = 'jfryman/nginx'
      PUPPET_MOD_NTP        = 'puppetlabs/ntp'
      PUPPET_MOD_PHP        = 'mayflower/php'
      PUPPET_MOD_REPO       = 'puppetlabs/vcsrepo'
      PUPPET_MOD_STDLIB     = 'puppetlabs/stdlib'
      PUPPET_MOD_STDMOD     = 'example42/stdmod'
      PUPPET_MOD_SWAP       = 'petems/swap_file'
      PUPPET_MOD_WGET       = 'maestrodev/wget'
      PUPPET_MOD_WP         = 'hunner/wordpress'

      # Class variables
      @@ver_format = {
        Setting::SW_PHP               => {
          Puppet::VER_FORMAT_SEMVER   => true,
          Puppet::VER_FORMAT_FAMILY   => false,
          Puppet::VER_FORMAT_KEYWORD  => true,
          Puppet::VER_FORMAT_SUBSET   => [],
          Puppet::VER_DEFAULT         => 'latest',
        },
        Setting::SW_MARIADB           => {
          Puppet::VER_FORMAT_SEMVER   => false,
          Puppet::VER_FORMAT_FAMILY   => false,
          Puppet::VER_FORMAT_KEYWORD  => false,
          Puppet::VER_FORMAT_SUBSET   => ['5.5', '10.0'],
          Puppet::VER_DEFAULT         => '10.0',
        },
      }
      @@hiera_include = {
        PUPPET_MOD_ARCHIVE    => false,
        PUPPET_MOD_MARIADB    => true,
        PUPPET_MOD_NGINX      => false,
        PUPPET_MOD_NTP        => false,
        PUPPET_MOD_PHP        => true,
        PUPPET_MOD_REPO       => false,
        PUPPET_MOD_STDLIB     => false,
        PUPPET_MOD_STDMOD     => false,
        PUPPET_MOD_SWAP       => false,
        PUPPET_MOD_WGET       => false,
        PUPPET_MOD_WP         => false,
        
      }
      @@unlisted_deps = {
        Puppet::PUPPET_MOD_MARIADB  => [Puppet::PUPPET_MOD_STDMOD],
      }
      @@sw_stack = {}
      @@puppetfile_mods = {}

      # Creates the puppet files needed for provisioning the guest machine according to the YAML settings.
      def self.setup_puppet_provision()
        # Initialize all class variables
        @@puppetfile_mods, @@sw_stack = {}, {}
        
        printf(DOA::L10n::SETTING_UP_PROVISIONER, DOA::Guest.sh_header, Puppet::TYPE, DOA::Guest.hostname)
        settings = DOA::Guest.settings
        sites = DOA::Tools.check_get(settings, DOA::Tools::TYPE_HASH,
          [settings[Setting::HOSTNAME], settings[Setting::HOSTNAME]], Setting::SITES)
        sites.each do |site, site_settings|
          stack = DOA::Tools.check_get(site_settings, DOA::Tools::TYPE_HASH,
            [settings[Setting::HOSTNAME], site, Setting::SITE_STACK], Setting::SITE_STACK, {})
            
          stack.each do |sw, sw_settings|
            @@sw_stack[sw] = {}
            
            # Create a hash with the required external modules for Puppetfile generation
            case sw
            when Setting::SW_PHP
              @@puppetfile_mods[Puppet::PUPPET_MOD_PHP] = true if !@@puppetfile_mods.has_key?(Puppet::PUPPET_MOD_PHP)
            #when Setting::SW_MARIADB
            #  @@puppetfile_mods[Puppet::PUPPET_MOD_MARIADB] = true if !@@puppetfile_mods.has_key?(Puppet::PUPPET_MOD_MARIADB)
            #  @@puppetfile_mods[Puppet::PUPPET_MOD_SWAP] = true if DOA::Guest.mem < 1024 and !@@puppetfile_mods.has_key?(Puppet::PUPPET_MOD_SWAP)
            when Setting::SW_METEOR
            else
              puts sprintf(DOA::L10n::UNSUPPORTED_SW, DOA::Guest.sh_header,
                settings[Setting::HOSTNAME], site, sw).colorize(:red)
              raise SystemExit
            end
            
            # Check the format of the version when provided.
            # Allowed values for software version (depends on config of @@ver_format):
            #   - Specific version string (semantic versioning rules)
            #   - Version family (5.x, 3.2.x,...)
            #   - Reserved keyword: 'latest', 'present', 'absent'
            if @@ver_format.has_key?(sw)
              ver = DOA::Tools.check_get(sw_settings, DOA::Tools::TYPE_STRING,
                [settings[Setting::HOSTNAME], site, sw, Setting::SW_VERSION], Setting::SW_VERSION, @@ver_format[sw][Puppet::VER_DEFAULT])
              if (!@@ver_format[sw][Puppet::VER_FORMAT_SUBSET].empty? and @@ver_format[sw][Puppet::VER_FORMAT_SUBSET].include?(ver)) or
                    (@@ver_format[sw][Puppet::VER_FORMAT_KEYWORD] and Puppet::VERSION_KEYWORDS.include?(ver)) or
                    (@@ver_format[sw][Puppet::VER_FORMAT_FAMILY] and !(ver =~ Puppet::FAMILY_REGEX).nil?) or
                    (@@ver_format[sw][Puppet::VER_FORMAT_SEMVER] and !(ver =~ Puppet::SEMVER_REGEX).nil?)
                # SEMVER: https://github.com/jlindsey/semantic
                @@sw_stack[sw][Setting::SW_VERSION] = (@@sw_stack.has_key?(sw) and @@sw_stack[sw][Setting::SW_VERSION].is_a?(Array)) ?
                  @@sw_stack[sw][Setting::SW_VERSION].insert(-1, ver) : [ver]
              else
                puts ''
                puts sprintf(DOA::L10n::UNRECOGNIZED_VERSION, DOA::Guest.sh_header,
                  settings[Setting::HOSTNAME], site, sw, Setting::SW_VERSION).colorize(:red)
                raise SystemExit
              end
            end
          end
          
          # Add dependencies not included in the module's metadata.json
          @@unlisted_deps.each do |mod, deps|
            if @@puppetfile_mods.has_key?(mod)
              deps.each do |dep|
                @@puppetfile_mods[dep] = true if !@@puppetfile_mods.has_key?(dep)
              end
            end
          end
        end

        # Create directories and generic command
        local_puppet = "#{ DOA::Guest::HOME }/.puppetlabs/etc/puppet"
        DOA::Guest.ssh([
          "sudo mkdir -p #{ DOA::Guest::PROVISION }/config",
          "sudo mkdir -p #{ DOA::Guest::PROVISION }/files",        # For syncing custom DOA files
          "sudo mkdir -p #{ DOA::Guest::PROVISION }/modules",      # For syncing custom DOA modules
          "sudo mkdir -p #{ DOA::Provisioner::Puppet::HIERA_DATA_DIR }",
          "sudo mkdir -p #{ DOA::Provisioner::Puppet::MANIFESTS_DIR }",
          "sudo mkdir -p #{ local_puppet }",
        ])

        # Set the contents of puppet files for provisioning to work
        provision_files = {
          DOA::Host.session.guest_papply => {
            'host_template' => DOA::Templates::papply,
            'guest_temp'    => DOA::Guest.session.tmp_papply,
            'guest_final'   => DOA::Guest.session.papply,
          },
          DOA::Host.session.guest_puppet_conf => {
            'host_template' => DOA::Templates::puppet_conf,
            'guest_temp'    => DOA::Guest.session.tmp_puppet_conf,
            'guest_final'   => DOA::Guest.session.puppet_conf,
          },
          DOA::Host.session.guest_puppetfile => {
            'host_template' => DOA::Templates::puppetfile,
            'guest_temp'    => DOA::Guest.session.tmp_puppetfile,
            'guest_final'   => DOA::Guest.session.puppetfile,
          },
          DOA::Host.session.guest_common_yaml => {
            'host_template' => DOA::Templates::common_yaml,
            'guest_temp'    => DOA::Guest.session.tmp_common_yaml,
            'guest_final'   => DOA::Guest.session.common_yaml,
          },
          DOA::Host.session.guest_hostname_yaml => {
            'host_template' => DOA::Templates::hostname_yaml,
            'guest_temp'    => DOA::Guest.session.tmp_hostname_yaml,
            'guest_final'   => DOA::Guest.session.hostname_yaml,
          },
          DOA::Host.session.guest_hiera_yaml => {
            'host_template' => DOA::Templates::hiera_yaml,
            'guest_temp'    => DOA::Guest.session.tmp_hiera_yaml,
            'guest_final'   => DOA::Guest.session.hiera_yaml,
          },
          DOA::Host.session.guest_site_pp => {
            'host_template' => DOA::Templates::site_pp,
            'guest_temp'    => DOA::Guest.session.tmp_site_pp,
            'guest_final'   => DOA::Guest.session.site_pp,
          },
        }
        provision_files.each do |host_temp_path, settings|
          # Set file contents
          puppet_file = File.open(host_temp_path, 'w')
          puppet_file << ERB.new(File.read(settings['host_template'])).result(binding)
          puppet_file.close
          # Copy file into a temporary location inside the guest machine
          DOA::Guest.scp(host_temp_path, settings['guest_temp'])
          # Move the file into its final location inside the guest machine
          DOA::Guest.ssh(["sudo mv -f #{ settings['guest_temp'] } #{ settings['guest_final'] }"])
        end

        # Set the appropriate permissions and ownership
        DOA::Guest.ssh([
          "sudo chown -R root:root #{ DOA::Guest::PROVISION }",
          "sudo find #{ DOA::Guest::PROVISION } -type d -exec chmod 755 {} ';'",
          "sudo find #{ DOA::Guest::PROVISION } -type f -exec chmod 644 {} ';'",
          "sudo chown root:root #{ DOA::Guest.session.papply }",
          "sudo chmod 755 #{ DOA::Guest.session.papply }",
          "sudo ln -fs #{ DOA::Guest.session.puppet_conf } #{ local_puppet }/puppet.conf",
          #"sudo chown -R #{ DOA::Guest::USER }:#{ DOA::Guest::USER } #{ DOA::Guest::HOME }/.puppetlabs",
        ])
        puts DOA::L10n::SUCCESS_OK

        printf(DOA::L10n::PROVISIONING_STACK, DOA::Guest.sh_header, settings[Setting::HOSTNAME], Puppet::TYPE)
        DOA::Guest.ssh([
          "cd #{ DOA::Provisioner::Puppet::CONFDIR }",
          #"sudo r10k puppetfile install",    # Download the 3rd party modules into the guest machine
          "sudo librarian-puppet update",     # Download the 3rd party modules (and their deps) into the guest machine
          "papply",                           # Execute provisioning
        ])
        puts DOA::L10n::SUCCESS_OK

        # TODO: RSYNC host->guest custom modules & files
      end
    end
  end
end
