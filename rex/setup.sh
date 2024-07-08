#!/bin/bash

#THIS SCRIPT IS NOT SUITABLE FOR PRODUCTION OR REMOTE DEPLOYMENT - IT IS INTENDED FOR EASE OF DEVELOPMENT AND TESTING ONLY.

apt-get update
apt-get install -y cpanminus gcc g++ make nano libaws-signature4-perl libdata-validate-ip-perl libdevel-caller-perl libhash-merge-perl 
apt-get install -y libio-string-perl libsort-naturally-perl libterm-readkey-perl libtext-glob-perl liburi-perl libxml-simple-perl libyaml-perl
apt-get install -y libversion-perl libfile-sharedir-install-perl libio-pty-perl libdigest-hmac-perl libnet-sftp-foreign-perl libnet-openssh-perl 
apt-get install -y libjson-maybexs-perl libcpanel-json-xs-perl

cpanm --notest Rex
