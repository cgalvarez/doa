#!/usr/bin/ruby

require 'singleton'
require_relative 'puppet/couchdb'
require_relative 'puppet/meteor'
require_relative 'puppet/php'

module DOA
  module Provisioner
    class Puppet
      include Singleton

      # Constants
      TYPE             = 'puppet'
      OS_FAMILY        = 'os_family'
      OS_DISTRO        = 'os_distro'
      OS_DISTRO_VER    = 'os_distro_ver'
      PPA_DEFAULTS     = {
        'architecture' => '"%{::architecture}"',
        'release'      => '"%{::lsbdistcodename}"',
        'repos'        => "'main'",
        'key'          => {'server'     => "'keyserver.ubuntu.com'"},
        'pin'          => "'700'",
      }

      CONFDIR = '/etc/puppetlabs/puppet'
      MODS_PATH_3RD_PARTY = "#{ CONFDIR }/modules"
      MODS_PATH_CUSTOM = "#{ DOA::Guest::PROVISION }/modules"
      HIERA_DATA_DIR = "#{ DOA::Guest::PROVISION }/hiera"
      MANIFESTS_DIR = "#{ DOA::Guest::PROVISION }/manifests"

      # 3rd party puppet modules
      PUPPET_FORGE_ID_GLUE = '/'
      PUPPET_FORGE_MOD_APT = 'puppetlabs/apt'

      # Class variables
      @@sw_stack        = {}
      @@puppetfile_mods = {}
      @@hiera_classes   = {}
      @@relationships   = {}
      @@current_site    = nil
      @@current_sw      = nil

      # Getters
      def self.current_site
        @@current_site
      end
      def self.sw_stack
        @@sw_stack
      end

      # Adds the provided classes to the list of classes automatically loaded
      # through Puppet Hiera.
      # +classes+:: array of strings with the name of the classes to load with Hiera
      def self.enqueue_hiera_classes(classes)
        # +classes+: wrong type
        if !classes.is_a?(Array)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_site, @@current_sw, 'classes', 'Array', 'Puppet#enqueue_hiera_classes').colorize(:red)
          raise SystemExit
        else
          classes.each do |class_name|
            # +classes+: malformed (values of wrong type)
            if !class_name.is_a?(String)
              puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                @@current_site, @@current_sw, 'classes', 'Puppet#enqueue_hiera_classes').colorize(:red)
              raise SystemExit
            end
            @@hiera_classes[class_name] = true if !@@hiera_classes.has_key?(class_name)
          end
        end
      end

      # Adds the provided modules to the list of external modules automatically
      # managed my librarian-puppet from Puppet Forge.
      # +mods+:: array of strings with the Puppet Forge identifiers of the modules to manage with librarian-puppet
      def self.enqueue_puppetfile_mods(mods)
        # +mods+: wrong type
        if !mods.is_a?(Array)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_site, @@current_sw, 'mods', 'Array', 'Puppet#enqueue_puppetfile_mods').colorize(:red)
          raise SystemExit
        else
          mods.each do |mod|
            # +mods+: malformed (values of wrong type)
            if !mod.is_a?(String) || !mod.include?(PUPPET_FORGE_ID_GLUE)
              puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                @@current_site, @@current_sw, 'mods', 'Puppet#enqueue_puppetfile_mods').colorize(:red)
              raise SystemExit
            end
            @@puppetfile_mods[mod] = true if !@@puppetfile_mods.has_key?(mod)
          end
        end
      end

      # Adds the provided APT repositories (Debian Linux family) to the list of
      # repositories automatically managed with Puppet Hiera.
      # +label+:: string with the name to assign to the repository
      # +settings+:: hash with the requested settings for setting the repository up (required keys {ensure|comment|location|key|before}
      # +relationships+:: hash with the requested relationships; see Puppet#enqueue_relationship
      def self.enqueue_repo_apt(label, settings, relationships = nil)
        # +label+: wrong type
        if !label.is_a?(String)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_site, @@current_sw, 'label', 'String', 'Puppet#enqueue_repo_apt').colorize(:red)
          raise SystemExit
        # +settings+: wrong type
        elsif !settings.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_site, @@current_sw, 'settings', 'Hash', 'Puppet#enqueue_repo_apt').colorize(:red)
          raise SystemExit
        # +settings+: missing required keys or values of wrong type
        elsif !settings.has_key?('ensure') || !settings['ensure'].is_a?(String) ||
            !settings.has_key?('comment') || !settings['comment'].is_a?(String) ||
            !settings.has_key?('location') || !settings['location'].is_a?(String) ||
            !settings.has_key?('key') || !settings['key'].is_a?(Hash) ||
            !settings['key'].has_key?('id') || !settings['key']['id'].is_a?(String)
          puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_SITE, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_site, @@current_sw, 'settings', 'Puppet#enqueue_repo_apt').colorize(:red)
          raise SystemExit
        # +relationships+: wrong type
        elsif !relationships.nil? and !relationships.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header,
            DOA::Guest.hostname, @@current_site, @@current_sw, 'relationships', 'Hash').colorize(:red)
          raise SystemExit
        # Enqueue module parameters for Hiera
        else
          pkg_mngr = 'apt'
          escaped_label = label.gsub('.', '_')
          @@puppetfile_mods[PUPPET_FORGE_MOD_APT] = true if !@@puppetfile_mods.has_key?(PUPPET_FORGE_MOD_APT)
          @@hiera_classes[PUPPET_FORGE_MOD_APT] = false if !@@hiera_classes.has_key?(PUPPET_FORGE_MOD_APT)
          @@sw_stack[pkg_mngr] = {} if !@@sw_stack.has_key?(pkg_mngr)
          @@sw_stack[pkg_mngr]['sources'] = {} if !@@sw_stack[pkg_mngr].has_key?('sources')
          @@sw_stack[pkg_mngr]['sources']["'#{ escaped_label }'"] = PPA_DEFAULTS.deep_merge(settings)
          enqueue_relationship("Apt::Source['#{ escaped_label }']", relationships) if !relationships.nil? and !relationships.empty?
        end
      end

      # Generates and adds the chaining arrows for the requested relationships.
      # +source+:: source reference (the +relationships+ values are the targets)
      # +relationships+:: hash of strings with the requested relationships; Possible keys: {before|require|notify|subcribe}
      def self.enqueue_relationship(source, relationships)
        # Set the appropriate relationships through chaining arrows when requested
        if !relationships.nil? and !relationships.empty?
          relationships.each do |relationship, target|
            # +relationships+: malformed (values of wrong type)
            if !target.is_a?(String)
              puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                @@current_site, @@current_sw, 'relationships', 'Puppet#enqueue_relationship').colorize(:red)
              raise SystemExit
            end
            chaining =
              case relationship
              when 'before' then "#{ source } -> #{ target }"
              when 'require' then "#{ target } -> #{ source }"
              when 'notify' then "#{ source } ~> #{ target }"
              when 'subcribe' then "#{ target } ~> #{ source }"
              else ''
              end
            # +relationships+: malformed (disallowed keys)
            if chaining.empty?
              puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                @@current_site, @@current_sw, 'relationships', 'Puppet#enqueue_relationship').colorize(:red)
              raise SystemExit
            else
              @@relationships[chaining] = true if !@@relationships.has_key?(chaining)
            end
          end
        end
      end

      # Creates the puppet files needed for provisioning the guest machine according to the YAML settings.
      def self.setup_provision()
        # Initialize all class variables
        @@puppetfile_mods, @@sw_stack, @@hiera_classes, @@relationships = {}, {}, {}, {}

        printf(DOA::L10n::SETTING_UP_PROVISIONER, DOA::Guest.sh_header, TYPE, DOA::Guest.hostname)
        sites = DOA::Tools.check_get(DOA::Guest.settings, DOA::Tools::TYPE_HASH,
          [DOA::Guest.hostname, DOA::Guest.hostname], Setting::SITES)

        # LOOP sites
        sites.each do |site, site_settings|
          @@current_site  = site
          stack = DOA::Tools.check_get(site_settings, DOA::Tools::TYPE_HASH,
            [DOA::Guest.hostname, @@current_site, Setting::SITE_STACK], Setting::SITE_STACK, {})

          # LOOP software stack
          stack.each do |sw, sw_settings|
            @@current_sw = sw
            @@sw_stack[sw] = {}
            sw_mod =
              case sw
              when Setting::SW_COUCHDB then 'CouchDB'
              when Setting::SW_METEOR then 'Meteor'
              when Setting::SW_PHP then 'PHP'
              end
            if Puppet.const_defined?(sw_mod) and Puppet.const_get(sw_mod).respond_to?('setup')
              Puppet.const_get(sw_mod).send('setup', sw_settings)
            else
              puts sprintf(DOA::L10n::UNSUPPORTED_SW, DOA::Guest.sh_header,
                DOA::Guest.hostname, @@current_site, sw).colorize(:red)
              raise SystemExit
            end
          end
        end

        # Create directories and generic command
        local_puppet = "#{ DOA::Guest::HOME }/.puppetlabs/etc/puppet"
        DOA::Guest.ssh([
          "sudo mkdir -p #{ DOA::Guest::PROVISION }/config",
          "sudo mkdir -p #{ DOA::Guest::PROVISION }/files",   # Synced custom DOA files
          "sudo mkdir -p #{ DOA::Guest::PROVISION }/modules", # Synced custom DOA modules
          "sudo mkdir -p #{ HIERA_DATA_DIR }",
          "sudo mkdir -p #{ MANIFESTS_DIR }",
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

        ssh_cmds = []
        provision_files.each do |host_temp_path, settings|
          # Set file contents
          puppet_file = File.open(host_temp_path, 'w')
          puppet_file << ERB.new(File.read(settings['host_template'])).result(binding)
          puppet_file.close
          # Copy file into a temporary location inside the guest machine
          DOA::Guest.scp(host_temp_path, settings['guest_temp'])
          # Move the file into its final location inside the guest machine
          ssh_cmds.insert(-1, "sudo mv -f #{ settings['guest_temp'] } #{ settings['guest_final'] }")
        end
        # Execute the remote commands
        DOA::Guest.ssh(ssh_cmds)

        # Set the appropriate permissions and ownership
        DOA::Guest.ssh([
          "sudo chown -R root:root #{ DOA::Guest::PROVISION }",
          "sudo find #{ DOA::Guest::PROVISION } -type d -exec chmod 755 {} ';'",
          "sudo find #{ DOA::Guest::PROVISION } -type f -exec chmod 644 {} ';'",
          "sudo chown root:root #{ DOA::Guest.session.papply }",
          "sudo chmod 755 #{ DOA::Guest.session.papply }",
          "sudo ln -fs #{ DOA::Guest.session.puppet_conf } #{ local_puppet }/puppet.conf",
        ])
        puts DOA::L10n::SUCCESS_OK

        printf(DOA::L10n::PROVISIONING_STACK, DOA::Guest.sh_header, DOA::Guest.hostname, TYPE)
        DOA::Guest.ssh([
          "cd #{ CONFDIR }",
          #"sudo r10k puppetfile install",    # Download the 3rd party modules into the guest machine
          "sudo librarian-puppet update",     # Download the 3rd party modules (and their deps) into the guest machine
          "papply",                           # Execute provisioning
        ])
        puts DOA::L10n::SUCCESS_OK
      end

      # Returns some info about the guest machine, retrieved through Puppet Facter.
      # +param+:: info to retrieve. Possible values: {OS_FAMILY|OS_DISTRO|OS_DISTRO_VER}
      def self.os_info(param)
        fact =
          case param
          when OS_FAMILY then 'osfamily'
          when OS_DISTRO then 'lsbdistid'
          when OS_DISTRO_VER then 'lsbdistcodename'
          else nil
          end
        req_info = DOA::Guest.send(param)
        if req_info.nil?
          req_info =
            case DOA::Guest.os
            when DOA::OS::LINUX then SSH.ssh_capture(DOA::Env.guest_insecure_ppk, DOA::Guest.user,
              DOA::Host.os, DOA::Guest.ssh_address, DOA::Guest.os, ["facter #{ fact }"]).strip.downcase
            else nil
            end
          DOA::Guest.send("set_#{ param }", req_info) if !req_info.nil?
        end
        return req_info
      end
    end
  end
end
