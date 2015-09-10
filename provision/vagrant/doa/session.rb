#!/usr/bin/ruby

module DOA
  class Session
    # Host session attributes
    attr_reader :path, :pub, :auth_keys_reloaded, :machine_session,
      :guest_listener, :guest_hosts_pp,
      :guest_papply, :guest_puppet_conf, :guest_puppetfile, :guest_hiera_yaml, :guest_common_yaml, :guest_hostname_yaml, :guest_site_pp,
    # Guest session attributes
      :hosts_pp,
      :tmp_papply, :tmp_puppet_conf, :tmp_puppetfile, :tmp_hiera_yaml, :tmp_common_yaml, :tmp_hostname_yaml, :tmp_site_pp,
      :papply, :puppet_conf, :puppetfile, :hiera_yaml, :common_yaml, :hostname_yaml, :site_pp,
    # Session common attributes
      :pid, :launcher, :listener, :ppk, :log_rsync

    # Makes the default initialization.
    # Params:
    # +machine+:: {DOA::Host | DOA::Guest} object
    def initialize(host = false)
      if host
        # Host intermediate temporary files
        @path               = "#{ DOA::Env.tmp_path }/#{ DOA::Guest.name }"
        @ppk                = "#{ @path }/#{ DOA::Guest.name }"
        @pub                = "#{ @ppk }.pub"
        @pid                = "#{ @path }/pid"
        @launcher           = "#{ @path }/launcher.ps1"
        @listener           = "#{ @path }/fsevents_host.rb"
        @log_rsync          = "#{ @path }/rsync.log"
        @auth_keys_reloaded = "#{ @path }/auth_keys_reloaded"
        @user_domain        = ENV['USERDOMAIN']
        @user_name          = ENV['USERNAME']

        # Auto-generated files for the guest machine in the host machine
        @guest_listener       = "#{ @path }/fsevents_guest.rb"
        @guest_hosts_pp       = "#{ @path }/hosts.pp"
        @guest_papply         = "#{ @path }/papply"
        @guest_puppet_conf    = "#{ @path }/puppet.conf"
        @guest_puppetfile     = "#{ @path }/Puppetfile"
        @guest_hiera_yaml     = "#{ @path }/hiera.yaml"
        @guest_common_yaml    = "#{ @path }/common.yaml"
        @guest_hostname_yaml  = "#{ @path }/hostname.yaml"
        @guest_site_pp        = "#{ @path }/site.pp"

        # Check for required folders
        Dir.mkdir(@path) unless File.exists?(@path) and File.directory?(@path)
      else
        @ppk        = "#{ DOA::Guest::HOME }/.ssh/#{ DOA::Host.hostname }"
        @log_rsync  = "#{ DOA::Guest::LOG }/rsync.log"
        @hosts_pp   = "#{ DOA::Guest::TMP }/hosts.pp"
        @listener   = "#{ DOA::Guest::TMP }/fsevents_guest.rb"
        
        # PROVISIONER: Puppet
        @tmp_papply         = "#{ DOA::Guest::TMP }/papply"
        @tmp_puppet_conf    = "#{ DOA::Guest::TMP }/puppet.conf"
        @tmp_puppetfile     = "#{ DOA::Guest::TMP }/Puppetfile"
        @tmp_hiera_yaml     = "#{ DOA::Guest::TMP }/hiera.yaml"
        @tmp_common_yaml    = "#{ DOA::Guest::TMP }/common.yaml"
        @tmp_hostname_yaml  = "#{ DOA::Guest::TMP }/#{ DOA::Guest.name }.yaml"
        @tmp_site_pp        = "#{ DOA::Guest::TMP }/site.pp"
        @papply             = '/usr/local/bin/papply'
        @puppet_conf        = "#{ DOA::Provisioner::Puppet::CONFDIR }/puppet.conf"
        @puppetfile         = "#{ DOA::Provisioner::Puppet::CONFDIR }/Puppetfile"
        @hiera_yaml         = "#{ DOA::Guest::PROVISION }/config/hiera.yaml"
        @common_yaml        = "#{ DOA::Provisioner::Puppet::HIERA_DATA_DIR }/common.yaml"
        @hostname_yaml      = "#{ DOA::Provisioner::Puppet::HIERA_DATA_DIR }/#{ DOA::Guest.name }.yaml"
        @site_pp            = "#{ DOA::Provisioner::Puppet::MANIFESTS_DIR }/site.pp"
      end
    end
  end
end
