# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set the appropriate environment
#require "./provision/vagrant/vagrant_env.rb"
#$env = VagrantEnv.new if $env.nil?
#[$env.tmp_path].each { |filepath|
#  Dir.mkdir(filepath) unless File.exists?(filepath) and File.directory?(filepath)
#}

require './provision/vagrant/doa'

# Set default Vagrant settings
ENV['VAGRANT_DEFAULT_PROVIDER'] = DOA::Provider::Virtualbox::TYPE
VAGRANTFILE_API_VERSION = '2'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for backwards
# compatibility). Please don't change it unless you know what you're doing.
DOA.initialize
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  machines = YAML.load_file('machines.yml')
  DOA::Host.calc_guest_defaults(machines)

  machines.each do |name, settings|
    config.vm.define name do |machine|
      DOA::Guest.load(name, settings)
      machine_exists = DOA::Guest.provider.exist?(DOA::Guest.provider_vname)

      # Setup virtual machine
      machine.vm.box = DOA::Guest.box
      machine.vm.hostname = DOA::Guest.hostname
      if DOA::Guest.get_ip.nil?
        machine.vm.network 'private_network', type: 'dhcp'
      else
        machine.vm.network 'private_network', ip: DOA::Guest.get_ip
      end

      # Fix annoying "stdin: is not a tty" Vagrant error
      # Read more: https://github.com/mitchellh/vagrant/issues/1673
      machine.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

      # Configure the latest version of the desired provisioner in the guest
      if DOA::Guest.provision or !machine_exists
        case DOA::Guest.provisioner.class.const_get(:TYPE)
        when DOA::Provisioner::Docker::TYPE then
          # Docker provisioning
        else
          # Update puppet/r10k/librarian-puppet to their latest versions
          machine.vm.provision 'shell', path: 'provision/shell/puppet.sh'
          machine.vm.synced_folder "provision/puppet/modules/", DOA::Provisioner::Puppet::MODS_PATH_CUSTOM
        end
      end

      # ALWAYS reload host info with Vagrant internal info and the current guest
      machine.trigger.before [:up, :halt, :suspend, :resume, :reload, :ssh, :destroy] do
        DOA::Env.reload_session(@machine)
        DOA::Host.reload_session
        DOA::Guest.reload_session
      end

      machine.trigger.before [:reload, :suspend, :halt] do
        DOA::Host.remove_session_keys
        DOA::Guest.remove_session_keys
        DOA::Guest.manage_hosts(true)
        DOA::Host.manage_hosts(true)
      end

      machine.trigger.after [:reload, :resume, :up] do
        DOA::Host.manage_hosts
        DOA::Host.add_session_keys
        #DOA::Host.reload_authorized_keys
        DOA::Guest.manage_hosts
        DOA::Guest.add_session_keys

        # Setup the provision for the desired guest machine stack by the user
        if DOA::Guest.provision or !machine_exists
          case DOA::Guest.provisioner.class.const_get(:TYPE)
          when DOA::Provisioner::Docker::TYPE then
            # Docker provisioning
          else
            # Default provisioner: Puppet
            DOA::Guest.provisioner.class.setup_provision
          end
        end

        # Start bg-rsyncing @ guest before => Creates folders structure if
        # missing with appropriate ownership and permissions
        DOA::Guest.sync.start
        # TODO: This should start when exiting Vagrant (after all the guests are up)
        # That's not possible, so we check it on every processed machine (we could
        # check for the last machine and then do it, but in a multi-machine Vagrant
        # environment each machine can be managed independently of the others).
        DOA::Host.sync.start
      end

      machine.trigger.after [:suspend, :halt, :destroy] do
        DOA::Host.sync.stop
        DOA::Host.clean
      end

      machine.trigger.before [:ssh] do
        #DOA::Host.reload_authorized_keys
      end

      # Guest virtual machine setup
      provider_settings =
        case DOA::Guest.provider.class.const_get(:TYPE)
        when DOA::Provider::Virtualbox::TYPE then [
            'modifyvm',               :id,
            '--cpuexecutioncap',      '50',
            '--natdnshostresolver1',  'on',
            '--natdnsproxy1',         'on',
            '--groups',               '/DOA',
            '--cpus',                 DOA::Guest.cores,
            '--memory',               DOA::Guest.mem,
          ]
        else []
        end
      if provider_settings.any?
        machine.vm.provider DOA::Guest.provider.class.const_get(:TYPE) do |vm|
          vm.name = DOA::Guest.provider_vname
          vm.customize provider_settings
        end
      else
        raise sprintf(DOA::L10n::PROVIDER_NOT_SUPPORTED,
          DOA::Guest.provider.class.const_get(:TYPE), DOA::Guest.name)
      end
    end
  end
end
