#!/usr/bin/ruby

module DOA
  module Provisioner
    class Puppet
      module Meteor
        # Constants
        SW = Setting::SW_METEOR
        DOA_MOD = 'cgalvarez/meteor'
        SUPPORTED = {}

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
          Puppet.enqueue_hiera_classes([DOA_MOD]) if const_defined?('DOA_MOD')

          # Set the provided values or the default otherwise
          SUPPORTED.each do |param, def_val|
            if settings.nil? or !settings.has_key?(param) or settings[param].nil?
              Puppet.sw_stack[SW][param] = def_val
            #else
            #  case param
            #  end
            end
          end
        end
      end
    end
  end
end
