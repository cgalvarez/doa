#!/usr/bin/ruby

module DOA
  module Provisioner
    class Puppet
      module CouchDB
        # Constants
        SW = Setting::SW_COUCHDB
        PUPPET_FORGE_MOD = 'camptocamp/couchdb'
        SUPPORTED = {
          'bind_address'  => "'0.0.0.0'",
          'port'          => 5984,
          'backupdir'     => "'/var/backups/couchdb'",
        }

        # Creates the puppet files needed for provisioning the guest machine according to the YAML settings.
        def self.setup(settings)
          # Check for disallowed parameters
          if !settings.nil?
            settings.each do |param, value|
              if !SUPPORTED.has_key?(param)
                puts sprintf(DOA::L10n::UNRECOGNIZED_SW_PARAM, DOA::Guest.sh_header,
                  DOA::Guest.hostname, Puppet.current_site, SW, param).colorize(:red)
                raise SystemExit
              end
            end
          end

          # Add the required parameters to the corresponding queues:
          #  - Puppet Forge modules (loaded through librarian-puppet -> Puppetfile)
          #  - Classes (loaded through Hiera -> hostname.yaml)
          Puppet.enqueue_puppetfile_mods([PUPPET_FORGE_MOD]) if const_defined?('PUPPET_FORGE_MOD')
          Puppet.enqueue_hiera_classes([PUPPET_FORGE_MOD]) if const_defined?('PUPPET_FORGE_MOD')

          # Add official repo for latest available version by Apache CouchDB Team
          case Puppet.os_info(Puppet::OS_FAMILY)
          when DOA::OS::LINUX_FAMILY_DEBIAN
            Puppet.enqueue_repo_apt('couchdb_apache', {
              'ensure'   => "'present'",
              'comment'  => "'PPA for latest stable official CouchDB packages by Apache CouchDB team'",
              'location' => "'http://ppa.launchpad.net/couchdb/stable/ubuntu'",
              'key'      => {'id' => "'15866BAFD9BCC4F3C1E0DFC7D69548E1C17EAB57'"},
            }, {'before' => "Package['couchdb']"})
          end

          # Set the provided values or the default otherwise
          SUPPORTED.each do |param, def_val|
            if settings.nil? or !settings.has_key?(param) or settings[param].nil?
              Puppet.sw_stack[SW][param] = def_val
            else
              case param
              when 'bind_address'
                Puppet.sw_stack[SW][param] = settings[param] if DOA::Tools.valid_ipv4?(settings[param])
              when 'port'
                Puppet.sw_stack[SW][param] = settings[param] if DOA::Tools.valid_port?(settings[param]) 
              when 'backupdir'
                Puppet.sw_stack[SW][param] = settings[param] if DOA::Tools.valid_unix_abspath(settings[param])
              end
            end
          end
        end
      end
    end
  end
end
