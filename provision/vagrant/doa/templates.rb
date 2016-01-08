#!/usr/bin/ruby

require 'singleton'

module DOA
  class Templates
    include Singleton

    # Class variables
    @@listener        = nil
    @@presync         = nil
    @@launcher        = nil
    @@hosts_pp        = nil
    @@papply          = nil
    @@puppet_conf     = nil
    @@puppetfile      = nil
    @@common_yaml     = nil
    @@hostname_yaml   = nil
    @@hiera_yaml      = nil
    @@site_pp         = nil

    # Getters
    def self.listener
      @@listener
    end
    def self.launcher
      @@launcher
    end
    def self.hosts_pp
      @@hosts_pp
    end
    def self.papply
      @@papply
    end
    def self.puppetfile
      @@puppetfile
    end
    def self.puppet_conf
      @@puppet_conf
    end
    def self.common_yaml
      @@common_yaml
    end
    def self.hostname_yaml
      @@hostname_yaml
    end
    def self.hiera_yaml
      @@hiera_yaml
    end
    def self.site_pp
      @@site_pp
    end
    def self.presync
      @@presync
    end

    # Makes the default initialization.
    def self.initialize
      @@listener        = "#{ DOA::Env.vagrant_provision_path }/templates/listener.erb"
      @@launcher        = "#{ DOA::Env.vagrant_provision_path }/templates/launcher.erb"
      @@hosts_pp        = "#{ DOA::Env.vagrant_provision_path }/templates/hosts.erb"
      @@papply          = "#{ DOA::Env.vagrant_provision_path }/templates/papply.erb"
      @@puppet_conf     = "#{ DOA::Env.vagrant_provision_path }/templates/puppet_conf.erb"
      @@puppetfile      = "#{ DOA::Env.vagrant_provision_path }/templates/Puppetfile.erb"
      @@common_yaml     = "#{ DOA::Env.vagrant_provision_path }/templates/common_yaml.erb"
      @@hostname_yaml   = "#{ DOA::Env.vagrant_provision_path }/templates/hostname_yaml.erb"
      @@hiera_yaml      = "#{ DOA::Env.vagrant_provision_path }/templates/hiera_yaml.erb"
      @@site_pp         = "#{ DOA::Env.vagrant_provision_path }/templates/site_pp.erb"
      @@presync         = "#{ DOA::Env.vagrant_provision_path }/templates/presync.erb"
    end
  end
end
