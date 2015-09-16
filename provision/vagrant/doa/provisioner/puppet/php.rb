#!/usr/bin/ruby

module DOA
  module Provisioner
    class Puppet
      module PHP
        # Constants
        SW = Setting::SW_PHP
        PUPPET_FORGE_MOD = 'mayflower/php'
        SUPPORTED = {
          'version'                 => 'latest',
          'fpm'                     => 'true',
          'dev'                     => 'true',
          'composer'                => 'true',
          'pear'                    => 'true',
          'phpunit'                 => 'true',
          'fpm::config::log_level'  => 'notice',
          'composer::auto_update'   => 'true',
        }
        REPO_ONDREJ = {
            '5.4' => "'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu/'",
            '5.5' => "'http://ppa.launchpad.net/ondrej/php5/ubuntu/'",
            '5.6' => "'http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu/'",
            '7.0' => "'http://ppa.launchpad.net/ondrej/php-7.0/ubuntu/'",
          }

        # Sets up the PHP provisioning with puppet
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

          # Add repos from Ondřej Surý for PHP 5.4.x, 5.5.x, 5.6.x
          #case Puppet.os_info(OS_FAMILY)
          #when DOA::OS::LINUX_FAMILY_DEBIAN
          #  wanted_repos =
          #    case Puppet.os_info(OS_DISTRO)
          #    when DOA::OS::LINUX_UBUNTU then
          #      # Unofficial versions and distros supported by Ondřej Surý (Ubuntu):
          #      #   Lucid    (10.04)       5.4.x
          #      #   Precise  (12.04) LTS   5.4.x   5.5.x   5.6.x           apache2
          #      #   Quantal  (12.10)       5.4.x
          #      #   Saucy    (13.10)               5.5.x
          #      #   Trusty   (14.04) LTS           5.5.x   5.6.x   7.0.x   apache2
          #      #   Utopic   (14.10)                       5.6.x           apache2
          #      #   Vidid    (15.04)                       5.6.x   7.0.x   apache2
          #      #   Wily     (15.04)                       5.6.x   7.0.x   apache2
          #      case Puppet.os_info(OS_DISTRO_VER)
          #      when DOA::OS::UBUNTU_LUCID, DOA::OS::UBUNTU_QUANTAL then ['5.4']
          #      when DOA::OS::UBUNTU_SAUCY then ['5.5']
          #      when DOA::OS::UBUNTU_UTOPIC then ['5.6']
          #      when DOA::OS::UBUNTU_PRECISE then ['5.4', '5.5', '5.6']
          #      when DOA::OS::UBUNTU_TRUSTY then ['5.5', '5.6']
          #      else []
          #      end
          #    else []
          #    end
          #
          #  guest_repos = {
          #      '5.4' => "'http://ppa.launchpad.net/ondrej/php5-oldstable/ubuntu/'",
          #      '5.5' => "'http://ppa.launchpad.net/ondrej/php5/ubuntu/'",
          #      '5.6' => "'http://ppa.launchpad.net/ondrej/php5-5.6/ubuntu/'",
          #      #'7.0' => "'http://ppa.launchpad.net/ondrej/php-7.0/ubuntu/'",
          #    }#.select { |key,_| wanted_repos.include? key }
          #
          #  REPO_ONDREJ.each do |php_ver, location|
          #    escaped_php_ver = php_ver.gsub('.', '_')
          #    Puppet.enqueue_repo_apt("php_ondrej_#{ escaped_php_ver }", {
          #      'ensure'   => wanted_repos.include?(php_ver) ? "'present'" : "'absent'",
          #      'comment'  => "'PPA for latest PHP #{ php_ver }.x packages by Ondřej Surý'",
          #      'location' => location,
          #      'key'      => {'id' => "'14AA40EC0831756756D7F66C4F4EA0AAE5267A6C'"},
          #    }, {'before' => "Class['php']"})
          #  end
          #  
          #  # Add ppa:ondrej/apache2 to resolve unmet dependencies
          #  Puppet.enqueue_repo_apt('apache2_ondrej', {
          #    'ensure'   => wanted_repos.include?(php_ver) ? "'present'" : "'absent'",
          #    'comment'  => "'PPA for latest Apache 2 packages by Ondřej Surý'",
          #    'location' => "'http://ppa.launchpad.net/ondrej/apache2/ubuntu/'",
          #    'key'      => {'id' => "'14AA40EC0831756756D7F66C4F4EA0AAE5267A6C'"},
          #  }, {'before' => "Class['php']"})
          #end

          # Set the provided values or the default otherwise
          SUPPORTED.each do |param, def_val|
            if settings.nil? or !settings.has_key?(param) or settings[param].nil?
              case param
              when 'version' then 'ensure'
                Puppet.sw_stack[SW]['ensure'] = def_val
              else
                Puppet.sw_stack[SW][param] = def_val
              end
            else
              case param
              when 'version'
                ver = DOA::Tools.check_get(settings, DOA::Tools::TYPE_STRING,
                  [DOA::Guest.hostname, Puppet.current_site, SW, param], param, SUPPORTED['version'])
                if Tools.valid_version?(ver, [], ['latest', 'present', 'absent'], true, false)
                  Puppet.sw_stack[SW]['ensure'] = "'#{ ver }'"
                else
                  puts sprintf(DOA::L10n::UNRECOGNIZED_VERSION, DOA::Guest.sh_header,
                    DOA::Guest.hostname, Puppet.current_site, SW, Setting::SW_VERSION).colorize(:red)
                  raise SystemExit
                end
              end
            end
          end
          Puppet.sw_stack[SW]['manage_repos'] = 'false'
        end
      end
    end
  end
end
