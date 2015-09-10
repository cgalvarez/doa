#!/usr/bin/ruby

require 'singleton'
require 'fileutils'
require_relative 'session'
require_relative 'sync'

module DOA
  class Host
    include Singleton

    # Constants
    HOSTS_SECTION = 'Vagrant DOA (DevOps-Automatter)'

    # Class variables
    @@hostname            = nil
    @@ip                  = nil
    @@authorized_keys     = nil
    @@hosts               = nil
    @@session             = nil
    @@os                  = nil
    @@total_mem           = nil
    @@free_mem            = nil
    @@cores               = nil
    @@sync                = nil
    @@user_name           = nil
    @@user_domain         = nil
    @@user_home           = nil
    @@default_guest_mem   = nil
    @@default_guest_cores = nil

    # Getters/setters
    def self.hostname
      @@hostname
    end
    def self.ip
      @@ip
    end
    def self.authorized_keys
      @@authorized_keys
    end
    def self.hosts
      @@hosts
    end
    def self.session
      @@session
    end
    def self.os
      @@os
    end
    def self.total_mem
      @@total_mem
    end
    def self.free_mem
      @@free_mem
    end
    def self.cores
      @@cores
    end
    def self.sync
      @@sync
    end
    def self.user_name
      @@user_name
    end
    def self.user_domain
      @@user_domain
    end
    def self.user_home
      @@user_home
    end
    def self.default_guest_mem
      @@default_guest_mem
    end
    def self.default_guest_cores
      @@default_guest_cores
    end

    # Makes the default initialization.
    # Params:
    # +hostname+:: string containing the hostname of the host machine; defaults to +'automatter.host'+
    def self.initialize(hostname = 'automatter.host')
      @@hostname        = hostname
      @@user_name       = ENV['USERNAME']
      @@user_home       = ENV['USERPROFILE']
      @@user_domain     = ENV['USERDOMAIN']
      @@authorized_keys = "#{ @@user_home }/.ssh/authorized_keys"
      @@os              = DOA::Host.get_os
      @@cores           = DOA::Host.get_cores(@@os) unless @@os.nil?
      @@total_mem       = DOA::Host.get_total_physical_memory(@@os) unless @@os.nil?
      @@free_mem        = DOA::Host.get_free_physical_memory(@@os) unless @@os.nil?
      @@ip              = Host.first_public_ipv4.ip_address unless Host.first_public_ipv4.nil?
      @@hosts           = @@os == DOA::OS::WINDOWS ? 'C:/Windows/System32/Drivers/etc/hosts' : '/etc/hosts'
    end

    def self.calc_guest_defaults(machines)
      # Optimize resources assigned to the multi-machine environment
      # https://stefanwrobel.com/how-to-make-vagrant-performance-not-suck

      # Default memory size for non-specified guest machines based on host resources
      # We want:
      #   - 25% of @total_mem to be free for host OS.
      #   - Each VM will have a maximum of @total_mem/4 MB and a minimum of 512 MB assigned.
      #   - Pre-assigned machines will stick with their own memory assignments.
      n_preassigned_machines = 0
      preassigned_mem = 0
      machines.each do |machine, settings|
        if settings['memory'].is_a? Integer
          if settings['memory'] >= DOA::Guest::MIN_MACHINE_MEM
            preassigned_mem += settings['memory']
            n_preassigned_machines += 1
          end
        elsif /\A\d+\z/.match(settings['memory'])
          if settings['memory'].to_i >= DOA::Guest::MIN_MACHINE_MEM
            preassigned_mem += settings['memory'].to_i
            n_preassigned_machines += 1
          end
        end
      end
      avail_mem_sizes = [(@@total_mem / 4)]
      default_mem = machines.length - n_preassigned_machines == 0 ?
        DOA::Guest::MIN_MACHINE_MEM :
        (@@free_mem - (@@total_mem / 4) - preassigned_mem) / (machines.length - n_preassigned_machines)
      avail_mem_sizes.insert(-1, default_mem < DOA::Guest::MIN_MACHINE_MEM ?
        DOA::Guest::MIN_MACHINE_MEM : default_mem)
      @@default_guest_mem = avail_mem_sizes.min

      # Default cores for non-specified guest machines based on host resources
      @@default_guest_cores =
        case @@cores
        when 1, 2 then 1
        else (0.75 * @@cores).ceil
        end
    end

    # Reloads internal attributes for current guest session.
    def self.reload_session
      @@session  = DOA::Session.new(true)
      @@sync     = @@sync.nil? ? DOA::Sync.new(self, DOA::Guest) :
        @sync.reload_to(DOA::Guest)
    end

    # Gets the first private host IPv4 address available.
    def self.first_private_ipv4
      require 'socket'
      Socket.ip_address_list.detect { |intf| intf.ipv4_private? }
    end

    # Gets the first public host IPv4 address available.
    def self.first_public_ipv4
      require 'socket'
      Socket.ip_address_list.detect { |intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private? }
    end

    # Generates a new session key for the current guest and authorizes them
    def self.add_session_keys
      if DOA::Guest.running?
        # Generate a new RSA 2048 bits SSH key for current session
        print "#{ DOA::Guest.sh_header } Generating new session key... "
        commands = []
        quotes = ""
        separator = ' && '
        hide_output = '>/dev/null 2>&1'
        if Vagrant::Util::Platform.windows?
          commands.insert(-1, @@session.path[/^([a-zA-Z]:)/,1])
          quotes = "\""
          separator = ' & '
          hide_output = '>NUL 2>NUL'
        end
        commands.push(
          "cd #{ quotes }#{ @@session.path }#{ quotes }",
          "rm -f #{ quotes }#{ @@session.ppk }#{ quotes }",
          "rm -f #{ quotes }#{ @@session.pub }#{ quotes }",
          "ssh-keygen -R #{ quotes }#{ DOA::Guest.get_ip }#{ quotes } #{ hide_output }",
          "ssh-keygen -R #{ quotes }#{ DOA::Guest.hostname }#{ quotes } #{ hide_output }",
          "ssh-keygen -b 2048 -f #{ quotes }#{ @@session.ppk }#{ quotes } -N \"\" -t rsa -C \"#{ DOA::Guest.hostname }\""
        )
        `#{ commands.join(separator) }`
        puts $?.exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR

        # Append the new generated key for current session to the authorized keys
        print "#{ DOA::Guest.sh_header } Adding new session key to host authorized keys... "
        `cat #{ quotes }#{ @@session.pub }#{ quotes } >> #{ quotes }#{ @@authorized_keys }#{ quotes }`
        puts $?.exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR

        # Remove flag file to ask for reloading authorized keys again
        `rm -f #{ quotes }#{ @@session.auth_keys_reloaded }#{ quotes }`
      end
    end

    # Cleans the temporary folder
    def self.clean
      print "#{ DOA::Guest.sh_header } Cleaning temporary files for current session @ #{ @@hostname }... "
      FileUtils.rm_rf(@@session.path)
      puts DOA::L10n::SUCCESS_OK
    end

    # Removes the last authorized key for the current guest machine if it exists.
    def self.remove_session_keys
      print "#{ DOA::Guest.sh_header } Removing session key from host authorized keys... "
      auth_keys_content = File.exist?(@@authorized_keys) ? `sed '/#{ DOA::Guest.hostname }/d' #{ @@authorized_keys }` : ''
      File.open(@@authorized_keys, 'w') { |file| file.write(auth_keys_content) }
      puts DOA::L10n::SUCCESS_OK
    end

    # Gets the hosts section for DOA for a given +Aef::Hosts+ object.
    # Params:
    # +hosts+:: +Aef::Hosts+ object with the contents of the hosts file
    private
    def self.get_hosts_section(hosts)
      section_idx = []
      hosts.elements.each_with_index do |el, idx|
        if el.class.name == 'Aef::Hosts::Section' and el.name == DOA::Host::HOSTS_SECTION
          section_idx.insert(-1, idx)
        end
      end
      return section_idx
    end

    # Gets the hosts section for DOA for a given +Aef::Hosts+ object.
    # Params:
    # +hosts+:: +Aef::Hosts+ object with the contents of the hosts file
    # +section_idx+:: numerical index of the DOA section inside the passed +hosts+ object
    # +name+:: name of the guest machine to look for
    private
    def self.get_hosts_section_entry(hosts, section_idx, name)
      entry_idx = []
      if !section_idx.nil?
        hosts.elements[section_idx].elements.each_with_index do |el, idx|
          if el.name == name
            entry_idx.insert(-1, idx)
          end
        end
      end
      return entry_idx
    end

    # Manages the hosts file in the host machine.
    # Params:
    # +remove+:: boolean; true if the entry of the currently under-process guest machine has to be removed; false otherwise
    # +hosts_path+:: string containing the path to the +hosts+ file inside the host machine
    def self.manage_hosts(remove = false, hosts_path = @@hosts)
      status = nil
      hosts = Hosts::File.read(hosts_path)

      # Delete repeated sections after first found one
      section_idx = get_hosts_section(hosts)
      section_idx.each_with_index do |section, idx|
        hosts.elements.delete_at(idx) if idx > 0
      end
      section = section_idx[0] if section_idx.size > 0

      # Delete repeated entries in section after first found one
      entry_idx = get_hosts_section_entry(hosts, section, DOA::Guest.hostname)
      entry_idx.each_with_index do |entry, idx|
        hosts.elements[section].elements.delete_at(idx) if idx > 0
      end
      entry = entry_idx[0] if entry_idx.size > 0

      # Case remove entry
      if remove and !section.nil?
        status = DOA::L10n::SUCCESS_REMOVED
        # Delete entire section if only has one entry
        if hosts.elements[section].elements.size == 1
          hosts.elements.delete_at(section)
        # Delete entry for current guest in case of multiple entries
        else
          hosts.elements[section].elements.delete_at(entry_idx)
        end
      # Case add/update entry
      else
        ip = DOA::Guest.get_ip
        if DOA::Guest.running? and !ip.nil? and !ip.empty?
          # Case section exists
          if !section.nil?
            if !entry.nil?
              old_entry = hosts.elements[section].elements[entry]
              # Update existing entry if any data has changed
              if old_entry.address != ip or old_entry.aliases.size != DOA::Guest.aliases.size or (old_entry.aliases & DOA::Guest.aliases != old_entry.aliases)
                status = DOA::L10n::SUCCESS_UPDATED
                hosts.elements[section].elements[entry].address = ip
                hosts.elements[section].elements[entry].aliases = DOA::Guest.aliases
              end
            # Add new entry if not exist
            else
              status = DOA::L10n::SUCCESS_ADDED
              hosts.elements[section].elements.insert(-1, Hosts::Entry.new(ip, DOA::Guest.hostname, :aliases => DOA::Guest.aliases))
            end
          # Case section doesn't exist
          else
            status = DOA::L10n::SUCCESS_CREATED
            hosts.elements.insert(-1, Hosts::Section.new(DOA::Host::HOSTS_SECTION,
              :elements => [Hosts::Entry.new(ip, DOA::Guest.hostname, :aliases => DOA::Guest.aliases)]))
          end
        end
      end

      # Update file contents
      if !status.nil?
        hosts.write
        puts sprintf(DOA::L10n::HOST_HOSTS_GUEST_ENTRY, DOA::Guest.sh_header, @@hostname, DOA::SSH.escape(@@os, hosts_path), status)
      end
    end

    # Check if the host operative system is Windows
    def self.windows?
      # Vagrant::Util::Platform.windows?
      (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
    end

    # Check if the host operative system is Mac
    def self.mac?
     (/darwin/ =~ RUBY_PLATFORM) != nil
    end

    # Check if the host operative system is Unix
    def self.unix?
      !self.windows?
    end

    # Check if the host operative system is Linux
    def self.linux?
      self.unix? and not self.mac?
    end

    # Gets the OS of the host machine
    def self.get_os
      if !@@os.nil?
        return @@os
      elsif self.windows?
        return OS::WINDOWS
      elsif self.mac?
        return OS::MAC
      elsif self.linux?
        return OS::LINUX
      elsif self.unix?
        return OS::UNIX
      else
        return nil
      end
    end

    # Gets the total physical memory of the host machine in MB
    def self.get_total_physical_memory(os)
      total_phys_mem =
        case os
        # meminfo shows KB and we need to convert to MB
        when OS::LINUX, OS::UNIX then `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024
        # wmic shows KB and we need to convert to MB
        #when OS::WINDOWS then `wmic OS get TotalVisibleMemorySize /Value`.gsub("\n", '').partition('=').last.to_i / 1024
        when OS::WINDOWS then `wmic OS get TotalVisibleMemorySize /Value`.strip.partition('=').last.to_i / 1024
        # sysctl returns Bytes and we need to convert to MB
        when OS::MAC then `sysctl -n hw.memsize`.to_i / 1024 / 1024
        else nil
        end
      return total_phys_mem
    end

    # Gets the free physical memory of the host machine in MB
    def self.get_free_physical_memory(os)
      free_phys_mem =
        case os
        # meminfo shows KB and we need to convert to MB
        when OS::LINUX, OS::UNIX then `grep 'MemFree' /proc/meminfo | sed -e 's/MemFree://' -e 's/ kB//'`.to_i / 1024
        # wmic shows KB and we need to convert to MB
        #when OS::WINDOWS then `wmic OS get FreePhysicalMemory /Value`.gsub("\n", '').partition('=').last.to_i / 1024
        when OS::WINDOWS then `wmic OS get FreePhysicalMemory /Value`.strip.partition('=').last.to_i / 1024
        # sysctl returns Bytes and we need to convert to MB
        when OS::MAC then `sysctl -n hw.usermem`.to_i / 1024 / 1024
        else nil
        end
      return free_phys_mem
    end

    # Gets the total number of CPU cores of the host machine
    def self.get_cores(os)
      cores = 
        case os
        when OS::LINUX, OS::UNIX then `nproc`.to_i
        #when OS::WINDOWS then `wmic cpu get NumberOfCores /Value`.gsub("\n", '').partition('=').last.to_i
        when OS::WINDOWS then `wmic cpu get NumberOfCores /Value`.strip.partition('=').last.to_i
        when OS::MAC then `sysctl -n hw.ncpu`.to_i
        else nil
        end
      return cores
    end

    # Reloads authorized keys for current user account at host machine.
    # Params:
    # +max_retries+:: integer stating the maximum number of retries to provide the account password
    def self.reload_authorized_keys(max_retries = 3)
      if @@os == OS::WINDOWS and !File.exist?(@@session.auth_keys_reloaded)
        auth_keys_content = File.exist?(@@authorized_keys) ?
          `sed -n '/#{ DOA::Guest.hostname }/p' #{ @@authorized_keys }` : ''
        puts sprintf(DOA::L10n::PW_REQUEST, DOA::Guest.sh_header)

        n_tries = 0
        success = false
        while n_tries < max_retries and !success
          puts sprintf(DOA::L10n::CONN_CLOSED, DOA::Guest.sh_header) if n_tries > 0
          n_tries += 1
          `ssh -l "#{ @@user_domain }\\#{ @@user_name }" #{ DOA::SSH::OPT_SSH_PASS } #{ @@user_name }@localhost 'echo >NUL'`
          success = $?.exitstatus == 0
        end

        puts sprintf(DOA::L10n::MAX_RETRIES_REACHED, DOA::Guest.sh_header) if n_tries == max_retries
        puts sprintf(DOA::L10n::RELOADING_AUTH_KEYS, DOA::Guest.sh_header, success ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR)
        ###puts "#{ DOA::Guest.sh_header } Aborting... Maximum number of retries reached...".colorize(:red) if n_tries == max_retries
        ###puts "#{ DOA::Guest.sh_header } Reloading authorized keys... [" + (success ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR) + ']'
        `touch #{ @@session.auth_keys_reloaded }` if success
      end
    end
  end
end
