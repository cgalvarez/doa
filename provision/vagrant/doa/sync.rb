#!/usr/bin/ruby

require 'erb'

module DOA
  class Sync

    # Constants
    OPT_RSYNC       = '-vpaLzr --delete-after --compress-level=9'
    WWW_ROOT        = '/var/www'
    DEFAULT_EXCLUDES= ['node_modules/', 'bower_components/', 'vendor/', 'versions/']
    REGEX_META      = ['(', ')', '[', ']', '{', '}', '.', '?', '+', '*', '/']

    attr_reader :from, :to, :listener, :launcher, :ssh_user, :ssh_key, :rsync_user, :quotes
    attr_accessor :listen_to, :excludes, :ignores, :conditions, :presync
    @conditions     = {}
    @ignores        = []
    @listen_to      = []
    @presync        = []

    def initialize(from, to)
      # Assign default values to class attributes
      @from = from
      @excludes, @listen_to, @ignores, @conditions = [], [], [], {}
      @quotes = @from.os == DOA::OS::WINDOWS ? "'" : ''
      reload_to(to)
    end

    def reload_to(to)
      @to = to
      if @to.instance.instance_of? Guest
        @ssh_user   = DOA::Guest::USER
        @ssh_key    = DOA::Env.guest_insecure_ppk
        @rsync_user = @ssh_user
      elsif @to.instance.instance_of? Host
        @ssh_user   = @to.os == DOA::OS::WINDOWS ? "\\\"#{ @to.user_domain }\\\\#{ @to.user_name }\\\"" : @to.user_name
        @ssh_key    = @from.session.ppk
        @rsync_user = @to.user_name
      end

      # Prepare the object for pre-rsyncing commands
      # IMPORTANT: Use the full path of MinGW/msys ssh exec when Windows host or
      #            you'll get into "connection reset by peer (104)" rsync error.
      ssh_exec = @from.os == DOA::OS::WINDOWS ? `where ssh | grep 'MinGW'`.strip : 'ssh'
      cmd_ssh = "#{ ssh_exec } -l #{ @ssh_user } #{ DOA::SSH::OPT_RSYNC } -i #{ @quotes }#{ @ssh_key }#{ @quotes }"
      @presync = {
          :cmd  => "rsync -e 'ssh -i #{ @from.session.ppk } #{ DOA::SSH::OPT_SSH_PASS }' #{ OPT_RSYNC } --log-file #{ @quotes }#{ @from.session.log_rsync }#{ @quotes }",
          :dirs => {},
        }
    end

    # Starts background-listening the provided paths of the caller machine.
    def start
      if DOA::Guest.provision
        create_presync
        create_launcher
        create_listener
      end
      if !DOA::Guest.presynced
        start_presync
        DOA::Guest.set_presynced(true)
      end
      start_listener
    end

    # Stops background-listening the provided paths of the calling machine.
    def stop
      printf(DOA::L10n::STOP_BG_LISTENING, DOA::Guest.sh_header, @from.hostname)
      case @from.os
      when DOA::OS::WINDOWS
        if @from.instance.instance_of? DOA::Host
          if File.exist?(@from.session.pid)
            pid = nil
            File.open(@from.session.pid, 'r+') { |file| pid = file.read.strip }
            if pid.empty?
              status_msg = DOA::L10n::FAIL_EMPTY_PID
            else
              running = !`powershell -ExecutionPolicy Unrestricted -Command "$i = Get-Process -Id #{ pid } -ErrorAction SilentlyContinue; Echo $i"`.strip.empty?
              if running
                `taskkill /pid #{ pid } /f /t > NUL 2>&1`
                exitstatus = $?.exitstatus
              else
                status_msg = DOA::L10n::WARNING_NOT_RUNNING
              end
            end
          else
            status_msg = DOA::L10n::WARNING_NOT_RUNNING
          end
        end
      when DOA::OS::LINUX
        output = @from.ssh_capture(["ps aux | grep 'ruby #{ @from.session.listener}' | sed /grep/d | awk '{print \$2}'"])
        if output.strip.empty?
          status_msg = DOA::L10n::WARNING_NOT_RUNNING
        else
          exitstatus = @from.ssh(["ps aux | grep 'ruby #{ @from.session.listener}' | sed /grep/d | awk '{print \$2}' | xargs kill -9"])
        end
      end

      puts status_msg.empty? ? (exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR) : status_msg
    end

    def create_listener
      if !@listen_to.empty?
        # Set the contents of the listener script
        printf(DOA::L10n::CREATE_LISTENER, DOA::Guest.sh_header, @from.hostname)
        listener = File.open((@from.instance.instance_of? Guest) ? DOA::Host.session.guest_listener : DOA::Host.session.listener, 'w')
        listener << ERB.new(File.read(DOA::Templates.listener), nil, '-').result(binding)
        listener.close
        puts DOA::L10n::SUCCESS_OK

        if @from.instance.instance_of? Guest
          # Secure copy of the listener script into guest
          printf(DOA::L10n::SCP_LISTENER, DOA::Guest.sh_header, @from.hostname)
          exitstatus = @from.scp(DOA::Host.session.guest_listener, @from.session.listener)
          exitstatus = @from.ssh([
            "sudo chmod 600 #{ @from.session.listener }",
            "sudo chown #{ @from.user }:#{ @from.user } #{ @from.session.listener }",
          ]) if exitstatus == 0
          puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR

          # Install required gems if not present
          printf(DOA::L10n::INSTALL_RUBY_GEMS_LISTENER, DOA::Guest.sh_header, @from.hostname)
          required_gems = ['listen', 'colorize']
          exitstatus = @from.ssh(required_gems.map { |gem|
            "sudo /bin/sh -c 'if ! gem dependency #{ gem } --local >/dev/null 2>&1; then sudo gem install #{ gem }; fi'"
          })
          puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
        end
      end
    end

    def create_presync
      if @from.instance.instance_of? Guest
        # Set the contents of the pre-rsync script
        printf(DOA::L10n::CREATE_PRESYNC, DOA::Guest.sh_header)
        listener = File.open(DOA::Host.session.guest_presync, 'w')
        listener << ERB.new(File.read(DOA::Templates.presync), nil, '-').result(binding)
        listener.close
        puts DOA::L10n::SUCCESS_OK

        # Create DOA hidden folder
        @from.ssh(["mkdir -p #{ DOA::Guest::HOME }/.doa"]) if @from.instance.instance_of?(Guest)

        # Secure copy of the presync script into guest
        printf(DOA::L10n::SCP_PRESYNC, DOA::Guest.sh_header, DOA::Guest.hostname)
        exitstatus = DOA::Guest.scp(DOA::Host.session.guest_presync, DOA::Guest.session.presync)
        puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
      end
    end

    def start_presync
      printf(DOA::L10n::FULL_INITIAL_PRESYNC, DOA::Guest.sh_header, @from.hostname)
      exitstatus = @from.ssh(["ruby #{ @from.session.presync }"])
      puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
    end

    def create_launcher
      case @from.os
      when DOA::OS::WINDOWS
        if @from.instance.instance_of? Host
          # Set the contents of the Powershell script to launch in background the active listening
          printf(DOA::L10n::CREATE_BG_LAUNCHER, DOA::Guest.sh_header, @from.hostname)
          launcher = File.open(@from.session.launcher, 'w')
          launcher << ERB.new(File.read(DOA::Templates.launcher)).result(binding)
          launcher.close
          puts DOA::L10n::SUCCESS_OK
        # TODO
        #elsif if @from.instance.instance_of? Guest
        end
      when DOA::OS::LINUX
        # TODO: Launcher is not necessary, but we want to save the pid in a file...
      end
    end

    def start_listener
      # Launch appropriately
      case @from.os
      when DOA::OS::WINDOWS
        if @from.instance.instance_of? Host
          # Start background-listening
          printf(DOA::L10n::START_BG_LISTENING, DOA::Guest.sh_header, @from.hostname)
          `powershell -ExecutionPolicy Unrestricted -File "#{ @from.session.launcher }" -WindowStyle Hidden` # -NoExit
          puts $?.exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
        # TODO
        #elsif if @from.instance.instance_of? Guest
        end
      when DOA::OS::LINUX
        if @from.instance.instance_of? Host
          printf(DOA::L10n::START_BG_LISTENING, DOA::Guest.sh_header, @from.hostname)
          puts "ruby #{ @from.session.listener } >#{ @from.session.log_listener } 2>&1 &"
          `ruby #{ @from.session.listener } >#{ @from.session.log_listener } 2>&1 &`
          puts $?.exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
        elsif @from.instance.instance_of? Guest
          # Start background-listening
          # TODO: Check that there isn't another background listener process running
          printf(DOA::L10n::START_BG_LISTENING, DOA::Guest.sh_header, @from.hostname)
          exitstatus = @from.ssh(["ruby #{ @from.session.listener } >/dev/null 2>&1 &"])
          puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
        end
      end
    end
  end
end
