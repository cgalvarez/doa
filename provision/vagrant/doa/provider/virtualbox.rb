#!/usr/bin/ruby

require 'singleton'

module DOA
  module Provider
    class Virtualbox
      include Singleton

      # Constants.
      TYPE = 'virtualbox'
      WINDOWS_DRIVE_TYPE_HARDDISK = 2

      # Class variables.
      @@vboxmanage = nil

      # Makes the default initialization.
      def initialize
        @@vboxmanage = locate_vboxmanage if @@vboxmanage.nil? or @@vboxmanage.empty?
      end

      # Locates the VBoxManage tool and saves its path into internal attribute.
      def locate_vboxmanage
        vboxmanage_exec, output = '', ''
        print DOA::L10n::LOCATE_VBOXMANAGE

        # Search VBoxManage in the PATH first
        if DOA::Host.os == DOA::OS::WINDOWS
          vboxmanage_exec = 'VBoxManage.exe'
          output = `where #{ vboxmanage_exec } 2>NUL`
        end

        # Take the first returned available path
        if $?.exitstatus == 0 and !output.empty?
          paths = output.split("\n")
          paths.each do |path|
            @@vboxmanage = path.strip if !path.strip.empty?
            break if !@@vboxmanage.nil?
          end 
        end

        if @@vboxmanage.nil?
          print DOA::L10n::FAIL_NOT_FOUND_PATH

          # If not found, search in the path detected by Vagrant
          drive_letter = ENV['VBOX_MSI_INSTALL_PATH'][/^([a-zA-Z]:)/,1]
          output = `#{ drive_letter } & cd #{ ENV['VBOX_MSI_INSTALL_PATH'] } & dir #{ vboxmanage_exec } /b/s 2>NUL`

          # Take the first returned available path from Vagrant ENV path
          if $?.exitstatus == 0 and !output.empty?
            paths = output.split("\n")
            paths.each do |path|
              @@vboxmanage = path.strip if !path.strip.empty?
              break if !@@vboxmanage.nil?
            end 
          end

          # If not found in the Vagrant ENV path
          if @@vboxmanage.nil?
            print DOA::L10n::FAIL_NOT_FOUND_ENV

            # Search VBoxManage in all available hard drives
            if DOA::Host.os == DOA::OS::WINDOWS and !vboxmanage_exec.empty?
            #if Vagrant::Util::Platform.windows? and !vboxmanage_exec.empty?
              # See http://stackoverflow.com/questions/3258518/ruby-get-available-disk-drives#answer-3258842
              require 'win32ole'
              file_system = WIN32OLE.new('Scripting.FileSystemObject')
              drives      = file_system.Drives
              drives.each do |drive|
                if drive.DriveType == VagrantProviderVirtualBox::WINDOWS_DRIVE_TYPE_HARDDISK
                  output = `#{ drive.Path } & cd / & dir #{ vboxmanage_exec } /b/s 2>NUL`
                  break if $?.exitstatus == 0
                end
              end
            end

            # Take the first returned available path
            if $?.exitstatus == 0 and !output.empty?
              paths = output.split("\n")
              paths.each do |path|
                @@vboxmanage = path.strip if !path.strip.empty?
                break if !@@vboxmanage.nil?
              end 
            end

            if @@vboxmanage.nil?
              puts DOA::L10n::SUCCESS_FOUND_FS
            else
              puts "#{ DOA::L10n::FAIL_NOT_FOUND_FS }#{ DOA::L10n::FAIL_NOT_FOUND }"
            end
          else
            puts DOA::L10n::SUCCESS_FOUND_ENV
          end
        else
          puts DOA::L10n::SUCCESS_FOUND_PATH
        end

        # Print error message to user if not found and break execution
        if @@vboxmanage.empty?
          puts DOA::L10n::FAIL_NOT_FOUND
          abort
        end

        return @@vboxmanage
      end

      # Gets the IPv4 address of the guest machine.
      # Params:
      # +uid+:: string with the name of the guest virtual machine
      def get_ip(uid)
        ip = nil
        if !@@vboxmanage.nil? and !@@vboxmanage.empty?
          vb_cmd = "\"#{ @@vboxmanage }\" guestproperty get \"#{ uid }\" /VirtualBox/GuestInfo/Net/1/V4/IP"
          vb_cmd += DOA::Host.os == DOA::OS::WINDOWS ? ' 2>NUL' : ' 2>/dev/null'
          ip = `#{ vb_cmd } | awk -v OFS="\\n" '{ print $2 }'`.strip
        end
        return ip
      end

      # Checks if the guest virtual machine is running.
      # Params:
      # +uid+:: string with the name of the guest virtual machine
      def running?(uid)
        running = false
        if !@@vboxmanage.nil? and !@@vboxmanage.empty?
          vb_cmd = "\"#{ @@vboxmanage }\" list runningvms"
          vb_cmd += DOA::Host.os == DOA::OS::WINDOWS ? ' 2>NUL' : ' 2>/dev/null'
          `#{ vb_cmd } | grep '#{ uid }'`
          running = $?.exitstatus == 0
        end
        return running
      end

      # Gets the OS of the guest virtual machine.
      # Params:
      # +uid+:: string with the name of the guest virtual machine
      def get_os(uid)
        os = nil
        if !@@vboxmanage.nil? and !@@vboxmanage.empty?
          vb_cmd = "\"#{ @@vboxmanage }\" guestproperty get \"#{ uid }\" /VirtualBox/GuestInfo/OS/Product"
          vb_cmd += DOA::Host.os == DOA::OS::WINDOWS ? ' 2>NUL' : ' 2>/dev/null'
          os = `#{ vb_cmd } | awk -v OFS="\\n" '{ print $2 }'`.strip
          os = OS::WINDOWS if /^.*Windows.*$/.match(os)
        end
        return os
      end

      # Checks if virtual machine with the provided UID exists.
      # Params:
      # +uid+:: string with the name of the guest virtual machine
      def exist?(uid)
        if !@@vboxmanage.nil? and !@@vboxmanage.empty?
          return !`"#{ @@vboxmanage }" list vms | grep '"#{ uid }"'`.strip.empty?
        end
        return false
      end
    end
  end
end
