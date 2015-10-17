#!/usr/bin/ruby

module DOA
  module L10n
    # Status
    SUCCESS_ADDED       = "[#{ 'ADDED'.colorize(:green) }]"
    SUCCESS_CREATED     = "[#{ 'CREATED'.colorize(:green) }]"
    SUCCESS_FOUND_ENV   = "[#{ 'ENV'.colorize(:green) }]"
    SUCCESS_FOUND_FS    = "[#{ 'FS'.colorize(:green) }]"
    SUCCESS_FOUND_PATH  = "[#{ 'PATH'.colorize(:green) }]"
    SUCCESS_OK          = "[#{ 'OK'.colorize(:green) }]"
    SUCCESS_REMOVED     = "[#{ 'REMOVED'.colorize(:green) }]"
    SUCCESS_UPDATED     = "[#{ 'UPDATED'.colorize(:green) }]"
    FAIL_ERROR          = "[#{ 'ERROR'.colorize(:red) }]"
    FAIL_NOT_FOUND      = "[#{ 'NOT FOUND'.colorize(:red) }]"
    FAIL_NOT_FOUND_ENV  = "[#{ 'ENV'.colorize(:red) }]"
    FAIL_NOT_FOUND_FS   = "[#{ 'FS'.colorize(:red) }]"
    FAIL_NOT_FOUND_PATH = "[#{ 'PATH'.colorize(:red) }]"
    NOT_RUNNING         = "[#{ 'NOT RUNNING'.colorize(:yellow) }]"
    
    # host.rb
    HOST_HOSTS_GUEST_ENTRY = "%s Managing guest entry in @ %s:%s... %s"
    PW_REQUEST = "%s Please, enter the password for your user account to reload authorized keys for host:".colorize(:light_blue)
    CONN_CLOSED = "%s Connection terminated or wrong password entered. Please, try again...".colorize(:red)
    MAX_RETRIES_REACHED = "%s Aborting... Maximum number of retries reached...".colorize(:red)
    RELOADING_AUTH_KEYS = "%s Reloading authorized keys... %s"
    
    # guest.rb
    SCP_PPK = "%s Secure copy of new session private key into %s... "
    RM_SESSION_KEY = "%s Removing session key from %s... "
    CREATE_HOSTS_MANIFEST = "%s Creating hosts manifest for %s... "
    SCP_HOSTS_MANIFEST = "%s Secure copy of puppet manifest for managing hosts file into %s... "
    GUEST_HOSTS_HOST_ENTRY = "%s Managing host entry @ %s:%s... "
    
    # sync.rb
    START_BG_LISTENING = "%s Start background-listening FSEvents @ %s... "
    SCP_LISTENER = "%s Secure copy of listener script into %s... "
    INSTALL_RUBY_GEMS_LISTENER = "%s Installing required ruby gems for listening FSEvents @ %s (be patient)... "
    CREATE_LISTENER = "%s Creating listener script for FSEvents @ %s... "
    CREATE_BG_LAUNCHER = "%s Creating background-launcher for %s listener script... "
    STOP_BG_LISTENING = "%s Stop background-listening FSEvents @ %s... "
    
    # Notification
    LOCATE_VBOXMANAGE = 'Locating VBoxManage... '
    PROVIDER_NOT_SUPPORTED = "Provider '%s' is not officially supported yet (machine '%s')... "
    
    # puppet.rb
    UNSUPPORTED_SW = "\n%s ERROR [%s » %s]: The software '%s' has no support... "
    UNRECOGNIZED_SW_PARAM = "\n%s ERROR [%s » %s » %s]: Unrecognized parameter '%s'... "
    UNRECOGNIZED_VERSION = "\n%s ERROR [%s » %s » %s » %s]: Unrecognized reserved keyword, malformed semver string or not allowed string... "
    SETTING_UP_PROVISIONER = "%s Setting up provisioner %s for %s... "
    PROVISIONING_STACK = "%s Provisioning requested stack for %s with %s... "
    ###CREATING_PUPPETFILE = "%s Creating Puppetfile for %s..."
    ###CREATING_FILE = "%s Creating %s for %s..."
    NOT_SUPPORTED_BRANCH = "\n%s ERROR [%s » %s » %s]: %s currently has no support for branch %s"
    INCOMPAT_SETTINGS_LIBRARIAN_MOD = "\n%s ERROR: Incompatible settings for librarian-puppet module of '%s'"
    
    # mariadb.rb
    MARIADB_NO_SUPPORT  = "\n%s ERROR [%s » %s » %s]: %s currently has no support for %s"
    VERSION_INCOMP      = "\n%s ERROR [%s » %s » %s]: %s cannot be '%s' when providing a specific version"
    BRANCH_INCOMP       = "\n%s ERROR [%s » %s » %s]: All involved packages must belong to the same branch"
    
    # 
    MISSING_PATH = "%s ERROR [%s]: You must provide the path for the addon '%s'"
    MALFORMED_EXCLUDE = "%s WARNING [%s]: '%s', when provided, must be a non-empty array of strings... ignored for '%s'"

    # Generic
    MISSING_PARAM_TYPE_CTX_VM       = "\n%s ERROR [%s]: A value must be provided for parameter '%s'"
    MISSING_PARAM_TYPE_CTX_SITE     = "\n%s ERROR [%s » %s]: A value must be provided for parameter '%s'"
    MISSING_PARAM_TYPE_CTX_SW       = "\n%s ERROR [%s » %s » %s]: A value must be provided for parameter '%s'"
    MISSING_PARAM_TYPE_CTX_ASSET    = "\n%s ERROR [%s » %s » %s » %s]: A value must be provided for parameter '%s'"
    WRONG_TYPE_CTX_VM               = "\n%s ERROR [%s]: '%s' must be %s type"
    WRONG_TYPE_CTX_SITE             = "\n%s ERROR [%s » %s]: '%s' must be %s type"
    WRONG_TYPE_CTX_SW               = "\n%s ERROR [%s » %s » %s]: '%s' must be %s type"
    WRONG_TYPE_CTX_ASSET            = "\n%s ERROR [%s » %s » %s » %s]: '%s' must be %s type"
    WRONG_TYPE_FN_PARAM_CTX_VM      = "\n%s ERROR [%s]: Parameter '%s' must be %s type for method '%s'"
    WRONG_TYPE_FN_PARAM_CTX_SITE    = "\n%s ERROR [%s » %s]: Parameter '%s' must be %s type for method '%s'"
    WRONG_TYPE_FN_PARAM_CTX_SW      = "\n%s ERROR [%s » %s » %s]: Parameter '%s' must be %s type for method '%s'"
    WRONG_TYPE_FN_PARAM_CTX_ASSET   = "\n%s ERROR [%s » %s » %s » %s]: Parameter '%s' must be %s type for method '%s'"
    #WRONG_TYPE_VALUE_CTX_VM         = "\n%s ERROR [%s]: Parameter '%s' must be %s type"
    #WRONG_TYPE_VALUE_CTX_SITE       = "\n%s ERROR [%s » %s]: Parameter '%s' must be %s type for method '%s'"
    #WRONG_TYPE_VALUE_CTX_SW         = "\n%s ERROR [%s » %s » %s]: Parameter '%s' must be %s type for method '%s'"
    #WRONG_TYPE_VALUE_CTX_ASSET      = "\n%s ERROR [%s » %s » %s » %s]: Parameter '%s' must be %s type for method '%s'"
    MALFORMED_FN_PARAM_CTX_VM       = "\n%s ERROR [%s]: Malformed parameter '%s' in method '%s'"
    MALFORMED_FN_PARAM_CTX_SITE     = "\n%s ERROR [%s » %s]: Malformed parameter '%s' in method '%s'"
    MALFORMED_FN_PARAM_CTX_SW       = "\n%s ERROR [%s » %s » %s]: Malformed parameter '%s' in method '%s'"
    MALFORMED_FN_PARAM_CTX_ASSET    = "\n%s ERROR [%s » %s » %s » %s]: Malformed parameter '%s' in method '%s'"
    UNSUPPORTED_VALUE_CTX_VM        = "\n%s ERROR [%s]: Unsupported value '%s' for parameter '%s'"
    UNSUPPORTED_VALUE_CTX_SITE      = "\n%s ERROR [%s » %s]: Unsupported value '%s' for parameter '%s'"
    UNSUPPORTED_VALUE_CTX_SW        = "\n%s ERROR [%s » %s » %s]: Unsupported value '%s' for parameter '%s'"
    UNSUPPORTED_VALUE_CTX_ASSET     = "\n%s ERROR [%s » %s » %s » %s]: Unsupported value '%s' for parameter '%s'"
    UNSUPPORTED_PARAM_VALUE_CTX_VM    = "\n%s ERROR [%s]: Unsupported value for parameter '%s'"
    UNSUPPORTED_PARAM_VALUE_CTX_SITE  = "\n%s ERROR [%s » %s]: Unsupported value for parameter '%s'"
    UNSUPPORTED_PARAM_VALUE_CTX_SW    = "\n%s ERROR [%s » %s » %s]: Unsupported value for parameter '%s'"
    UNSUPPORTED_PARAM_VALUE_CTX_ASSET = "\n%s ERROR [%s » %s » %s » %s]: Unsupported value for parameter '%s'"
    EXCLUSIVE_CTX_VM    = "\n%s ERROR [%s]: Parameters '%s' and '%s' are mutually exclusive"
    EXCLUSIVE_CTX_SITE  = "\n%s ERROR [%s » %s]: Parameters '%s' and '%s' are mutually exclusive"
    EXCLUSIVE_CTX_SW    = "\n%s ERROR [%s » %s » %s]: Parameters '%s' and '%s' are mutually exclusive"
    EXCLUSIVE_CTX_ASSET = "\n%s ERROR [%s » %s » %s » %s]: Parameters '%s' and '%s' are mutually exclusive"
  end
end
