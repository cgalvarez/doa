#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class NodeJS < PuppetModule
        # Constants.
        MOD_CGALVAREZ_NODESTACK = 'cgalvarez/nodestack'

        # Class variables.
        @hieraclasses = ['nodestack']
        @label        = DOA::Setting::SW_NODEJS_LABEL
        @librarian    = {
          MOD_CGALVAREZ_NODESTACK => {
            :git  => 'git://github.com/cgalvarez/puppet-nodestack.git',
            #:ver  => '1.0.0',
          },
        }
        # See: https://github.com/artberri/puppet-nvm
        # See: https://github.com/puppet-community/puppet-nodejs
        @supported = {
            'nvm' => {
              :children => {
                # Sets the directory where NVM is going to be installed.
                # Defaults to "/home/${user}/.nvm".
                'dir' => {
                  :expect  => :unix_abspath,
                  :maps_to => 'nodestack::nvm_dir',
                },
                'path' => {
                  :children => {
                    # Indicates the user's home. Only used when manage_user is set
                    # to true. Deaults to "/home/${user}".
                    'home' => {
                      :expect  => :unix_abspath,
                      :maps_to => 'nodestack::nvm_home',
                    },
                    # Sets the profile file where the nvm.sh is going to be loaded.
                    # Only used when manage_profile is set to true (default behaivour).
                    # Defaults "/home/${user}/.bashrc".
                    'profile' => {
                      :expect  => :unix_abspath,
                      :maps_to => 'nodestack::nvm_profile_path',
                    },
                  },
                },
                # Sets if the repo should be fetched again. Defaults to "false".
                'refetch' => {
                  :expect  => :boolean,
                  :maps_to => 'nodestack::nvm_refetch',
                  :mod_def => 'false',
                },
                # Sets the NVM repo url that is going to be cloned.
                # Defaults to "https://github.com/creationix/nvm".
                'repo' => {
                  :expect  => :url,
                  :maps_to => 'nodestack::nvm_nvm_repo',
                  :mod_def => 'https://github.com/creationix/nvm.git'
                },
                # Sets the user that will install NVM
                'user' => {
                  :expect  => :puppet_interpolable_string,
                  :maps_to => 'nodestack::nvm_user',
                  :doa_def => DOA::Guest::USER,
                },
                # Version of NVM that is going to be installed. Can point to any git
                # reference of the NVM project (or the repo set in nvm_repo parameter).
                # Defaults to "v0.29.0".
                'version' => {
                  :expect  => :semver_version,
                  :maps_to => 'nodestack::nvm_version',
                  :mod_def => '0.29.0',
                },
                'manage' => {
                  :children => {
                    # Sets if the module will manage the git, wget, make package
                    # dependencies. Defaults to "true".
                    'dependencies' => {
                      :expect  => :boolean,
                      :maps_to => 'nodestack::nvm_manage_dependencies',
                      :mod_def => 'true',
                    },
                    # Sets if the module will add the nvm.sh file to the user profile.
                    # Defaults to "true".
                    'profile' => {
                      :expect  => :boolean,
                      :maps_to => 'nodestack::nvm_manage_profile',
                      :mod_def => 'true',
                    },
                    # Sets if the selected user will be created if not exists.
                    # Defaults to "false".
                    'user' => {
                      :expect  => :boolean,
                      :maps_to => 'nodestack::nvm_manage_user',
                      :mod_def => 'false',
                    },
                  },
                },
              },
            },
            'versions' => {
              :maps_to       => 'nodestack::versions',
              :children_hash => {
                'default' => {
                  :expect  => :boolean,
                  :mod_def => 'false',
                },
                'nvm_dir' => {
                  :expect  => :unix_abspath,
                },
                'source' => {
                  :maps_to => 'from_source',
                  :expect  => :boolean,
                  :mod_def => 'false',
                },
                'user' => {
                  :expect  => :string,
                },
              },
            },
            'packages' => {
            },
          }
      end
    end
  end
end
