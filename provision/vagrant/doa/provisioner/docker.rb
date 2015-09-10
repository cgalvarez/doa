#!/usr/bin/ruby

require 'singleton'

module DOA
  module Provisioner
    class Docker
      include Singleton

      # Constants.
      TYPE = 'docker'
    end
  end
end
