#!/usr/bin/ruby

class PuppetModule
  # Constants.
  GLUE_NAMESPACE  = '::'
  GLUE_METHOD     = '#'
  GLUE_PARAMS     = '@'
  GLUE_ITEMS      = ','
  GLUE_KEYS       = DOA::Tools::GLUE_KEYS
  VALIDATORS = [
    :array,
    :array_ips,
    :array_ipv4,
    :array_ipv6,
    :auto,
    :boolean,
    :chmod,
    :float,
    :hash,
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

  def self.set_params(path = [], supported = @supported)
    queue = {}
    supported.recursive_get(path, DOA::L10n::UNRECOGNIZED_PARAM).each do |param, config|
      valid, value, default, doa_def, mod_def = true, nil, nil, nil, nil
      provided = @provided.recursive_get(path + [param], nil, true)
      config[:expect] = [config[:expect]] if config.has_key?(:expect) and !config[:expect].is_a?(Array)

      # Check for mutually exclusive parameters
      if config.has_key?(:exclude) and !provided.nil?
        config[:exclude] = [config[:exclude]] if !config[:exclude].is_a?(Array)
        config[:exclude].each do |exclusive|
          if !@provided.recursive_get(exclusive.split(GLUE_KEYS), nil, true).nil?
            DOA::L10n::print(DOA::L10n::EXCLUSIVE_PARAMS, DOA::L10n::MSG_TYPE_ERROR,
              [DOA::Guest.provisioner.current_project, @label.downcase], [param, exclusive], true)
          end
        end
      end

      # Recursive self call for parameter children
      if config.has_key?(:children)
        children_to_queue = set_params(path + [param, :children], supported)
        queue = queue.deep_merge(children_to_queue) if children_to_queue.present?
      # Recursive self call for hash of children items
      elsif config.has_key?(:children_hash)
        if !provided.nil?
          DOA::L10n::print(DOA::L10n::UNSUPPORTED_PARAM_VALUE, DOA::L10n::MSG_TYPE_ERROR,
            [DOA::Guest.provisioner.current_project, @label.downcase], [param], true) if !provided.is_a?(Hash) or provided.blank?
          value = {}
          provided.each do |child, child_config|
            value["'#{ child }'"] = set_params(path + [param, :children_hash, child], supported)
          end
        end
      # Process provided parameter
      else
        # Get the default value to apply
        doa_def = get_default_value(config, :doa_def)
        mod_def = get_default_value(config, :mod_def)
        default = case doa_def
          when nil then mod_def
          else (doa_def != mod_def) ? doa_def : nil
          end

        # Set default value when non provided and DOA default differs from puppet module default
        if provided.nil?
          value = default if !default.nil? and default != mod_def
        # Set provided value if differs from puppet module default
        elsif provided.to_s != mod_def
          # Check if provided value is included in the allowed subset whenever present
          if config.has_key?(:allow)
            if provided.is_a?(Array) and !(provided - config[:allow]).empty? or !config[:allow].include?(provided.to_s)
              DOA::L10n::print(DOA::L10n::UNSUPPORTED_VALUE, DOA::L10n::MSG_TYPE_ERROR,
                [DOA::Guest.provisioner.current_project, @label.downcase], [provided, param], true)
            end
          end

          # Create an array with all validation callbacks (from either :cb_validate or :expect)
          cb_validate = []
          if config.has_key?(:cb_validate)
            cb_validate.insert(-1, config[:cb_validate])
          elsif config.has_key?(:expect) and !config[:expect].empty?
            config[:expect].each do |expected|
              if VALIDATORS.include?(expected)
                cb_validate.insert(-1, "DOA::Tools#valid_#{ expected.to_s }?");
              else
                DOA::L10n::print(DOA::L10n::UNSUPPORTED_VALUE, DOA::L10n::MSG_TYPE_ERROR,
                  [DOA::Guest.provisioner.current_project, @label.downcase], [expected.to_s, :expect.to_s], true)
              end
            end
          end

          # Perform validation (exit on the first successful validation)
          if !cb_validate.empty?
            valid = false
            cb_validate.each do |cb|
              parts = cb.split(GLUE_PARAMS)
              params = (parts.size == 2 ? parts[1].split(GLUE_ITEMS) : []).insert(0, provided)
              cb_tokens = parts[0].split(GLUE_METHOD)
              valid = cb_tokens[0].split(GLUE_NAMESPACE).reduce(Module, :const_get).send(cb_tokens[1].to_s, *params)
              break if valid
            end
          end
          value = (provided.is_a?(Hash) or provided.is_a?(Array)) ? provided : provided.to_s
        end
      end

      # Custom processing of the parameter value (through @supported callback)
      if valid
        if config.has_key?(:cb_process)
          parts = config[:cb_process].split(GLUE_PARAMS)
          params = (parts.size == 2 ? parts[1].split(GLUE_ITEMS) : []).insert(0, provided)
          cb_tokens = parts[0].split(GLUE_METHOD)
          value = cb_tokens[0].split(GLUE_NAMESPACE).reduce(Module, :const_get).send(cb_tokens[1].to_s, *params)
        end
      else
        DOA::L10n::print(DOA::L10n::UNSUPPORTED_PARAM_VALUE, DOA::L10n::MSG_TYPE_ERROR,
          [DOA::Guest.provisioner.current_project, @label.downcase], [param], true)
      end

      if !value.nil? and value != mod_def
        # Some types need a preprocess to be properly wrapped
        if config[:expect].is_a?(Array) and
            (config[:expect].include?(:hash_flags) or config[:expect].include?(:hash_values))
          new_value = {}
          value.each do |k, v|
            if v.is_a?(FalseClass) or v == 'off'
              new_value["'#{ k }'"] = "'off'"
            elsif v.is_a?(TrueClass) or v == 'on'
              new_value["'#{ k }'"] = "'on'"
            else
              new_value["'#{ k }'"] = "'#{ v }'"
            end
          end
          value = new_value
        end

        # Assign value when catched
        maps_to = (config.has_key?(:maps_to) and !config[:maps_to].blank?) ? config[:maps_to] : param
        queue[maps_to] = case config.has_key?(:expect)
          when true then case (config[:expect] & VALIDATORS_TO_WRAP).size
            when 0 then value
            else "'#{ value.to_s }'"
            end
          else value
          end
      end
    end

    return queue
  end

  # Adds the required parameters to the corresponding queues:
  #  - Puppet Forge modules (loaded through librarian-puppet -> Puppetfile)
  #  - Classes (loaded through Hiera -> hostname.yaml)
  #  - Relationships (chaining arrows inside -> site.pp)
  # and recursively checks all parameters for the requested software,
  # setting the appropriate values.
  def self.setup(settings)
    @provided = settings.is_a?(Hash) ? settings : {}
    DOA::Provisioner::Puppet.enqueue_librarian_mods(@librarian) if @librarian.is_a?(Hash) and !@librarian.blank?
    DOA::Provisioner::Puppet.enqueue_hiera_classes(@hieraclasses) if @hieraclasses.is_a?(Array) and !@hieraclasses.blank?
    DOA::Provisioner::Puppet.enqueue_hiera_params(@label, set_params()) if !@supported.empty?
    self.send('custom_setup', @provided) if self.respond_to?('custom_setup')
  end

  def self.get_default_value(config, type = :doa_def)
    def_val, config_os, env = nil, nil, DOA::Guest.env
    os_family     = DOA::Provisioner::Puppet.os_family
    os_distro     = DOA::Provisioner::Puppet.os_distro
    os_distro_ver = DOA::Provisioner::Puppet.os_distro_ver
    def_val       = config['default'] if config.has_key?(type) and config[type].is_a?(Hash) and config[type].has_key?('default')
    hash_expected = ((!config[:expect].is_a?(Array) and config[:expect] == :hash_values) or
      (config[:expect].is_a?(Array) and config[:expect].include?(:hash_values)))

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
            elsif hash_expected
              def_val = config[type][env]
            else
              puts "error 1"
            end
          else
            def_val = config[type][env]
          end
        elsif config[type].has_key?(os_family)
          config_os = config[type]
        else
          def_val = config[type]
        end
      else
        def_val = config[type]
      end
    end
    if def_val.nil? and !config_os.nil?
      if config_os[os_family].is_a?(Hash)
        # If os distro is a hash, then check for a specific distro version
        if !config_os[os_family].has_key?(os_distro)
          puts "error 2"
        elsif config_os[os_family][os_distro].is_a?(Hash)
          if !config_os[os_family][os_distro].has_key?(os_distro_ver) or
              config_os[os_family][os_distro][os_distro_ver].is_a?(Hash)
            puts "error 3"
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
      if !value.nil?
        # Specific versions or branches automatically ensure 'held', no
        # matter the user value (if provided)
        @version = value.match(DOA::Tools::RGX_SEMVER).captures[0].gsub('X', 'x')
        @provided['ensure'] = (@branch != @version) ? 'held' :
          get_default_value(@supported['ensure'], :doa_def)
        DOA::Provisioner::Puppet.enqueue_hiera_params(@label, {
          "#{ classname }::version" => "'#{ @version }'",
        })
      end
    else
      DOA::L10n::print(DOA::L10n::NOT_SUPPORTED_BRANCH, DOA::L10n::MSG_TYPE_ERROR,
        [DOA::Guest.provisioner.current_project, @label.downcase], [@label, value], true)
    end
    nil
  end

  def self.empty(value)
    nil
  end
end
