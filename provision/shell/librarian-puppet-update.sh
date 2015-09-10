#!/bin/sh
PUPPET_DIR=/etc/puppet
ln -sf /vagrant/provision/puppet/Puppetfile $PUPPET_DIR/Puppetfile
cd $PUPPET_DIR && librarian-puppet update
