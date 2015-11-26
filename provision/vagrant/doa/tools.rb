#!/usr/bin/ruby

module DOA
  class Tools

    # Constants
    TYPE_STRING         = 'String'
    TYPE_INTEGER        = 'Integer'
    TYPE_ARRAY          = 'Array'
    TYPE_HASH           = 'Hash'
    MSG_MISSING_VALUE   = 'missing_value'
    MSG_WRONG_VALUE     = 'wrong_value'
    MSG_WRONG_TYPE      = 'wrong_type'
    # Regex for Linux package name validator
    # See: http://www.linuxquestions.org/questions/slackware-14/characters-allowed-in-package-name-and-version-string-4175552002/
    RGX_LEVEL           = /\A[12](:[12])*\z/
    RGX_INTEGER         = /\A\d+\z/
    RGX_CHMOD           = /\A0[0-7]{3}\z/
    RGX_LINUX_PKG_NAME  = /\A[a-zA-Z0-9][.+@\-\w]+\z/
    RGX_STRING_INT      = /\A\d+\z/
    # Puppet variables regex: https://docs.puppetlabs.com/puppet/latest/reference/lang_variables.html#regular-expressions-for-variable-names
    RGX_PUPPET_INTERPOLABLE_URI_SOURCE = /\A(?:(?:puppet|file):\/\/)?(?:(?:[.\w-]*%\{(?:hiera|scope)\('(?:(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*)'\)\}[.\w-]*|[.\w-]*%\{::[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|[.\w-]*\$\{(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|[.\w-]*\$\{[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|[.\w-]*\$[a-z0-9_][a-zA-Z0-9_]*[.\w-]*)?(?:\/[.\w-]*%\{(?:hiera|scope)\('(?:(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*)'\)\}[.\w-]*|\/[.\w-]*%\{::[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|\/[.\w-]*\$\{(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|\/[.\w-]*\$\{[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|\/[.\w-]*\$[a-z0-9_][a-zA-Z0-9_]*[.\w-]*|\/[.\w-]+)*(?:\/[.\w-]*%\{(?:hiera|scope)\('(?:(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*)'\)\}[.\w-]*|\/[.\w-]*%\{::[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|\/[.\w-]*\$\{(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|\/[.\w-]*\$\{[a-z0-9_][a-zA-Z0-9_]*\}[.\w-]*|\/[.\w-]*\$[a-z0-9_][a-zA-Z0-9_]*[.\w-]*|\/[.\w-]+)+)\z/
    RGX_PUPPET_INTERPOLABLE_STRING = /\A(?:%\{(?:hiera|scope)\('(?:(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*)'\)\}|%\{::[a-z0-9_][a-zA-Z0-9_]*\}|\$\{(?:[a-z][a-z0-9_]*)?(?:::[a-z][a-z0-9_]*)*::[a-z0-9_][a-zA-Z0-9_]*\}|\$\{[a-z0-9_][a-zA-Z0-9_]*\}|\$[a-z0-9_][a-zA-Z0-9_]*|(?:(?!hiera|scope|\$|%).)+)+\z/
    RGX_UNIX_ABSPATH    = /\A(?:\/[.\w-]+)+\z/
    RGX_UNIX_RELPATH    = /\A(?:[.\w-]+\/?)+\z/
    RGX_UNIX_PATH       = /\A(?:\/?[.\w-]+\/?)+\z/
    RGX_IPV4            = /\A((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\z/ #/\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/
    RGX_IPV4_PORT       = /\A((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])(:(6553[0-5]|654[0-9]{2}|65[0-4][0-9]{3}|6[0-4][0-9]{3}|[0-5]?[0-9]{1,4}))?\z/
    RGX_PORT            = /\A(6553[0-5]|654[0-9]{2}|65[0-4][0-9]{3}|6[0-4][0-9]{3}|[0-5]?[0-9]{1,4})\z/
    # IPv6 regex. See http://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses
    RGX_IPV6 = /\A(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|[fF][eE]80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::([fF]{4}(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\z/
    RGX_SEMVER_VERSION  = /\A(\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\z/
    RGX_SEMVER_BRANCH   = /\A(\d+\.[xX]|\d+\.\d+\.[xX])\z/
    RGX_SEMVER          = /\A((\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))|(\d+\.([0-9]+\.([0-9]+|[xX])|[xX])))?\z/
    #RGX_SEMVER_MINOR    = /\A(\d+\.\d+)\.\d+(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?\z/
    RGX_SEMVER_MINOR    = /\A(\d+\.\d+)(?:\..*)\z/
    MAX_PORT            = 65535
    MIN_PORT            = 0
    YAML_TAB            = '  '
    # GLUE
    GLUE_KEYS           = '->'


    # Gets the value of a setting with type integer.
    # Params:
    # +var+:: variable from which check and retrieve the value
    # +type+:: type of the value; allowed: {Integer | String}
    # +ctx+:: parameters passed to printed commands to easily locate the error/warning
    # +key+:: [OPTIONAL] key when +var+ is Hash type for accessing one of its elements
    # +default+:: [OPTIONAL] default value if not provided; only used in conjunction with +key+
    # +empty+:: [OPTIONAL] allow for empty values (but not nil). Default: false
    # +vmin+:: minimum value allowed for the value of Integer types (included)
    # +vmax+:: maximum value allowed for the value of Integer types (included)
    def self.check_get(var, type, ctx, key = nil, default = nil, empty = false, vmin = nil, vmax = nil)
      value, abort, msg, msg_type = nil, '', '', ''
      if var.nil? or (!key.nil? and key.is_a?(String) and !key.empty? and var.is_a?(Hash) and (!var.has_key?(key) or var[key].nil?))
        if default.nil?
          msg_type = Tools::MSG_MISSING_VALUE
        elsif
          value = default
        end
      else
        var_class = case type
          when DOA::Tools::TYPE_INTEGER then Integer
          when DOA::Tools::TYPE_STRING then String
          when DOA::Tools::TYPE_ARRAY then Array
          when DOA::Tools::TYPE_HASH then Hash
          end
        case type
        when DOA::Tools::TYPE_INTEGER, DOA::Tools::TYPE_STRING, DOA::Tools::TYPE_ARRAY, DOA::Tools::TYPE_HASH
          if key.nil?
            # Without key and not its type
            if !var.is_a?(var_class)
              if type == DOA::Tools::TYPE_INTEGER and var.is_a?(String)
                if !/\A\d+\z/.match(var) or (!vmin.nil? and var.to_i < vmin) or (!vmax.nil? and var.to_i > vmax)
                  msg_type = Tools::MSG_WRONG_VALUE
                else
                  value = var.to_i
                end
              else
                msg_type = Tools::MSG_WRONG_TYPE ##
              end
            # Without key and its type
            else
              if type == DOA::Tools::TYPE_INTEGER
                value = var if (vmin.nil? or var >= vmin) and (vmax.nil? or var <= vmax)
              elsif !empty and var.empty?
                msg_type = Tools::MSG_MISSING_VALUE
              else
                value = var
              end
            end
          # With key
          elsif key.is_a?(String) and !key.empty?
            # Parent is hash
            if var.is_a?(Hash)
              ctx[-1] = key
              # Key does not exist
              if !var.has_key?(key)
                msg_type = Tools::MSG_MISSING_VALUE
              # Child not of its type
              elsif !var[key].is_a?(var_class)
                if type == DOA::Tools::TYPE_INTEGER and var[key].is_a?(String)
                  if !/\A\d+\z/.match(var) or (!vmin.nil? and var.to_i < vmin) or (!vmax.nil? and var.to_i > vmax)
                    msg_type = Tools::MSG_WRONG_VALUE
                  else
                    value = var.to_i
                  end
                else
                  msg_type = Tools::MSG_WRONG_TYPE
                end
              # Child of its type
              else
                if type == DOA::Tools::TYPE_INTEGER
                  value = var[key] if (vmin.nil? or var[key] >= vmin) and (vmax.nil? or var[key] <= vmax)
                elsif !empty and var[key].empty?
                  msg_type = Tools::MSG_MISSING_VALUE
                else
                  value = var[key]
                end
                ###value = var[key]
              end
            # Parent is not hash
            else
              msg_type = Tools::MSG_WRONG_TYPE
            end
          end
        else
          puts (sprintf "%s ERROR: The type '%s' has no checking support", *args).colorize(:red) #########
          raise SystemExit
        end
        msg_type = Tools::MSG_WRONG_TYPE if value.nil? and msg_type.empty?
      end

      # Get message string and its input arguments when
      case msg_type
      when Tools::MSG_MISSING_VALUE
        msg = case ctx.size
          when 2 then DOA::L10n::MISSING_PARAM_TYPE_CTX_VM
          when 3 then DOA::L10n::MISSING_PARAM_TYPE_CTX_PROJECT
          when 4 then DOA::L10n::MISSING_PARAM_TYPE_CTX_SW
          when 5 then DOA::L10n::MISSING_PARAM_TYPE_CTX_ASSET
          end
      when Tools::MSG_WRONG_TYPE
        msg = case ctx.size
          when 2 then DOA::L10n::WRONG_TYPE_CTX_VM
          when 3 then DOA::L10n::WRONG_TYPE_CTX_PROJECT
          when 4 then DOA::L10n::WRONG_TYPE_CTX_SW
          when 5 then DOA::L10n::WRONG_TYPE_CTX_ASSET
          end
      end

      if !msg.empty?
        args = ctx.unshift(DOA::Guest.sh_header).insert(-1, type)
        puts (sprintf msg, *args).colorize(:red)
        raise SystemExit
      end
      return value
    end

    # Returns +true+ if +check+ is a non-empty hash of values (anything but array or hash).
    def self.valid_hash_values?(check)
      if !check.is_a?(Hash) or check.empty?
        return false
      else
        check.each do |key, val|
          return false if val.is_a?(Hash) or val.is_a?(Array)
        end
      end
      true
    end

    # Returns +true+ if +check+ is a non-empty hash of flags (boolean or on/off string).
    def self.valid_hash_flags?(check)
      if !check.is_a?(Hash) or check.empty?
        return false
      else
        check.each do |key, val|
          return false if !((val.is_a?(String) and (val == 'on' or val == 'off')) or Tools::valid_boolean?(val))
        end
      end
      true
    end

    # Returns +true+ if +check+ is a valid flag string (on/off).
    def self.valid_flag?(check)
      (check.is_a?(String) and (check == 'on' or check == 'off'))
    end

    # Returns +true+ if +check+ is a non-empty array.
    def self.valid_array?(check)
      (check.is_a?(Array) and !check.empty?)
    end

    # Returns +true+ if +check+ is a valid boolean value.
    def self.valid_boolean?(check)
      (check.is_a?(TrueClass) or check.is_a?(FalseClass) or (check.is_a?(String) and ['false', 'true'].include?(check)))
    end

    # Returns +true+ if +check+ is a valid boolean value.
    def self.valid_integer?(check)
      (check.is_a?(Integer) or check =~ Tools::RGX_INTEGER)
    end

    # Returns +true+ if +check+ is a valid level value.
    def self.valid_level?(check)
      (check.is_a?(String) and check =~ Tools::RGX_LEVEL)
    end

    # Returns +true+ if +check+ is a valid level value.
    def self.valid_auto?(check)
      (check.is_a?(String) and check == 'auto')
    end

    # Returns +true+ if +check+ is a valid boolean value.
    def self.valid_chmod?(check)
      (!check.nil? and check.is_a?(String) and Tools::RGX_CHMOD =~ check)
    end

    # Returns +true+ if +check+ is an array of valid IPv4 addresses.
    def self.valid_array_ipv4?(check)
      valid = true
      if !check.is_a?(Array)
        valid = false
      else
        check.each do |item|
          if !Tools::valid_ipv4?(item)
            valid = false
            break
          end
        end
      end
      valid
    end

    # Returns +true+ if +check+ is an array of valid IPv6 addresses.
    def self.valid_array_ipv6?(check)
      valid = true
      if !check.is_a?(Array)
        valid = false
      else
        check.each do |item|
          if !Tools::valid_ipv6?(item)
            valid = false
            break
          end
        end
      end
      valid
    end

    # Returns +true+ if +check+ is an array of valid IP addresses (IPv4 or IPv6).
    def self.valid_array_ips?(check)
      valid = true
      if !check.is_a?(Array)
        valid = false
      else
        check.each do |item|
          if !Tools::valid_ipv4?(item) and !Tools::valid_ipv6?(item)
            valid = false
            break
          end
        end
      end
      valid
    end

    # Returns +true+ if +check+ is a valid IP address (IPv4 or IPv6).
    def self.valid_ip?(check)
      Tools::valid_ipv4?(check) or Tools::valid_ipv6?(check)
    end

    # Returns +true+ if +check+ is a valid IPv4 address.
    def self.valid_ipv4?(check)
      ###if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ addr
      if !check.nil? and Tools::RGX_IPV4 =~ check
        return $~.captures.all? {|i| i.to_i < 256}
      end
      return false
    end

    # Returns +true+ if +check+ is a valid IPv4 address.
    def self.valid_ipv4_port?(check)
      return (!check.nil? and Tools::RGX_IPV4_PORT =~ check)
    end

    # Returns +true+ if +check+ is a valid IPv4 address.
    def self.valid_ipv6?(check)
      (!check.nil? and Tools::RGX_IPV6 =~ check)
    end

    # Returns +true+ if +check+ is a valid Puppet interpolable URI
    # Examples:
    #   - /media/conf.%{hiera('input::hostname')}/shared-storage0/conf.$hostname/${fqdn}.motd/file
    #   - file:///media/conf.%{hiera('input::hostname')}/shared-storage0/conf.$hostname/${fqdn}.motd/file
    #   - puppet:///media/conf.%{hiera('input::hostname')}/shared-storage0/conf.$hostname/${fqdn}.motd/file
    def self.valid_puppet_interpolable_uri?(check)
      return (!check.nil? and !(Tools::RGX_PUPPET_INTERPOLABLE_URI_SOURCE =~ check).nil?)
    end

    def self.valid_puppet_interpolable_string?(check)
      return (!check.nil? and !(Tools::RGX_PUPPET_INTERPOLABLE_STRING =~ check).nil?)
    end

    # Returns +true+ if +check+ is a valid UNIX absolute path.
    def self.valid_unix_abspath?(check)
      require 'pathname'
      return (!check.nil? and !(Tools::RGX_UNIX_ABSPATH =~ check).nil? and (Pathname.new(check)).absolute?)
    end

    # Returns +true+ if +check+ is a valid UNIX relative path.
    def self.valid_unix_relpath?(check)
      require 'pathname'
      return (!check.nil? and !(Tools::RGX_UNIX_RELPATH =~ check).nil? and (Pathname.new(check)).relative?)
    end

    # Returns +true+ if +check+ is a valid UNIX (absolute or relative) path.
    def self.valid_unix_path?(check)
      return (!check.nil? and !(Tools::RGX_UNIX_PATH =~ check).nil?)
    end

    # Returns +true+ if +check+ is a valid Linux package name.
    def self.valid_linux_package_name?(check)
      return (!check.nil? and !(Tools::RGX_LINUX_PKG_NAME =~ check).nil?)
    end

    # Returns +true+ if +check+ is a valid Linux package name.
    def self.valid_string?(check)
      return check.is_a?(String)
    end

    # Returns +true+ if +check+ is a valid port number.
    def self.valid_port?(check)
      if !check.nil? and
          (check.is_a? Integer and check <= Tools::MAX_PORT and check >= Tools::MIN_PORT) or
          (check.is_a? String and Tools::RGX_STRING_INT =~ check and check.to_i <= Tools::MAX_PORT and check.to_i >= Tools::MIN_PORT)
        return true
      end
      return false
    end

    # Returns +true+ if +check+ is a valid port number.
    # Params:
    # +check+:: value to check
    # +allowed+:: array with the allowed subset of values; defaults to empty array [] (not taken into account)
    # +keywords+:: array with the allowed keywords; defaults to empty array [] (not taken into account)
    # +semver+:: whether to perform semver format checking or not; defaults to true
    # +branch+:: whether to perform semver + family format checking (Major.x, Major.Minor.x) or not; defaults to true
    def self.valid_version?(check, allowed = [], keywords = [], semver = true, branch = true)
      # Check the format of the version when provided.
      # Allowed values for software version (depends on config of @@ver_format):
      #   - Specific version string (semantic versioning rules)
      #   - Version branch (5.x, 3.2.x,...)
      #   - Reserved keyword: 'latest', 'present', 'absent'
      if (!allowed.empty? and allowed.include?(check)) or
            (!keywords.empty? and keywords.include?(check)) or
            (branch and !(check =~ Tools::RGX_SEMVER_BRANCH).nil?) or
            (semver and !(check =~ Tools::RGX_SEMVER_VERSION).nil?)
        # SEMVER: https://github.com/jlindsey/semantic
        return true
      end
      return false
    end
    def self.valid_semver_version?(check)
      return valid_version?(check, [], [], true, false)
    end
    def self.valid_semver_branch?(check)
      return valid_version?(check, [], [], false, true)
    end

    # Returns a string with the +item+ value formatted as YAML content.
    # Params:
    # +item+:: value to format
    # +depth+:: number of indentations at the beginning of each line
    def self.format_yaml(item, depth)
      indent = Tools::YAML_TAB * depth
      if item.is_a?(String) or item.is_a?(Integer)
        return " #{ item.to_s }"
      elsif item.is_a?(Array)
        #return item.to_yaml.gsub("---", '').gsub("\n", "\n#{ indent }").rstrip
        return item.size > 0 ? "\n#{ indent }- #{ item.join("\n#{ indent }- ") }" : ''
      elsif item.is_a?(Hash)
        text = ''
        #item = item.sort.to_h
        item.keys.sort.each { |k| item[k] = item.delete k }
        item.each do |key, val|
          text = "#{ text.to_s }\n#{ indent }#{ key }:#{ Tools.format_yaml(val, depth + 1) }"
        end
        return text
      end
    end

    def self.get_puppet_mod_def_value(mod, keys, type = :doa_def)
      puppetmod = DOA::Provisioner::Puppet.const_get(mod)
      last, recursion = keys.last, puppetmod.supported
      keys.each do |key|
        if recursion.is_a?(Hash) and recursion.has_key?(key)
          if key == last
            recursion = recursion[key]
          elsif recursion[key].has_key?(:children_hash)
            recursion = recursion[key][:children_hash]
          else
            recursion = recursion[key][:children]
          end
        else
          recursion = nil
        end
      end
      return recursion.nil? ? nil : puppetmod.get_default_value(recursion, type)
    end

    def self.get_puppet_mod_prioritized_def_value(path, puppetmod)
      value = DOA::Tools.recursive_get(DOA::Guest.provisioner.current_stack, path)
      value = DOA::Tools.recursive_get(DOA::Guest.settings['stack'], path) if value.empty?
      filtered_path = path - ['*']
      value = DOA::Tools.get_puppet_mod_def_value(puppetmod, filtered_path, :doa_def) if value.empty?
      value = DOA::Tools.get_puppet_mod_def_value(puppetmod, filtered_path, :mod_def) if value.empty?
      return value
    end
    def self.recursive_get(hash, keys)
      #keys = path.split(GLUE_KEYS)
      found, recursion, last = false, hash, keys.last
      keys.each_with_index do |key, index|
        if key == '*'
          if recursion.is_a?(Hash)
            subrecursion = nil
            recursion.each do |subkey, subvalue|
              #subrecursion = recursive_get(subvalue, keys[index + 1, keys.size - index].join(GLUE_KEYS))
              subrecursion = recursive_get(subvalue, keys[index + 1, keys.size - index])
              break if !subrecursion.nil?
            end
            recursion = subrecursion
            found = true if !recursion.nil?
          end
          break;
        elsif !recursion.nil? and recursion.has_key?(key)
          recursion = recursion[key]
          if key == last
            found = true
            break
          end
        else
          break
        end
      end
      return found ? recursion : nil
    end

    # Returns +true+ if +check+ is a valid URL.
    # Params:
    # +check+:: value to check
    def self.valid_url?(check)
      require 'uri'
      check =~ /\A#{URI::regexp(['http', 'https'])}\z/
    end
  end
end

class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
  def blank?
    self.empty?
  end
  def present?
    !self.empty?
  end
  # Returns a hash that includes everything but the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false, c: nil}
  #
  # This is useful for limiting a set of parameters to everything but a few known toggles:
  #   @person.update(params[:person].except(:admin))
  # Author: Beerlington
  # See: http://stackoverflow.com/questions/6227600/how-to-remove-a-key-from-hash-and-get-the-remaining-hash-in-ruby-rails
  def except(*keys)
    dup.except!(*keys)
  end

  # Replaces the hash without the given keys.
  #   hash = { a: true, b: false, c: nil}
  #   hash.except!(:c) # => { a: true, b: false}
  #   hash # => { a: true, b: false }
  # Author: Beerlington
  # See: http://stackoverflow.com/questions/6227600/how-to-remove-a-key-from-hash-and-get-the-remaining-hash-in-ruby-rails
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end

  def recursive_set!(keys, value)
    key = keys.shift
    if !keys.empty?
      self[key].recursive_set!(keys, value)
    else
      self[key] = value
    end
    true
  end
end

class ::String
  def is_integer?
    self.match(/^\-?[0-9]+$/)
  end
  def is_positive_integer?
    if !self.is_integer?
      return nil
    elsif self.to_i > 0
      return true
    else
      return false
    end
  end
  def is_negative_integer?
    if !self.is_integer?
      return nil
    elsif self.to_i < 0
      return true
    else
      return false
    end
  end
  def is_nonpositive_integer?
    if !self.is_integer?
      return nil
    elsif self.to_i <= 0
      return true
    else
      return false
    end
  end
  def is_nonnegative_integer?
    if !self.is_integer?
      return nil
    elsif self.to_i >= 0
      return true
    else
      return false
    end
  end
  def is_float?
    self.match(/^(\-?[0-9]+(\.[0-9]*)?|\-?\.[0-9]+)$/)
  end
  def is_positive_float?
    if !self.is_float?
      return nil
    elsif self.to_i > 0
      return true
    else
      return false
    end
  end
  def is_negative_float?
    if !self.is_float?
      return nil
    elsif self.to_i < 0
      return true
    else
      return false
    end
  end
  def is_nonpositive_float?
    if !self.is_float?
      return nil
    elsif self.to_i <= 0
      return true
    else
      return false
    end
  end
  def is_nonnegative_float?
    if !self.is_float?
      return nil
    elsif self.to_i >= 0
      return true
    else
      return false
    end
  end
  def is_numeric?
    self.is_float?
  end
  def blank?
    self.strip.empty?
  end
  def present?
    !self.blank?
  end
end

class ::NilClass
  def empty?
    true  # Exception
  end
  def blank?
    true
  end
  def present?
    false
  end
end

class ::FalseClass
  def empty?
    false  # Exception
  end
  def blank?
    true
  end
  def present?
    false
  end
end

class ::TrueClass
  def empty?
    false  # Exception
  end
  def blank?
    false
  end
  def present?
    true
  end
end

class ::Array
  def empty?
    (self.reject { |e| e.respond_to?('empty?') ? e.empty? : false }).size == 0
  end
  def blank?
    (self.reject { |e| e.blank? }).size == 0
  end
  def present?
    !self.blank?
  end
end

class ::Fixnum
  def empty?
    false  # Exception
  end
  def blank?
    false
  end
  def present?
    true
  end
end

class ::Float
  def empty?
    false  # Exception
  end
  def blank?
    false
  end
  def present?
    true
  end
end
