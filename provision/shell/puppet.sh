#!/bin/sh
PUPPET_LN_PATH='/opt/puppetlabs/bin'          # Puppet 3.x & 4.x
PUPPET_BIN_PATH='/opt/puppetlabs/puppet/bin'  # Puppet 4.x
ROOT_PROFILE='/root/.bash_profile'
ALL_USERS_PROFILE='/etc/profile'
ENVIRONMENT='/etc/environment'
LOCAL_USER='vagrant'

# Colored messages
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_END="\033[0m"
STATUS_OK="[${COLOR_GREEN}OK${COLOR_END}]"
STATUS_ERROR="[${COLOR_RED}ERROR${COLOR_END}]"

command -v git >/dev/null 2>&1; FOUND_GIT=$?
command -v librarian-puppet >/dev/null 2>&1; FOUND_LP=$?
command -v apt-get >/dev/null 2>&1; FOUND_APT=$?
command -v yum >/dev/null 2>&1; FOUND_YUM=$?
command -v lsb_release >/dev/null 2>&1; FOUND_LSBREL=$?
command -v gem >/dev/null 2>&1; FOUND_RUBY=$?

APT='apt-get'
YUM='yum'
if [ "${FOUND_YUM}" -eq '0' ]; then
  PKG_MANAGER=${YUM}
elif [ "${FOUND_APT}" -eq '0' ]; then
  PKG_MANAGER=${APT}
  # Suppress warning messages due to provisioners
  #  1) dpkg-reconfigure: unable to re-open stdin: No file or directory
  #  2) stdin: is not a tty
  export DEBIAN_FRONTEND=noninteractive
fi


# Install lsb-release if not present
# ------------------------------------------------------------------------------
if [ "${FOUND_LSBREL}" -ne '0' ]; then
  case $PKG_MANAGER in
    ${YUM})
      LSB_PKG='redhat-lsb-core'
      ;;
    ${APT})
      LSB_PKG='lsb-release'
      ;;
  esac
  echo 'Checking for lsb-release...'
  ${PKG_MANAGER} install -q -y ${LSB_PKG} >/dev/null 2>&1
  MSG='Installing lsb-release...'
  [ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"
fi
LSB_ID=$(lsb_release --id --short)


# Add Puppet Labs repositories if not present
# ------------------------------------------------------------------------------
# https://docs.puppetlabs.com/guides/puppetlabs_package_repositories.html
ADD_REPO='1'
case $PKG_MANAGER in
  ${YUM})
    case $LSB_ID in
      'CentOS')
        LSB_MAJOR_RELEASE=$(lsb_release --release --short | sed 's/^\([0-9][0-9]*\)\..*$/\1/g')
        REPO="puppetlabs-release-el-${LSB_MAJOR_RELEASE}.noarch.rpm"
        REPO_PROOF='/etc/yum.repos.d/puppetlabs-pc1.repo'
        if [ ! -e $REPO_PROOF ]; then
          ADD_REPO=0
          rpm -ivh "http://yum.puppetlabs.com/puppetlabs-release-el-${LSB_MAJOR_RELEASE}.noarch.rpm" >/dev/null
        fi
        ;;
    esac
    ;;
  ${APT})
    LSB_CODENAME=$(lsb_release --codename --short)
    REPO="puppetlabs-release-pc1-${LSB_CODENAME}.deb"
    REPO_PROOF='/etc/apt/sources.list.d/puppetlabs-pc1.list'
    if [ ! -e ${REPO_PROOF} ]; then
      ADD_REPO=0
      wget -q "http://apt.puppetlabs.com/${REPO}"
      dpkg -i ${REPO} >/dev/null
    fi
    ;;
esac
if [ "${ADD_REPO}" -eq '0' ]; then
  echo 'Checking for Puppet Labs repositories...'
  echo "${REPO_PROOF} not found..."
  ${PKG_MANAGER} update -y -q >/dev/null 2>&1
  MSG='Fetching and installing Puppet Labs repositories...'
  [ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"
fi


# Install puppet if not present or update it when outdated
# ------------------------------------------------------------------------------
PUPPET_PKG='puppet-agent'
INSTALL_PUPPET='1'
case $PKG_MANAGER in
  ${YUM})
    case $LSB_ID in
      'CentOS')
        PUPPET_VER_INSTALLED=$(yum list installed $PUPPET_PKG 2>/dev/null | awk "\$1 ~ /${PUPPET_PKG}.*/ { print \$2 }")
        PUPPET_VER_CANDIDATE=$(yum list available $PUPPET_PKG 2>/dev/null | awk "\$1 ~ /${PUPPET_PKG}.*/ { print \$2 }")
        INSTALL_PUPPET=$({ [ -z "${PUPPET_VER_INSTALLED}" ] || { [ -n "${PUPPET_VER_CANDIDATE}" ] && [ "${PUPPET_VER_INSTALLED}" != "${PUPPET_VER_CANDIDATE}" ]; } } && echo '0' || echo '1')
        ;;
    esac
    ;;
  ${APT})
    PUPPET_VER_INSTALLED=$(apt-cache policy puppet-agent | sed -n 's/\s*Installed:\s*\([0-9\.][0-9\.]*\).*/\1/p')
    PUPPET_VER_CANDIDATE=$(apt-cache policy puppet-agent | sed -n 's/\s*Candidate:\s*\([0-9\.][0-9\.]*\).*/\1/p')
    INSTALL_PUPPET=$({ [ -z "${PUPPET_VER_INSTALLED}" ] || [ "${PUPPET_VER_INSTALLED}" != "${PUPPET_VER_CANDIDATE}" ]; } && echo '0' || echo '1')
    ;;
