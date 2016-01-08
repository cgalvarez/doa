#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class CouchDB < PuppetModule
        # Constants.
        MOD_CGALVAREZ_COUCHDB = 'cgalvarez/couchdb'
        CL_COUCHDB = 'couchdb'

        # Class variables.
        @label        = 'CouchDB'
        @hieraclasses = ['couchdb']
        @librarian    = {
          MOD_CGALVAREZ_COUCHDB => {
            :git  => 'git://github.com/cgalvarez/puppet-couchdb.git',
            :ver  => '1.0.3',
          },
        }
        @supported = {
            'version' => {
              :expect     => [:semver_version, :semver_branch],
              :maps_to    => "#{ CL_COUCHDB }::version",
              :cb_process => "#{ self.to_s }#process_version@#{ CL_COUCHDB }",
            },
            'ensure' => {
              :expect  => [:string],
              :maps_to => "#{ CL_COUCHDB }::ensure",
              :allow   => ['absent', 'purged', 'present', 'installed', 'latest', 'held'],
              :mod_def => 'present',
              :doa_def => {
                :dev   => 'latest',
                :test  => 'latest',
                :prod  => 'present',
              },
            },
            'bind_address' => {
              :expect  => :ipv4,
              :maps_to => "#{ CL_COUCHDB }::bind_address",
              :mod_def => '127.0.0.1',
              :doa_def => {
                :dev   => '0.0.0.0',
                :test  => '0.0.0.0',
                :prod  => '127.0.0.1',
              },
            },
            'port' => {
              :expect  => :port,
              :maps_to => "#{ CL_COUCHDB }::port",
              :mod_def => '5984',
              :doa_def => {
                :dev   => '5984',
                :test  => '5984',
                :prod  => '5984',
              },
            },
            'backupdir' => {
              :expect  => :unix_abspath,
              :maps_to => "#{ CL_COUCHDB }::backupdir",
              :mod_def => '/var/backups/couchdb',
              :doa_def => {
                :dev   => '/var/backups/couchdb',
                :test  => '/var/backups/couchdb',
                :prod  => '/var/backups/couchdb',
              },
            },
          }
      end
    end
  end
end
