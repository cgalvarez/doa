#!/bin/sh
PUPPET_LN_PATH='/opt/puppetlabs/bin'          # Puppet 3.x & 4.x
PUPPET_BIN_PATH='/opt/puppetlabs/puppet/bin'  # Puppet 4.x
ROOT_PROFILE='/root/.bash_profile'
ALL_USERS_PROFILE='/etc/profile'
ENVIRONMENT='/etc/environment'

# Update puppet to the latest version provided by Puppet Labs
# -----------------------------------------------------------
# Credit goes to Kristian Glass:
#   http://blog.doismellburning.co.uk/2013/01/19/upgrading-puppet-in-vagrant-boxes/

# Make sure lsb-release is installed
$(which lsb_release > /dev/null 2>&1)
FOUND_LSBREL=$?
if [ "${FOUND_LSBREL}" -ne '0' ]; then
  apt-get install --yes lsb-release
fi
DISTRIB_CODENAME=$(lsb_release --codename --short)
DEB="puppetlabs-release-pc1-${DISTRIB_CODENAME}.deb"
# Assume that this file's existence means we have the Puppet Labs repo added
DEB_PROVIDES='/etc/apt/sources.list.d/puppetlabs-pc1.list'

# Add Puppet Labs repositories if not present
# http://docs.puppetlabs.com/puppet/4.2/reference/install_linux.html#installing-release-packages-aptdpkg-systems
if [ ! -e $DEB_PROVIDES ]; then
  print "$DEB_PROVIDES not found => fetching and installing $DEB"
  wget -q http://apt.puppetlabs.com/$DEB
  dpkg -i $DEB
  apt-get update
fi

# Install puppet if not present or update it if outdated
PUPPET_VER_INSTALLED=$(apt-cache policy puppet-agent | sed -n 's/\s*Installed:\s*\([0-9\.][0-9\.]*\).*/\1/p')
PUPPET_VER_CANDIDATE=$(apt-cache policy puppet-agent | sed -n 's/\s*Candidate:\s*\([0-9\.][0-9\.]*\).*/\1/p')
if [ -z "${PUPPET_VER_INSTALLED}" ] || [ "${PUPPET_VER_INSTALLED}" != "${PUPPET_VER_CANDIDATE}" ]; then
  echo "Installing the latest version of Puppet..."
  apt-get install --yes --force-yes puppet-agent
fi

# Install R10K through the Ruby gem exec bundled within Puppet 4 or update it if outdated
command -v r10k >/dev/null 2>&1 && R10K_VER_INSTALLED=$(${PUPPET_BIN_PATH}/r10k version | sed -n 's/\s*r10k\s*\([0-9\.][0-9\.]*\).*/\1/p')
R10K_VER_CANDIDATE=$(${PUPPET_BIN_PATH}/gem list r10k --remote | sed -n 's/^r10k\s*(\([0-9\.][0-9\.]*\)).*/\1/p')
if [ -z "${R10K_VER_INSTALLED}" ] || [ "${R10K_VER_INSTALLED}" != "${R10K_VER_CANDIDATE}" ]; then
  echo "Installing the latest version of R10K..."
  #${PUPPET_BIN_PATH}/gem install r10k
fi

# Source: https://github.com/purple52/librarian-puppet-vagrant
PATH=$PATH:/usr/local/bin/

command -v git >/dev/null 2>&1; FOUND_GIT=$?
command -v librarian-puppet >/dev/null 2>&1; FOUND_LP=$?
command -v apt-get >/dev/null 2>&1; FOUND_APT=$?
command -v yum >/dev/null 2>&1; FOUND_YUM=$?

InstallLibrarianPuppetGem () {
  echo 'Installing the latest version of librarian-puppet...'
  RUBY_VERSION=$(ruby -e 'print RUBY_VERSION')
  case "$RUBY_VERSION" in
    1.8.*)
      # Install the most recent 1.x.x version, but not 2.x.x which needs Ruby 1.9
      gem install librarian-puppet --version "~>1"
      ;;
    *)
      gem install librarian-puppet
      ;;
  esac
  echo 'Librarian-puppet installed...'
}

