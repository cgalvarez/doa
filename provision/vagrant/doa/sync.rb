#!/usr/bin/ruby

require 'erb'

module DOA
  class Sync

    # Constants
    OPT_RSYNC       = '-vpaLzr --delete-after --compress-level=9'
    WWW_ROOT        = '/var/www'
    DEFAULT_IGNORES = ['(.*\/)*\.git']
    DEFAULT_EXCLUDES= ['.git']
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
          :cmd  => "rsync -e \"#{ cmd_ssh }\" #{ OPT_RSYNC } --log-file #{ @quotes }#{ @from.session.log_rsync }#{ @quotes }",
          :dirs => {},
        }
    end

    # Starts background-listening the provided paths of the caller machine.
    def start
      create_listener
      create_launcher
      start_listener
    end

    # Stops background-listening the provided paths of the calling machine.
    def stop
      printf(DOA::L10n::STOP_BG_LISTENING, DOA::Guest.sh_header, @from.hostname)
      case @from.os
      when DOA::OS::WINDOWS
        if @from.instance.instance_of? Host
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
      DOA::Guest.settings[DOA::Setting::PROJECTS].each do |project, config|
        if config.has_key?(DOA::Setting::PROJECT_STACK) and config[DOA::Setting::PROJECT_STACK].is_a?(Hash)
          vm_www_root = DOA::Tools.check_get(DOA::Guest.settings, DOA::Tools::TYPE_STRING,
            [DOA::Guest.settings[DOA::Setting::HOSTNAME], DOA::Setting::WWW_ROOT], DOA::Setting::WWW_ROOT, '')
          site_www_root = DOA::Tools.check_get(config, DOA::Tools::TYPE_STRING,
            [DOA::Guest.settings[DOA::Setting::HOSTNAME], project, DOA::Setting::PROJECT_WWW_ROOT], DOA::Setting::PROJECT_WWW_ROOT, '')
          if !site_www_root.empty?
            root = site_www_root
          elsif !vm_www_root.empty?
            root = "#{ vm_www_root }/#{ project }"
          else
            root = "#{ Sync::WWW_ROOT }/#{ project }"
          end
          config[DOA::Setting::PROJECT_STACK].each do |sw, setup|
            case sw
            when DOA::Setting::SW_WP
              setup_listener_for_wordpress_site(project, root, setup)
            end
          end
        end
      end

      # Set the contents of the listener script
      if !@listen_to.empty?
        printf(DOA::L10n::CREATE_LISTENER, DOA::Guest.sh_header, @from.hostname)
        listener = File.open((@from.instance.instance_of? Guest) ? DOA::Host.session.guest_listener : DOA::Host.session.listener, 'w')
        listener << ERB.new(File.read(DOA::Templates.listener), nil, '-').result(binding)
        listener.close
        puts DOA::L10n::SUCCESS_OK
      end
    end

    def create_launcher
      if !@listen_to.empty?
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
    end

    def start_listener
      if !@listen_to.empty?
        # Pre-rsync when required
        if @from.instance.instance_of?(Guest) and !@presync[:dirs].empty?
          printf(DOA::L10n::FULL_INITIAL_BIRSYNC, DOA::Guest.sh_header, @from.hostname, @to.hostname)
          synced, total, failed = 0, @presync[:dirs].size, []
          @presync[:dirs].each do |from, settings|
            excludes = settings[:exclude].empty? ? '' : "--exclude '#{ settings[:exclude].join("' --exclude '") }'"
            exitstatus = DOA::Guest.ssh(["#{ @presync[:cmd] } #{ excludes } #{ from } #{ @rsync_user }@#{ @to.hostname }:#{ settings[:to] }"], "'")
            if exitstatus == 0
              synced += 1
            else
              failed.push(from)
            end
          end
          colour = case synced
            when 0 then :red
            when total then :green
            else :yellow
            end
          puts '[' + "#{ synced }/#{ total }".colorize(colour) + ']'
          printf(DOA::L10n::FAILED_SYNC, DOA::Guest.sh_header, "#{ DOA::Guest.sh_header }    - #{ failed.join("\n#{ DOA::Guest.sh_header }    - ")}") if !failed.empty?
        end

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
            `ruby #{ @from.session.listener } >/dev/null 2>&1 &`
            puts $?.exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
          elsif @from.instance.instance_of? Guest
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

            # Start background-listening
            # TODO: Check that there isn't another background listener process running
            printf(DOA::L10n::START_BG_LISTENING, DOA::Guest.sh_header, @from.hostname)
            exitstatus = @from.ssh(["ruby #{ @from.session.listener } >/dev/null 2>&1 &"])
            puts exitstatus == 0 ? DOA::L10n::SUCCESS_OK : DOA::L10n::FAIL_ERROR
          end
        end
      end
    end

    def setup_listener_for_wordpress_site(fqdn, root, setup)
      [DOA::Setting::WP_ASSET_PLUGIN, DOA::Setting::WP_ASSET_THEME].each do |type|
        if setup.has_key?(type)
          setup[type].each do |asset, params|
            sync_mode = (params.has_key?(DOA::Setting::ASSET_SYNC_MODE) and
                params[DOA::Setting::ASSET_SYNC_MODE].is_a? String and
                !params[DOA::Setting::ASSET_SYNC_MODE].empty?) ?
              params[DOA::Setting::ASSET_SYNC_MODE] : DOA::Setting::SYNC_BRSYNC
            path = DOA::Tools.check_get(params, DOA::Tools::TYPE_STRING,
              [DOA::Guest.settings[DOA::Setting::HOSTNAME], fqdn, DOA::Setting::SW_WP,
                asset, DOA::Setting::ASSET_PATH], DOA::Setting::ASSET_PATH, '')

            if sync_mode == DOA::Setting::SYNC_BRSYNC and !path.empty?
              # Build the from/to absolute paths
              from_path = (Pathname.new(path)).absolute? ? path : File.expand_path(path)
              to_path = "#{ root }/wp-content/#{ type }/#{ asset }"
              from_path, to_path = to_path, from_path if @from.instance.instance_of? Guest

              # Prepare the rsync exclusions and listen ignores
              @listen_to.insert(-1, from_path)
              asset_excludes = DOA::Tools.check_get(params, DOA::Tools::TYPE_ARRAY,
                [DOA::Guest.settings[DOA::Setting::HOSTNAME], fqdn, DOA::Setting::SW_WP,
                  asset, DOA::Setting::ASSET_EXCLUDE], DOA::Setting::ASSET_EXCLUDE, [])
              all_excludes = DOA::Sync::DEFAULT_IGNORES | asset_excludes
              @excludes.push(*(all_excludes.map { |rgx| "#{ from_path }/#{ rgx }" }))
              @ignores.push(*(all_excludes.map { |rgx|
                # Escape regex metacharacters: (, ), [, ], {, }, ., ?, +, *
                path = "#{ from_path }/#{ rgx }"
                DOA::Sync::REGEX_META.each { |meta|
                  path = path.gsub(/(?<!\\)#{ Regexp.escape(meta) }/, "\\#{ meta }")
                }
                path = path.gsub(/(?<!\.)\*/, ".*")
              }))
              # When rsyncing, origin path must end with a backslash, but not the target path
              # in order to sync the contents of both paths and avoid creating new folders
              @conditions[from_path] = "`\#{ cmd_partial_rsync } " \
                "#{ DOA::SSH.escape(@from.os, from_path, true) } " \
                "#{ @rsync_user }@#{ @to.hostname }:#{ DOA::SSH.escape(@to.os, to_path) }`"
            end
          end
        end
      end
    end
  end
end
