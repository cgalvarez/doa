#!/usr/bin/ruby

require 'singleton'
require_relative 'puppet/couchdb'
require_relative 'puppet/mariadb'
require_relative 'puppet/meteor'
require_relative 'puppet/nginx'
require_relative 'puppet/php'
require_relative 'puppet/wordpress'

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
        'key'          => {'server' => "'keyserver.ubuntu.com'"},
      }
      LIBRARIAN_MAP = {
          :git  => :git,
          :path => :path,
          :ref  => :ref,
          :tar  => :github_tarball,
          :ver  => nil,
      }

      CONFDIR = '/etc/puppetlabs/puppet'
      MODS_PATH_3RD_PARTY = "#{ CONFDIR }/modules"
      MODS_PATH_CUSTOM = "#{ DOA::Guest::PROVISION }/modules"
      HIERA_DATA_DIR = "#{ DOA::Guest::PROVISION }/hiera"
      MANIFESTS_DIR = "#{ DOA::Guest::PROVISION }/manifests"

      # 3rd party puppet modules
      PF_ID_GLUE   = '/'
      PF_RES_GLUE  = '::'
      PF_MOD_APT   = 'puppetlabs/apt'
      DOA_MOD_APT  = 'cgalvarez/apthelper'

      # Class variables
      @@api             = 'forgeapi'
      @@projects        = {}
      @@sw_stack        = {}
      @@puppetfile_mods = {}
      @@hiera_classes   = {}
      @@relationships   = {}
      @@site_content    = []
      @@current_project = nil
      @@current_sw      = nil
      @@current_stack   = nil
      @@os_family       = nil
      @@os_distro       = nil
      @@os_distro_ver   = nil

      # Getters
      def self.projects
        @@projects
      end
      def self.current_project
        @@current_project
      end
      def current_project
        @@current_project
      end
      def self.sw_stack
        @@sw_stack
      end
      def current_stack
        @@current_stack
      end
      def self.current_stack
        @@current_stack
      end
      def current_sw
        @@current_sw
      end
      def self.current_sw
        @@current_sw
      end
      def self.os_family
        @@os_family
      end
      def self.os_distro
        @@os_distro
      end
      def self.os_distro_ver
        @@os_distro_ver
      end

      # Creates the puppet files needed for provisioning the guest machine according to the YAML settings.
      def self.setup_provision()
        # Initialize all class variables
        @@puppetfile_mods, @@sw_stack, @@hiera_classes, @@relationships = {}, {}, {}, {}
        @@current_project, @@current_sw, @@current_stack = nil, nil, nil
        @@os_family, @@os_distro, @@os_distro_ver = os_info(OS_FAMILY), os_info(OS_DISTRO), os_info(OS_DISTRO_VER)
        ruby_ver = SSH.ssh_capture(DOA::Env.guest_insecure_ppk, DOA::Guest.user,
          DOA::Host.os, DOA::Guest.ssh_address, DOA::Guest.os, ["ruby -e 'print RUBY_VERSION'"]).strip.downcase
        @@api = ruby_ver =~ /\A1\.8\.[0-9]+\z/ ? 'forge' : 'forgeapi'

        printf(DOA::L10n::SETTING_UP_PROVISIONER, DOA::Guest.sh_header, TYPE, DOA::Guest.hostname)
        @@projects = DOA::Tools.check_get(DOA::Guest.settings, DOA::Tools::TYPE_HASH,
          [DOA::Guest.hostname, DOA::Guest.hostname], DOA::Setting::PROJECTS)

        # Queue all provided stacks
        stacks = [
          {
            :vm    => DOA::Guest.hostname,
            :proj  => nil,
            :stack => DOA::Tools.check_get(DOA::Guest.settings, DOA::Tools::TYPE_HASH,
              [DOA::Guest.hostname, DOA::Guest.hostname], DOA::Setting::VM_STACK, {}),
          }
        ]
        projects.each do |project, project_settings|
          stacks.insert(-1, {
              :vm    => DOA::Guest.hostname,
              :proj  => project,
              :stack => DOA::Tools.check_get(project_settings, DOA::Tools::TYPE_HASH,
                [DOA::Guest.hostname, @@current_project, DOA::Setting::PROJECT_STACK], DOA::Setting::PROJECT_STACK, {}),
            }
          )
        end

        # Provision machine
        stacks.each do |config|
          @@current_project, @@current_stack = config[:proj], config[:stack]
          config[:stack].each do |sw, sw_settings|
            @@current_sw = sw
            sw_mod =
              case sw
              when DOA::Setting::SW_COUCHDB then 'CouchDB'
              when DOA::Setting::SW_MARIADB then 'MariaDB'
              when DOA::Setting::SW_METEOR then 'Meteor'
              when DOA::Setting::SW_NGINX then 'Nginx'
              when DOA::Setting::SW_PHP then 'PHP'
              when DOA::Setting::SW_WP then DOA::Setting::PM_WP
              end
            if DOA::Provisioner::Puppet.const_defined?(sw_mod) and (subclass = DOA::Provisioner::Puppet.const_get(sw_mod)).is_a?(Class) and
                subclass < PuppetModule and subclass.respond_to?('setup')
              subclass.send('setup', sw_settings)
            else
              puts sprintf(DOA::L10n::UNSUPPORTED_SW, DOA::Guest.sh_header,
                config[:vm], config[:proj], sw).colorize(:red)
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
          'sudo librarian-puppet update',     # Download the 3rd party modules (and their deps) into the guest machine
          'papply',                           # Execute provisioning
        ])
        #puts DOA::L10n::SUCCESS_OK
        puts "[FIX]"
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
            when DOA::OS::LINUX then DOA::SSH.ssh_capture(DOA::Env.guest_insecure_ppk, DOA::Guest.user,
              DOA::Host.os, DOA::Guest.ssh_address, DOA::Guest.os, ["facter #{ fact }"]).strip.downcase
            else nil
            end
          DOA::Guest.send("set_#{ param }", req_info) if !req_info.nil?
        end
        return req_info
      end

      # Adds the provided classes to the list of classes automatically loaded
      # through Puppet Hiera.
      # +classes+:: array of strings with the name of the classes to load with Hiera
      def self.enqueue_hiera_classes(classes)
        classes = [classes] if !classes.is_a?(Array)
          classes.each do |class_name|
            # +classes+: malformed (values of wrong type)
            if !class_name.is_a?(String)
              puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                @@current_project, @@current_sw, 'classes', 'Puppet#enqueue_hiera_classes').colorize(:red)
              raise SystemExit
            end
            @@hiera_classes[class_name] = true if !@@hiera_classes.has_key?(class_name)
          end
        ###end
      end

      # Adds the provided modules to the list of external modules automatically
      # managed my librarian-puppet.
      # +mods+:: hash with module ID and its settings for it to be managed by librarian-puppet
      def self.enqueue_librarian_mods(mods)
        # +mods+: wrong type
        if !mods.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'mods', 'Hash', 'Puppet#enqueue_librarian_mods').colorize(:red)
          raise SystemExit
        end
        mods.each do |mod, settings|
          # +settings+: wrong type
          if !settings.is_a?(Hash)
            puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
              @@current_project, @@current_sw, 'settings', 'Hash', 'Puppet#enqueue_librarian_mods').colorize(:red)
            raise SystemExit
          end
          has = {}
          [:git, :path, :ref, :tar, :ver].each do |param|
            settings.except!(param) if settings.has_key?(param) and settings[param].is_a?(String) and settings[param].blank?
            has[param] = settings.has_key?(param)
          end
          # Check possible combinations of settings
          if settings.empty? or
              (has[:git] and !has[:path] and !has[:ref] and !has[:tar] and !has[:ver]) or   # mod + :git
              (has[:git] and has[:path] and !has[:ref] and !has[:tar] and !has[:ver]) or    # mod + :git + :path
              (has[:git] and !has[:path] and has[:ref] and !has[:tar] and !has[:ver]) or    # mod + :git + :ref
              (has[:git] and !has[:path] and !has[:ref] and !has[:tar] and has[:ver]) or    # mod + :git + :ver (:ver => :ref)
              (!has[:git] and !has[:path] and !has[:ref] and !has[:tar] and has[:ver]) or   # mod + :ver
              (!has[:git] and !has[:path] and !has[:ref] and has[:tar] and has[:ver]) or    # mod + :ver + :tar
              (!has[:git] and has[:path] and !has[:ref] and !has[:tar] and !has[:ver])      # mod + :path
            if !settings.empty? and has[:git] and !has[:path] and !has[:ref] and !has[:tar] and has[:ver]
              settings[:ref] = settings[:ver]
              settings.except!(:ver)
            end
            @@puppetfile_mods = @@puppetfile_mods.deep_merge({mod => settings})
          # Incompatible settings for librarian-puppet module
          else
            puts sprintf(DOA::L10n::INCOMPAT_SETTINGS_LIBRARIAN_MOD, DOA::Guest.sh_header, @@current_sw).colorize(:red)
            raise SystemExit
          end
        end
      end

      # Adds the provided APT repositories (Debian Linux family) to the list of
      # repositories automatically managed with Puppet Hiera.
      # +label+:: string with the name to assign to the repository
      # +settings+:: hash with the requested settings for setting the repository up (required keys {ensure|comment|location|key|before}
      # +relationships+:: hash with the requested relationships; see Puppet#enqueue_relationship
      # +puppetfile_mods+:: hash with modules to autoload with librarian-puppet
      # +hiera_classes+:: array with classes to autoload with Puppet Hiera
      def self.enqueue_apt_hiera_settings(modclass, modparam, label, settings, relationships = nil, puppetfile_mods = nil, hiera_classes = nil)
        hiera_classes = [hiera_classes] if !hiera_classes.is_a?(Array)

        # +label+: wrong type
        if !label.is_a?(String)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'label', 'String', 'Puppet#enqueue_apt_hiera_settings').colorize(:red)
          raise SystemExit
        # +settings+: wrong type
        elsif !settings.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'settings', 'Hash', 'Puppet#enqueue_apt_hiera_settings').colorize(:red)
          raise SystemExit
        # +relationships+: wrong type
        elsif !relationships.nil? and !relationships.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header,
            DOA::Guest.hostname, @@current_project, @@current_sw, 'relationships', 'Hash').colorize(:red)
          raise SystemExit
        # Enqueue module parameters for Hiera
        else
          enqueue_librarian_mods(puppetfile_mods) if !puppetfile_mods.empty?
          enqueue_hiera_classes(hiera_classes) if !hiera_classes.empty?
          enqueue_hiera_params('APT Package Manager', {"#{ modclass }::#{ modparam }" => settings}) if !settings.empty?
          rel_class = case modparam
            when 'sources' then 'Source'
            when 'pins' then 'Pin'
            else modparam.capitalize
            end
          enqueue_relationship("Apt::#{ rel_class }[#{ settings.keys[0] }]", relationships) if !relationships.empty?
        end
      end

      # Adds the provided APT repositories (Debian Linux family) to the list of
      # repositories automatically managed with Puppet Hiera.
      # +label+:: string with the name to assign to the repository
      # +settings+:: hash with the requested settings for setting the repository up (required keys {ensure|comment|location|key|before}
      # +relationships+:: hash with the requested relationships; see Puppet#enqueue_relationship
      def self.enqueue_apt_repo(label, settings, relationships = nil)
        # +settings+: wrong type
        if !settings.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'settings', 'Hash', 'Puppet#enqueue_apt_repo').colorize(:red)
          raise SystemExit
        # +settings+: missing required keys or values of wrong type
        elsif !settings.has_key?('ensure') || !settings['ensure'].is_a?(String) ||
            !settings.has_key?('comment') || !settings['comment'].is_a?(String) ||
            !settings.has_key?('location') || !settings['location'].is_a?(String) ||
            !settings.has_key?('key') || !settings['key'].is_a?(Hash) ||
            !settings['key'].has_key?('id') || !settings['key']['id'].is_a?(String)
          puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_PROJECT, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'settings', 'Puppet#enqueue_apt_repo').colorize(:red)
          raise SystemExit
        else
          enqueue_apt_hiera_settings('apt', 'sources', label, {"'#{ label }'" => settings.deep_merge(PPA_DEFAULTS)}, relationships, [PF_MOD_APT], [PF_MOD_APT])
        end
      end

      # Adds the provided APT pins (Debian Linux family) to hold a version/branch
      # of a specific software, automatically managed with Puppet Hiera (through
      # custom module apthelper).
      # +label+:: string with the name to assign to the repository
      # +settings+:: hash with the requested settings for setting the repository up (required keys {ensure|comment|location|key|before}
      # +relationships+:: hash with the requested relationships; see Puppet#enqueue_relationship
      # Example:
      #    enqueue_apt_pin('mariadb', {
      #      'packages' => "'mariadb-server'",
      #      'version'  => "'5.5.36'",
      #      'ensure'   => "'held'",
      #    }, {'before' => "Class['mariadb']"})
      def self.enqueue_apt_pin(label, settings, relationships = nil)
        # +settings+: wrong type
        if !settings.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'settings', 'Hash', 'Puppet#enqueue_apt_pin').colorize(:red)
          raise SystemExit
        # +settings+: missing required keys or values of wrong type
        elsif !settings.has_key?('ensure') || !settings['ensure'].is_a?(String) ||
            !settings.has_key?('packages') || !settings['packages'].is_a?(String) ||
            !settings.has_key?('version') || !settings['version'].is_a?(String)
          puts sprintf(DOA::L10n::MALFORMED_FN_PARAM_CTX_PROJECT, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'settings', 'Puppet#enqueue_apt_pin').colorize(:red)
          raise SystemExit
        else
          enqueue_apt_hiera_settings('apthelper', 'pins', label, {
              "'hold_#{ label.downcase.gsub(/\./, '_') }'" => settings,
            }, relationships, PF_MOD_APT, [PF_MOD_APT, DOA_MOD_APT])
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
                @@current_project, @@current_sw, 'relationships', 'Puppet#enqueue_relationship').colorize(:red)
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
                @@current_project, @@current_sw, 'relationships', 'Puppet#enqueue_relationship').colorize(:red)
              raise SystemExit
            else
              @@relationships[chaining] = true if !@@relationships.has_key?(chaining)
            end
          end
        end
      end

      # Insert content into the guest manifest.
      # +content+:: string with the content to append to 'site.pp' manifest
      def self.enqueue_site_content(content)
        # Set the appropriate relationships through chaining arrows when requested
        if content.nil? or !content.is_a?(String)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'content', 'String', 'Puppet#enqueue_site_content').colorize(:red)
          raise SystemExit
        elsif content.present?
          @@site_content.insert(-1, content) if !content.empty?
        end
      end

      # Enqueue Puppet Hiera parameters into the given label (appending when key exists).
      # +sw_label+:: key representing the section to insert the parameters into
      # +params+:: hash with the Hiera parameters to append
      def self.enqueue_hiera_params(sw_label, params)
        # Set the appropriate relationships through chaining arrows when requested
        if params.nil? or !params.is_a?(Hash)
          puts sprintf(DOA::L10n::WRONG_TYPE_FN_PARAM_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
            @@current_project, @@current_sw, 'content', 'String', 'Puppet#enqueue_hiera_params').colorize(:red)
          raise SystemExit
        elsif !params.empty?
          if @@sw_stack[sw_label].empty?
            @@sw_stack[sw_label] = params
          else
            @@sw_stack[sw_label] = @@sw_stack[sw_label].deep_merge(params)
          end
        end
      end
    end
  end
end
