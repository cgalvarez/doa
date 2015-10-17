#!/usr/bin/ruby

require_relative 'puppet_module'

module DOA
  module Provisioner
    class Puppet
      class Meteor < PuppetModule
        # Constants.
        MOD_CGALVAREZ_METEOR = 'cgalvarez/meteor'

        # Class variables.
        @label        = 'Meteor'
        @hieraclasses = ['meteor']
        @librarian    = {
          MOD_CGALVAREZ_METEOR => {
            :git  => 'git://github.com/cgalvarez/puppet-meteor.git',
            :ver  => '1.0.0',
          },
        }
      end
    end
  end
end
