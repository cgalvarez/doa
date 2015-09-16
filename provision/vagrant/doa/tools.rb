#!/usr/bin/ruby

module DOA
  class Tools

    # Constants
    TYPE_STRING       = 'String'
    TYPE_INTEGER      = 'Integer'
    TYPE_ARRAY        = 'Array'
    TYPE_HASH         = 'Hash'
    MSG_MISSING_VALUE = 'missing_value'
    MSG_WRONG_VALUE   = 'wrong_value'
    MSG_WRONG_TYPE    = 'wrong_type'
    RGX_STRING_INT    = /^\A\d+\z$/
    RGX_UNIX_ABSPATH  = /^\A(?:[\w-]+\/?)+\z$/
    RGX_IPV4          = /^\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z$/
    RGX_SEMVER        = /^(\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/
    RGX_SEMVER_FAMILY = /^((\d+\.\d+\.\d+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))|(\d+\.([0-9]+\.([0-9]+|[xX])|[xX])))?$/
    MAX_PORT          = 65535
    MIN_PORT          = 0
    YAML_TAB          = '  '


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
          when 3 then DOA::L10n::MISSING_PARAM_TYPE_CTX_SITE
          when 4 then DOA::L10n::MISSING_PARAM_TYPE_CTX_SW
          when 5 then DOA::L10n::MISSING_PARAM_TYPE_CTX_ASSET
          end
      when Tools::MSG_WRONG_TYPE
        msg = case ctx.size
          when 2 then DOA::L10n::WRONG_TYPE_CTX_VM
          when 3 then DOA::L10n::WRONG_TYPE_CTX_SITE
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

    # Returns +true+ if +check+ is a valid IPv4 address.
    def self.valid_ipv4?(check)
      ###if /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\Z/ =~ addr
      if !check.nil? and Tools::RGX_IPV4 =~ check
        return $~.captures.all? {|i| i.to_i < 256}
      end
      return false
    end

    # Returns +true+ if +check+ is a valid UNIX absolute path.
    def self.valid_unix_abspath?(check)
      require 'pathname'
      puts check
      puts Tools::RGX_UNIX_ABSPATH
      puts (Pathname.new check)
      return (!check.nil? and !(Tools::RGX_UNIX_ABSPATH =~ check).nil? and (Pathname.new(check)).absolute?)
      return true
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
    # +family+:: whether to perform semver + family format checking (Major.x, Major.Minor.x) or not; defaults to true
    def self.valid_version?(check, allowed = [], keywords = [], semver = true, family = true)
      # Check the format of the version when provided.
      # Allowed values for software version (depends on config of @@ver_format):
      #   - Specific version string (semantic versioning rules)
      #   - Version family (5.x, 3.2.x,...)
      #   - Reserved keyword: 'latest', 'present', 'absent'
      if (!allowed.empty? and allowed.include?(check)) or
            (!keywords.empty? and keywords.include?(check)) or
            (family and !(check =~ Tools::RGX_SEMVER_FAMILY).nil?) or
            (semver and !(check =~ Tools::RGX_SEMVER).nil?)
        # SEMVER: https://github.com/jlindsey/semantic
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
    # +family+:: whether to perform semver + family format checking (Major.x, Major.Minor.x) or not; defaults to true
    def self.format_yaml(item, depth)
      indent = Tools::YAML_TAB * depth
      if item.is_a?(String) or item.is_a?(Integer)
        return " #{ item.to_s }"
      elsif item.is_a?(Array)
        return value.to_yaml.gsub("---", '').gsub("\n", "\n#{ indent }")
      elsif item.is_a?(Hash)
        text = ''
        item.each do |key, val|
          text = "#{ text.to_s }\n#{ indent }#{ key }:#{ Tools.format_yaml(val, depth + 1) }"
        end
        return text
      end
    end
  end
end

class ::Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        self.merge(second, &merger)
    end
end
