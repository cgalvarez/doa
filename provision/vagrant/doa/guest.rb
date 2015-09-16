#!/usr/bin/ruby

require 'singleton'
require_relative 'session'
require_relative 'sync'

module DOA
  class Guest
    include Singleton

    # Constants
    USER            = 'vagrant'
    HOME            = "/home/#{ DOA::Guest::USER }"
    TMP             = '/tmp'
    PROVISION       = '/etc/doa'
    LOG             = '/var/log'
    IP_REGEX        = /^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$/
    MIN_MACHINE_MEM = 512

    # Class variables
    @@ip              = nil
    @@name            = nil
    @@aliases         = nil
    @@box             = nil
    @@hostname        = nil
    @@fqdn            = nil
    @@sh_header       = nil
    @@session         = nil
    @@provider        = nil
    @@provider_vname  = nil
    @@provisioner     = nil
    @@ssh_address     = nil
    @@mem             = nil
    @@cores           = nil
    @@settings        = nil
    @@sync            = nil
    @@user            = nil
    @@os              = nil     # Filled and cached by chosen provider
    @@os_family       = nil     # Filled and cached by chosen provisioner
    @@os_distro       = nil     # Filled and cached by chosen provisioner
    @@os_distro_ver   = nil     # Filled and cached by chosen provisioner
    @@provision       = false

    # Getters
    def self.name
      @@name
    end
    def self.aliases
      @@aliases
    end
    def self.box
      @@box
    end
    def self.hostname
      @@hostname
    end
    def self.fqdn
      @@fqdn
    end
    def self.sh_header
      @@sh_header
    end
    def self.session
      @@session
    end
    def self.provider
      @@provider
    end
    def self.provider_vname
      @@provider_vname
    end
    def self.provisioner
      @@provisioner
    end
    def self.ssh_address
      @@ssh_address
    end
    def self.mem
      @@mem
    end
    def self.cores
      @@cores
    end
    def self.settings
      @@settings
    end
    def self.sync
      @@sync
    end
    def self.user
      @@user
    end
    def self.os
      @@os.nil? ? @@provider.get_os(@@provider_vname) : @@os
    end
    def self.os_family
      @@os_family
    end
    def self.set_os_family(value)
      @@os_family = value
    end
    def self.os_distro
      @@os_distro
    end
    def self.set_os_distro(value)
      @@os_distro = value
    end
    def self.os_distro_ver
      @@os_distro_ver
    end
    def self.set_os_distro_ver(value)
      @@os_distro_ver = value
    end
    def self.provision
      @@provision
    end

    # Makes the default initialization.
    # +name+:: string containing the name of the guest machine
    # +settings+:: hash with the user's settings for the current guest machine
    def self.load(name, settings)
      @@settings          = settings
      @@user              = DOA::Guest::USER
      @@name              = name
      @@provider = case DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_STRING,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::PROVIDER, ENV['VAGRANT_DEFAULT_PROVIDER'])
        when DOA::Provider::Virtualbox::TYPE then DOA::Provider::Virtualbox.instance
        end
        ###case Guest.get_setting('provisioner', DOA::Guest::TYPE_STRING, DOA::Provisioner::Puppet::TYPE)
      @@provisioner = case DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_STRING,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::PROVISIONER, DOA::Provisioner::Puppet::TYPE)
        when DOA::Provisioner::Docker::TYPE then DOA::Provisioner::Docker.instance
        else DOA::Provisioner::Puppet.instance
        end
      @@hostname = "#{ @@name }.doa.guest"
      @@provider_vname = "doa_guest_#{ @@name }"
      @@sh_header = (@@name.nil? ? "==>" : "    #{ @@name }:").colorize(:light_white)
      @@ssh_address = "#{ @@user }@#{ @@hostname }"
      @@box = DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_STRING,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::BOX, 'ubuntu/trusty64')
      @@aliases = DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_ARRAY,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::ALIASES, [])
      @@fqdn = DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_STRING,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::FQDN, @@hostname)
      @@mem = DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_INTEGER,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::MEMORY,
          DOA::Host.default_guest_mem, false, DOA::Guest::MIN_MACHINE_MEM)
      @@cores = DOA::Tools.check_get(@@settings, DOA::Tools::TYPE_INTEGER,
          [@@settings[Setting::HOSTNAME], @@settings[Setting::HOSTNAME]], Setting::CORES,
          DOA::Host.default_guest_cores, false, 1)
      @@session = DOA::Session.new(false)
      if self.running?
        @@ip = @@provider.get_ip(@@provider_vname)
      elsif settings.has_key?('ip') and !(settings['ip'] =~ DOA::Guest::IP_REGEX).nil?
        @@ip = settings['ip']
      end
      if ARGV.include?('--provision')
        @@provision = true
      end
      @@os_family       = nil     # Filled and cached by chosen provisioner
      @@os_distro       = nil     # Filled and cached by chosen provisioner
      @@os_distro_ver   = nil     # Filled and cached by chosen provisioner
    end

    # Reloads internal attributes for current guest session.
    def self.reload_session
      @@sync = DOA::Sync.new(self, DOA::Host)
    end

    # Gets the value of a setting with type integer.
    # Params:
    # +key+:: key of the hash +settings+ related to the setting to retrieve
    # +type+:: type of the value. Allowed: {Integer | String}
    # +vmin+:: minimum value allowed for the value of Integer types (included)
    # +vmax+:: maximum value allowed for the value of Integer types (included)
    def self.get_setting(key, type, default = nil, vmin = nil, vmax = nil)
      value = nil
      if @@settings.has_key?(key) and !@@settings[key].nil?
        case type
        when DOA::Guest::TYPE_INTEGER
          if @@settings[key].is_a? Integer and
              (vmin.nil? or @@settings[key] >= vmin) and
              (vmax.nil? or @@settings[key] <= vmax)
            value = @@settings[key]
          elsif /\A\d+\z/.match(@@settings[key]) and
              (vmin.nil? or @@settings[key] >= vmin) and
              (vmax.nil? or @@settings[key] <= vmax)
            value = @@settings[key].to_i
          end
        when DOA::Guest::TYPE_STRING
          value = @@settings[key] if @@settings[key].is_a? String and !@@settings[key].empty?
        when DOA::Guest::TYPE_ARRAY
          value = @@settings[key] if @@settings[key].is_a? Array
        when DOA::Guest::TYPE_HASH
          value = @@settings[key] if @@settings[key].is_a? Hash
        end
      end
      value = default if value.nil?
      return value
    end

    # Returns whether this guest machine is running or not.
    def self.running?
      running = case @@provider.class.const_get(:TYPE)
        when DOA::Provider::Virtualbox::TYPE then @@provider.running?(@@provider_vname)
        else false
        end
      return running
    end

    # Copies the already generated session private key to the vagrant user home at
    # guest machine.
    def self.add_session_keys
      if self.running?
        @@os = @@os.nil? ? @@provider.get_os(@@provider_vname) : @@os
        printf(DOA::L10n::SCP_PPK, @@sh_header, @@hostname)
        exitstatus = scp(DOA::Host.session.ppk, @@session.ppk)
        exitstatus = ssh([
          "sudo chmod 600 #{ @@session.ppk }",
          "sudo chown #{ @@user }:#{ @@user } #{ @@session.ppk }",
        ]) if exitstatus == 0
        puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
      end
    end

    # Removes the last authorized key for the current guest machine if it exists.
    def self.remove_session_keys
      printf(DOA::L10n::RM_SESSION_KEY, @@sh_header, @@hostname)
      exitstatus = ssh(["rm -f #{ @@session.ppk }"])
      puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
    end

    # Executes the provided commands +cmd+ securely in the guest machine.
    # Params:
    # +cmd+:: array containing the commands to execute remotely
    def self.ssh(cmd)
      return SSH.ssh(DOA::Env.guest_insecure_ppk, @@user, DOA::Host.os, @@ssh_address, @@os, cmd)
    end

    # Copies securely a file from the provided host path +from_path+ to the provided guest path +to_path+.
    # Params:
    # +from_path+:: string with the host path from which to copy
    # +to_path+:: string with the guest path to copy
    def self.scp(from_path, to_path)
      return SSH.scp(DOA::Env.guest_insecure_ppk, DOA::Host.os, from_path, @@ssh_address, @@os, to_path)
    end

    # Gets the IP address (IPv4) of the guest virtual machine for current provider.
    def self.get_ip
      return @@ip.nil? ? @@provider.get_ip(@@provider_vname) : @@ip
    end

    # Manages the guest hosts file.
    # Params:
    # +remove+:: boolean; true if the entry of the guest machine has to be removed; false otherwise
    # +hosts_path+:: string containing the path to the +hosts+ file inside the host machine
    def self.manage_hosts(remove = false, hosts_path = nil)
      # Create the puppet manifest to insert the host IP into the guest's hosts file
      if self.running?
        if hosts_path.nil?
          @@os = @@os.nil? ? @@provider.get_os(@@provider_vname) : @@os
          hosts_path = @@os == OS::WINDOWS ? 'C:/Windows/System32/Drivers/etc/hosts' : '/etc/hosts'
        end

        # Set the contents of the listener script
        printf(DOA::L10n::CREATE_HOSTS_MANIFEST, @@sh_header, @@hostname)
        listener = File.open(DOA::Host.session.guest_hosts_pp, 'w')
        listener << ERB.new(File.read(DOA::Templates::hosts_pp)).result(binding)
        listener.close
        puts DOA::L10n::SUCCESS_OK

        # Copy hosts manifest over SSH
        printf(DOA::L10n::SCP_HOSTS_MANIFEST, @@sh_header, @@hostname)
        exitstatus = scp(DOA::Host.session.guest_hosts_pp, @@session.hosts_pp)
        if exitstatus == 0
          puts DOA::L10n::SUCCESS_OK

          # Manage host entry
          printf(DOA::L10n::GUEST_HOSTS_HOST_ENTRY, @@sh_header, @@hostname, DOA::SSH.escape(@@os, hosts_path))
          exitstatus = ssh([
            "sudo puppet apply #{ @@session.hosts_pp }",
            "sudo rm -f #{ @@session.hosts_pp }",
          ])
          puts exitstatus == 0 ? (remove ? DOA::L10n::SUCCESS_REMOVED : DOA::L10n::SUCCESS_CREATED) : DOA::L10n::FAIL_ERROR
        else
          puts DOA::L10n::FAIL_ERROR
        end
      end
    end

  end
end