if [ "${FOUND_YUM}" -eq '0' ]; then

  # Make sure Git is installed
  if [ "$FOUND_GIT" -ne '0' ]; then
    echo 'Attempting to install Git...'
    yum -q -y makecache
    yum -q -y install git
    echo 'Git installed...'
  fi

  # Make sure librarian-puppet is installed
  if [ "$FOUND_LP" -ne '0' ]; then
    InstallLibrarianPuppetGem
  fi

elif [ "${FOUND_APT}" -eq '0' ]; then

  #apt-get -q -y update

  # Make sure Git is installed
  if [ "$FOUND_GIT" -ne '0' ]; then
    echo 'Attempting to install Git...'
    apt-get -q -y install git
    echo 'Git installed...'
  fi

  # Make sure ruby-dev is installed
  $(dpkg -s ruby-dev > /dev/null 2>&1)
  FOUND_RUBY_DEV=$?
  if [ "$FOUND_RUBY_DEV" -ne '0' ]; then
    echo 'Attempting to install ruby-dev...'
    apt-get -q -y install ruby-dev
    echo 'ruby-dev installed...'
  fi

  # Make sure librarian-puppet is installed
  if [ "$FOUND_LP" -ne '0' ]; then
    if [ ! -n "$(apt-cache search librarian-puppet)" ]; then
       if [ -n "$(apt-cache search ruby-json)" ]; then
         # Try and install json dependency from package if possible
         apt-get -q -y install ruby-json
       fi
    fi
    InstallLibrarianPuppetGem
  fi
else
  echo 'No supported package installer available. You may need to install git and librarian-puppet manually...'
fi

#EXEC_NAME='librarian-puppet'
#EXEC_PATH=$(find / -name "${EXEC_NAME}" -type f)
#[ -z "${EXEC_PATH}" ] || ln -fs "${EXEC_PATH}" "${PUPPET_LN_PATH}/${EXEC_NAME}"
#EXEC_NAME='augtool'
#EXEC_PATH=$(find / -name "${EXEC_NAME}" -type f)
#[ -z "${EXEC_PATH}" ] || ln -fs "${EXEC_PATH}" "${PUPPET_LN_PATH}/${EXEC_NAME}"
#EXEC_NAME='r10k'
#ln -fs "../puppet/bin/${EXEC_NAME}" "${PUPPET_LN_PATH}/${EXEC_NAME}"

# Create symlinks to some useful puppet tool binaries
EXECS_TO_PATH="augtool
r10k"
set -f; IFS='
'                           # turn off variable value expansion except for splitting at newlines
for exec_file in $EXECS_TO_PATH; do
  set +f; unset IFS
  ln -fs "../puppet/bin/${exec_file}" "${PUPPET_LN_PATH}/${exec_file}"
done
set +f; unset IFS           # do it again in case $INPUT was empty



# Puppet executables are not in the PATH, so we have to options:
#   1) Add binaries to path
#      http://unix.stackexchange.com/questions/26047/how-to-correctly-add-a-path-to-path
#      http://stackoverflow.com/questions/257616/sudo-changes-path-why
#      http://www.troubleshooters.com/linux/prepostpath.htm
#   2) Symlink executables in the system binaries folders
# NOTE: It will be necessary to source the profile every time we run Puppet, with something like:
#   ". /home/vagrant/.profile", so we opt in for the 2nd way

# 1) Add binaries to path
#UPDATE_PATH_CMD="PATH=\$PATH:${PUPPET_LN_PATH}"
#VAGRANT_PROFILE="/home/vagrant/.profile"
#LINE=$(grep "${UPDATE_PATH_CMD}" "${VAGRANT_PROFILE}")
#if [ -z "${LINE}" ]; then
#  (echo ''; echo "${UPDATE_PATH_CMD}") >> "${VAGRANT_PROFILE}"
#fi

# 2) Symlink executables
for f in $PUPPET_LN_PATH/*; do
  symlink="/usr/local/bin/${f##*/}"
  # File does not exist
  if [ ! -e $symlink ]; then
    ln -s $f $symlink
  # File exists but it is not a symlink or points to a different target
  elif [ ! -L $f ] || [ ! "${symlink}" -ef "${f}" ]; then
    #rm -f $symlink
    #ln -s $f $symlink
    ln -fs $f $symlink
  fi
done