esac
if [ "${INSTALL_PUPPET}" -eq '0' ]; then
  echo 'Checking for Puppet...'
  ${PKG_MANAGER} install -q -y ${PUPPET_PKG} >/dev/null 2>&1
  MSG='Installing the latest version of Puppet...'
  [ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"
fi


# Install git if not present
# ------------------------------------------------------------------------------
if [ "${FOUND_GIT}" -ne '0' ]; then
  GIT_PKG='git'
  case $PKG_MANAGER in
    ${YUM})
      GIT_PKG="makecache ${GIT_PKG}"
      ;;
  esac
  echo 'Checking for git...'
  ${PKG_MANAGER} install -y -q ${GIT_PKG} >/dev/null 2>&1
  MSG='Installing git...'
  [ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"
fi


# Install rubygems and required gems if not present
# ------------------------------------------------------------------------------
[ "${FOUND_RUBY}" -ne '0' ] && RUBY_PKG='ruby' || RUBY_PKG=''
case $PKG_MANAGER in
  ${YUM})
    RUBY_PKG="${RUBY_PKG} rubygems ruby-json ruby-devel"
    ;;
  ${APT})
    RUBY_PKG="${RUBY_PKG} ruby-json ruby-dev"
    ;;
esac
echo 'Checking for Ruby and required gems...'
${PKG_MANAGER} install -y -q ${RUBY_PKG} >/dev/null 2>&1
MSG='Installing required Ruby packages...'
[ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"


# Install/update R10K through the Ruby gem exec bundled within Puppet 4
# ------------------------------------------------------------------------------
command -v r10k >/dev/null 2>&1 && R10K_VER_INSTALLED=$(${PUPPET_BIN_PATH}/r10k version | sed -n 's/\s*r10k\s*\([0-9\.][0-9\.]*\).*/\1/p')
R10K_VER_CANDIDATE=$(${PUPPET_BIN_PATH}/gem list r10k --remote | sed -n 's/^r10k\s*(\([0-9\.][0-9\.]*\)).*/\1/p')
if [ -z "${R10K_VER_INSTALLED}" ] || [ "${R10K_VER_INSTALLED}" != "${R10K_VER_CANDIDATE}" ]; then
  echo 'Checking for R10K...'
  ${PUPPET_BIN_PATH}/gem install -q r10k >/dev/null 2>&1
  MSG='Installing the latest version of R10K...'
  [ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"
fi


# Install librarian-puppet and required gems if not present
# ------------------------------------------------------------------------------
RUBY_VERSION=$(ruby -e 'print RUBY_VERSION')
LP_GEM='librarian-puppet'
LP_VER_INSTALLED=$(gem list ${LP_GEM} | sed -n "s/^${LP_GEM}\s*(\([0-9\.][0-9\.]*\)).*/\1/p")
RUBY_OLD_VERSION=$(echo ${RUBY_VERSION} | sed -n /1\.8\.[0-9\.]*/p)
LP_MAJOR_VERSION=$([ -n "${RUBY_OLD_VERSION}" ] && echo '1' || echo '')
if [ -n "${LP_MAJOR_VERSION}" ]; then
  LP_VER_CANDIDATE=$(gem list ${LP_GEM} --remote -all | sed -n "s/^${LP_GEM}\s*.*[(\s]\(${LP_MAJOR_VERSION}\.[0-9\.][0-9\.]*\).*)/\1/p")
else
  LP_VER_CANDIDATE=$(gem list ${LP_GEM} --remote | sed -n "s/^${LP_GEM}\s*(\([0-9\.][0-9\.]*\)).*/\1/p")
fi
if [ -z "${LP_VER_INSTALLED}" ] || [ "${LP_VER_INSTALLED}" != "${LP_VER_CANDIDATE}" ]; then
  echo 'Checking for librarian-puppet...'
  # Install the most recent 1.x.x version when Ruby 1.8.* installed, but not 2.x.x which needs Ruby 1.9.x or greater
  [ -n "${LP_MAJOR_VERSION}" ] && gem install -q ${LP_GEM} --version "~>${LP_MAJOR_VERSION}" >/dev/null 2>&1 || gem install -q ${LP_GEM} >/dev/null 2>&1
  MSG='Installing librarian-puppet...'
  [ ${?} -eq 0 ] && echo "${MSG} ${STATUS_OK}" || echo "${MSG} ${STATUS_ERROR}"
fi


# Create symlinks to some useful puppet tool binaries
# ------------------------------------------------------------------------------
EXECS_TO_PATH="augtool
r10k"
set -f; IFS='
'                   # turn off variable value expansion except for splitting at newlines
for exec_file in $EXECS_TO_PATH; do
  set +f; unset IFS
  ln -fs "../puppet/bin/${exec_file}" "${PUPPET_LN_PATH}/${exec_file}"
done
set +f; unset IFS   # do it again in case $INPUT was empty


# Some Puppet executables are not in the PATH, so we have to options:
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
    ln -s ${f} ${symlink}
  # File exists but it is not a symlink or points to a different target
elif [ ! -L ${f} ] || [ ! "${symlink}" -ef "${f}" ]; then
    ln -fs ${f} ${symlink}
  fi
done

# Local puppet folder must belong to Vagrant default user
mkdir -p "/home/${LOCAL_USER}/.puppetlabs/var"
chown -R ${LOCAL_USER}:${LOCAL_USER} "/home/${LOCAL_USER}/.puppetlabs"
