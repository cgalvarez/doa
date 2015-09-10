#!/usr/bin/ruby

require 'singleton'

module DOA
  class Env
    include Singleton

    # Constants
    ENV_HOME_VAR = 'VAGRANT_HOME'

    # Class variables
    @@cwd = nil
    @@local_data_path = nil         # @@cwd/.vagrant
    @@guest_data_dir = nil          # @@cwd/.vagrant/machines/???/virtualbox
    @@guest_insecure_ppk = nil      # @@cwd/.vagrant/machines/???/virtualbox/private_key
    @@home_path = nil               # %USERPROFILE%/.vagrant.d
    @@tmp_path = nil                # %USERPROFILE%/.vagrant.d/tmp
    @@data_dir = nil                # %USERPROFILE%/.vagrant.d/data
    @@gems_path = nil               # %USERPROFILE%/.vagrant.d/gems;ENV['VAGRANT_INSTALLER_EMBEDDED_DIR']/gems
    @@default_insecure_ppk = nil    # %USERPROFILE%/.vagrant.d/insecure_private_key
    @@ruby = nil                    # ENV['VAGRANT_INSTALLER_EMBEDDED_DIR']/bin/ruby
    @@vagrant_provision_path = nil  # @@cwd/provision/vagrant/

    # Getters/setters
    def self.cwd
      @@cwd
    end
    def self.local_data_path
      @@local_data_path
    end
    def self.guest_data_dir
      @@guest_data_dir
    end
    def self.guest_insecure_ppk
      @@guest_insecure_ppk
    end
    def self.home_path
      @@home_path
    end
    def self.tmp_path
      @@tmp_path
    end
    def self.data_dir
      @@data_dir
    end
    def self.gems_path
      @@gems_path
    end
    def self.default_insecure_ppk
      @@default_insecure_ppk
    end
    def self.ruby
      @@ruby
    end
    def self.vagrant_provision_path
      @@vagrant_provision_path
    end

    # Makes the default initialization.
    def self.initialize
      @@cwd       = Dir.pwd
      @@tmp_path  = "#{ @@home_path }/tmp"
      @@home_path = "#{ ENV['HOME'] }/.vagrant.d"
      @@ruby      = "#{ ENV['VAGRANT_INSTALLER_EMBEDDED_DIR'] }\\bin\\ruby.exe"
      @@gems_path = "#{ ENV['VAGRANT_INSTALLER_EMBEDDED_DIR'] }\\gems;#{ @@home_path }/gems".gsub('\\', '/')  # ENV['GEM_PATH']
      @@local_data_path         = "#{ @@cwd }/.vagrant"
      @@vagrant_provision_path  = "#{ @@cwd }/provision/vagrant/"
      Env.install_requirements
    end

    # Reloads internal attributes.
    # Params:
    # +machine+:: +Vagrant::Machine+ object representing the currently under-process machine; defaults to +nil+
    def self.reload_session(machine = nil)
      if !machine.nil?
        # Update own Vagrant environment info with internal Vagrant info when
        # available from +vagrant-triggers+ internal variable +@machine+
        @@cwd                  = machine.env.cwd.to_s
        @@local_data_path      = machine.env.local_data_path.to_s
        @@home_path            = machine.env.home_path.to_s
        @@tmp_path             = machine.env.tmp_path.to_s
        @@data_dir             = machine.env.data_dir.to_s
        #@gems_path            = machine.env.gems_path.to_s
        @@default_insecure_ppk = machine.env.default_private_key_path.to_s
        @@guest_data_dir       = machine.data_dir.to_s
      else
        @@guest_data_dir       = "#{ @@local_data_path }/machines/#{ $guest.name }/#{ $guest.provider }"
      end
      @@guest_insecure_ppk     = "#{ @@guest_data_dir }/private_key"
    end

    # Installs required Vagrant plugins and Ruby gems into Vagrant's isolated
    # Rubygems instance.
    def self.install_requirements
      Env.check_vagrant_home
      plugins = %w( vagrant-triggers )
      gems = %w( colorize hosts )
      required = plugins | gems
      need_restart = false
      required.each do |plugin|
        unless Vagrant.has_plugin? plugin
          system "vagrant plugin install #{ plugin }"
          need_restart = true
        end
      end
      exec "vagrant #{ ARGV.join(' ') }" if need_restart
    end

    # Sets the VAGRANT_HOME environment variable if it is not already set.
    def self.check_vagrant_home
      if DOA::Host.get_os == DOA::OS::WINDOWS
        `set #{ DOA::Env::ENV_HOME_VAR } >NUL 2>NUL`
        `set #{ DOA::Env::ENV_HOME_VAR }=#{ @@home_path } >NUL 2>NUL` if $?.exitstatus != 0
      else
        `echo #{ DOA::Env::ENV_HOME_VAR } >/dev/null 2>&1`
        `export #{ DOA::Env::ENV_HOME_VAR }='#{ @@home_path }' >/dev/null 2>&1` if $?.exitstatus != 0
      end
    end
  end
end
