#!/usr/bin/ruby

class PuppetModule
  # Constants.
  GLUE_NAMESPACE  = '::'
  GLUE_METHOD     = '#'
  GLUE_PARAMS     = '@'
  GLUE_ITEMS      = ','
  GLUE_KEYS       = DOA::Tools::GLUE_KEYS # '->'
  VALIDATORS = [
    :array,
    :array_ips,
    :array_ipv4,
    :array_ipv6,
    :auto,
    :boolean,
    :chmod,
    :float,
    :hash_flags,
    :hash_values,
    :integer,
    :ip,
    :ipv4,
    :ipv4_port,
    :ipv6,
    :level,
    :linux_package_name,
    :port,
    :puppet_interpolable_string,
    :puppet_interpolable_uri,
    :semver_branch,
    :semver_version,
    :string,
    :unix_abspath,
    :unix_path,
    :unix_relpath,
    :url,
  ]
  # Validators to enclose between single quotes
  VALIDATORS_TO_WRAP = [
    :auto,
    :chmod,
    :ipv4,
    :ipv4_port,
    :ipv6,
    :level,
    :linux_package_name,
    :puppet_interpolable_string,
    :puppet_interpolable_uri,
    :semver_branch,
    :semver_version,
    :string,
    :unix_abspath,
    :unix_path,
    :unix_relpath,
    :url,
  ]

  # Class variables.
  @label        = nil
  @branch       = nil
  @version      = nil
  @provided     = nil
  @allow_branch = nil
  @hieraclasses = nil
  @puppetfile   = nil
  @librarian    = nil
  @supported    = {}

  # Getters
  def self.label
    @label
  end
  def self.supported
    @supported
  end

  def self.check_unsupported_first_level_params(supported, provided)
    provided.each do |param, config|
      if !supported.has_key?(param)
        puts sprintf(DOA::L10n::UNRECOGNIZED_SW_PARAM, DOA::Guest.sh_header, DOA::Guest.hostname,
          DOA::Guest.provisioner.current_project.nil? ? 'machine stack' : DOA::Guest.provisioner.current_project,
          @label.downcase, param).colorize(:red)
        raise SystemExit
      end
    end
  end

  def self.set_params(supported, provided = {})
    stack_settings = {}

    # Check for disallowed parameters
    check_unsupported_first_level_params(supported, provided)

    supported.each do |param, config|
      # Check for mutually exclusive parameters
      if config.has_key?(:exclude) and provided.has_key?(param)
        config[:exclude] = [config[:exclude]] if !config[:exclude].is_a?(Array)
        config[:exclude].each do |exclusive|
          keys = exclusive.split(GLUE_KEYS)
          found, recursion, last = false, @provided, keys.last
          keys.each do |key|
            if recursion.has_key?(key)
              recursion = recursion[key]
              found = true if key == last
            else
              break
            end
          end
          if found
            puts sprintf(DOA::L10n::EXCLUSIVE_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
              DOA::Guest.provisioner.current_project, @label.downcase, param, exclusive).colorize(:red)
            raise SystemExit
          end
        end
      end

      valid, value = true, nil

      # Recursive self call for parameter children
      if config.has_key?(:children)
        if provided.has_key?(param)
          children_provided = set_params(config[:children],
            (provided[param].is_a?(Hash) and !provided[param].blank?) ? provided[param] : {})
          stack_settings = stack_settings.deep_merge(children_provided) if children_provided.present?
        end
      # Recursive self call for hash of children items
      elsif config.has_key?(:children_hash)
        if provided.has_key?(param)
          if provided[param].is_a?(Hash) and !provided[param].blank?
            children_hash = {}
            provided[param].each do |child_key, child_config|
              children_hash["'#{child_key}'"] = set_params(config[:children_hash], child_config)
            end
            value = children_hash
          else
            puts "debe ser hash y no vacio"
          end
        end
      # Process provided parameter
      else
        if config.has_key?(:expect) and !config[:expect].nil?
          config[:expect] = [config[:expect]] if !config[:expect].is_a?(Array)
        end

        # Get the default value to apply
        doa_def = get_default_value(config, :doa_def)
        mod_def = get_default_value(config, :mod_def)
        default = case doa_def
          when nil then mod_def
          else (doa_def != mod_def) ? doa_def : nil
          end

        (doa_def != mod_def or doa_def.nil?)
        # Set default value when non provided and DOA default differs from puppet module default
        if !provided.has_key?(param) or provided[param].blank?
          value = default if !default.nil? and default != mod_def
        # Set provided value provided in input YAML for current machine if different from defaults
        elsif provided[param].to_s != mod_def #default
          # Check if value is included in the allowed subset whenever present
          if config.has_key?(:allow)
            if provided[param].is_a?(Array) and !(provided[param] - config[:allow]).empty? or !config[:allow].include?(provided[param].to_s)
              puts sprintf(DOA::L10n::UNSUPPORTED_VALUE_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                DOA::Guest.provisioner.current_project, @label.downcase, provided[param], param).colorize(:red)
              raise SystemExit
            end
          end
          # Validation against callback or :expect type
          cb_validate = []
          if config.has_key?(:cb_validate)
            cb_validate.insert(-1, config[:cb_validate])
          elsif config.has_key?(:expect) and !config[:expect].empty?
            config[:expect].each do |expected|
              if VALIDATORS.include?(expected)
                cb_validate.insert(-1, "DOA::Tools#valid_#{ expected.to_s }?");
              else
                puts sprintf(DOA::L10n::UNSUPPORTED_VALUE_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
                  DOA::Guest.provisioner.current_project, @label.downcase, expected.to_s, :expect.to_s).colorize(:red)
                raise SystemExit
              end
            end
          end

          valid_cb = false
          cb_validate.each do |cb|
            parts = cb.split(GLUE_PARAMS)
            params = (parts.size == 2 ? parts[1].split(GLUE_ITEMS) : []).insert(0, provided[param])
            cb_tokens = parts[0].split(GLUE_METHOD)
            valid_cb ||= cb_tokens[0].split(GLUE_NAMESPACE).reduce(Module, :const_get).send(cb_tokens[1].to_s, *params)
            break if valid_cb
          end
          valid = valid_cb
          value = (provided[param].is_a?(Hash) or provided[param].is_a?(Array)) ? provided[param] : provided[param].to_s ####
        end
      end

      # Custom processing of the parameter value
      if valid
        if config.has_key?(:cb_process)
          parts = config[:cb_process].split(GLUE_PARAMS)
          params = (parts.size == 2 ? parts[1].split(GLUE_ITEMS) : []).insert(0, provided[param])
          cb_tokens = parts[0].split(GLUE_METHOD)
          value = cb_tokens[0].split(GLUE_NAMESPACE).reduce(Module, :const_get).send(cb_tokens[1].to_s, *params)
        end
      else
        puts sprintf(DOA::L10n::UNSUPPORTED_PARAM_VALUE_CTX_SW, DOA::Guest.sh_header, DOA::Guest.hostname,
          DOA::Guest.provisioner.current_project, @label.downcase, param).colorize(:red)
        raise SystemExit
      end

      ###if !value.nil? and config.has_key?(:maps_to) and !config[:maps_to].blank?
      if !value.nil? #and config.has_key?(:maps_to) and !config[:maps_to].blank?
        # Some types need a preprocess to be properly wrapped
        if config[:expect].is_a?(Array) and
            (config[:expect].include?(:hash_flags) or config[:expect].include?(:hash_values))
          new_value = {}
          value.each do |k, v|
            if v.is_a?(FalseClass) or v == 'off'
              new_value["'#{k}'"] = "'off'"
            elsif v.is_a?(TrueClass) or v == 'on'
              new_value["'#{k}'"] = "'on'"
            else
              new_value["'#{k}'"] = "'#{v}'"
            end
          end
          value = new_value
        end

        # Assign value when catched
        maps_to = (config.has_key?(:maps_to) and !config[:maps_to].blank?) ? config[:maps_to] : param
        ###stack_settings[config[:maps_to]] = case config.has_key?(:expect)
        stack_settings[maps_to] = case config.has_key?(:expect)
          when true then case (config[:expect] & VALIDATORS_TO_WRAP).size
            when 0 then value
            else "'#{ value.to_s }'"
            end
          else value
          end
      end
    end
    return stack_settings
  end

  # Adds the required parameters to the corresponding queues:
  #  - Puppet Forge modules (loaded through librarian-puppet -> Puppetfile)
  #  - Classes (loaded through Hiera -> hostname.yaml)
  #  - Relationships (chaining arrows inside -> site.pp)
  # and recursively checks all parameters for the requested software,
  # setting the appropriate values.
  def self.setup(settings)
    @provided = settings
    DOA::Provisioner::Puppet.enqueue_librarian_mods(@librarian) if @librarian.is_a?(Hash) and !@librarian.blank?
    DOA::Provisioner::Puppet.enqueue_hiera_classes(@hieraclasses) if @hieraclasses.is_a?(Array) and !@hieraclasses.blank?
    DOA::Provisioner::Puppet.enqueue_hiera_params(@label, set_params(@supported, (!settings.nil? and settings.is_a?(Hash)) ? settings : {})) if !@supported.empty?
    self.send('custom_setup', @provided) if self.respond_to?('custom_setup')
  end

  def self.get_default_value(config, type = :doa_def)
    def_val, config_os, env = nil, nil, DOA::Guest.env
    os_family     = DOA::Provisioner::Puppet.os_family
    os_distro     = DOA::Provisioner::Puppet.os_distro
    os_distro_ver = DOA::Provisioner::Puppet.os_distro_ver
    def_val       = config['default'] if config.has_key?(type) and config[type].is_a?(Hash) and config[type].has_key?('default')

    config_os = nil
    if config.has_key?(type)
      # Unique generic value (not a hash)
      if config[type].is_a?(Hash)
        # Check for requested environment
        if config[type].has_key?(env)
          # Hash of default values
          if config[type][env].is_a?(Hash)
            # If os families is a hash, then check for a specific distro
            if config[type][env].has_key?(os_family)
              config_os = config[type][os_family]
            else
              puts "error"
            end
          else
            def_val = config[type][env]
          end
        elsif config[type].has_key?(os_family)
          config_os = config[type]
        end
      else
        def_val = config[type]
      end
    end
    if def_val.nil? and !config_os.nil?
      if config_os[os_family].is_a?(Hash)
        # If os distro is a hash, then check for a specific distro version
        if !config_os[os_family].has_key?(os_distro)
          puts "error"
        elsif config_os[os_family][os_distro].is_a?(Hash)
          if !config_os[os_family][os_distro].has_key?(os_distro_ver) or
              config_os[os_family][os_distro][os_distro_ver].is_a?(Hash)
            puts "error"
          else
            def_val = config_os[os_family][os_distro][os_distro_ver]
          end
        else
          def_val = config_os[os_family][os_distro]
        end
      else
        def_val = config_os[os_family]
      end
    end

    def_val
  end

  def self.process_version(value, classname, keys = '')
    # Branch (with .x)
    if DOA::Tools::valid_version?(value, [], [], false, true)
      @branch = value.gsub(/\.[xX]/, '')
    # Specific version
    elsif DOA::Tools::valid_version?(value, [], [], true, false)
      @branch = value.match(DOA::Tools::RGX_SEMVER_MINOR).captures[0]
    # :allow value
    else
      @branch = value
    end

    # Check support for provided branch
    if @allow_branch.nil? or @allow_branch.include?(@branch)
      # Specific versions or branches automatically ensure 'held', no
      # matter the user value (if provided)
      @version = value.match(DOA::Tools::RGX_SEMVER).captures[0].gsub('X', 'x')
      @provided['ensure'] = (@branch != @version) ? 'held' :
        get_default_value(@supported['ensure'], :doa_def)
      DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
        "#{ classname }::version" => "'#{ @version }'",
      })
    else
      puts sprintf(DOA::L10n::NOT_SUPPORTED_BRANCH, DOA::Guest.sh_header, DOA::Guest.hostname,
        DOA::Guest.provisioner.current_project, @label.downcase, @label, value).colorize(:red)
      raise SystemExit
    end
    nil
  end

  def self.empty(value)
    nil
  end
end
