#!/usr/bin/ruby

require_relative './doa/env'
require_relative './doa/templates'
require_relative './doa/tools'
require_relative './doa/ssh'
require_relative './doa/os'
require_relative './doa/l10n'
require_relative './doa/settings'
require_relative './doa/host'
require_relative './doa/guest'
require_relative './doa/provider/virtualbox'
require_relative './doa/provisioner/puppet'
require_relative './doa/provisioner/docker'

module DOA
  # Makes the default initialization.
  def self.initialize
    DOA::Env.initialize
    DOA::Templates.initialize
    DOA::Host.initialize

    # Create temp dirs if not exist
    [DOA::Env.tmp_path].each { |filepath|
      Dir.mkdir(filepath) unless File.exists?(filepath) and File.directory?(filepath)
    }
  end
end
