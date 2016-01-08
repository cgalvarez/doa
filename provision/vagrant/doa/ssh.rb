#!/usr/bin/ruby

require 'singleton'

module DOA
  class SSH
    include Singleton

    # Constants
    OPT_COMMON = '-o Compression=yes -o CompressionLevel=9 -o IdentitiesOnly=yes ' \
      '-o StrictHostKeyChecking=no -o PasswordAuthentication=no'
    OPT_SCP = "-pqC #{ OPT_COMMON }"
    OPT_SSH = "#{ OPT_COMMON } -o DSAAuthentication=yes"
    OPT_SSH_PASS = '-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o DSAAuthentication=yes'
    OPT_RSYNC = '-o Compression=yes -o IdentitiesOnly=yes -o DSAAuthentication=yes ' \
      '-o StrictHostKeyChecking=no -o PasswordAuthentication=no'

    # Returns absolute path and optionally SSH-ready path (for Windows OS).
    # Params:
    # +folder+:: string containing the path to the folder to parse
    # +ssh_ready+:: boolean; +true+ if has to be parsed for CL SSH path (when Windows OS involved); +false+ otherwise
    def self.escape(os, path, trailing_backslash = false)
      path = "/#{ path }".gsub(':', '') if os == DOA::OS::WINDOWS
      path = "#{ path }/" if trailing_backslash and !path.end_with?('/')
      return path
    end

    def self.ssh(key, user, from_os, to_address, to_os, cmd, cmd_quotes = '"')
      quote = from_os == DOA::OS::WINDOWS ? "'" : ''
      cmd_separator = to_os == DOA::OS::WINDOWS ? ' & ' : ' ; '
      `ssh -l #{ user } #{ OPT_SSH } -i #{ quote }#{ key }#{ quote } #{ to_address } #{ cmd_quotes }#{ cmd.join(cmd_separator) }#{ cmd_quotes }`
      ret = $?.exitstatus
      if ret != 0
        puts DOA::L10n::FAIL_ERROR
        raise SystemExit
      end
      return ret
    end

    def self.ssh_capture(key, user, from_os, to_address, to_os, cmd)
      quote = from_os == DOA::OS::WINDOWS ? "'" : ''
      cmd_separator = to_os == DOA::OS::WINDOWS ? ' & ' : ' ; '
      ret = `ssh -l #{ user } #{ OPT_SSH } -i #{ quote }#{ key }#{ quote } #{ to_address } "#{ cmd.join(cmd_separator) }"`
      if $?.exitstatus != 0
        puts DOA::L10n::FAIL_ERROR
        raise SystemExit
      end
      return ret
    end

    def self.scp(key, from_os, from_path, to_address, to_os, to_path)
      quote = from_os == DOA::OS::WINDOWS ? "'" : ''
      `scp #{ OPT_SCP } -i #{ quote }#{ key }#{ quote } #{ escape(from_os, from_path) } #{ to_address }:#{ SSH.escape(to_os, to_path) }`
      ret = $?.exitstatus
      if ret != 0
        puts DOA::L10n::FAIL_ERROR
        raise SystemExit
      end
      return ret
    end
  end
end
