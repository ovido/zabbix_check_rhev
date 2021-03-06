#!/usr/bin/perl -w

#########################################################
#                                                       #
#  Name:    zabbix_check_rhev                           #
#                                                       #
#  Version: 0.1.0                                       #
#  Created: 2014-06-08                                  #
#  Last Update: 2014-09-15                              #
#  License: GPLv3 - http://www.gnu.org/licenses         #
#  Copyright: (c)2014 Zabbix check_rhev devlopment team #
#  URL: https://github.com/ovido/zabbix_check_rhev      #
#                                                       #
#########################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use Getopt::Long;

# for debugging only
use Data::Dumper;

use lib "../lib";
use oVirt::Zabbix;

# Configuration
# all values can be overwritten in authrc file
my $rhevm_timeout	= 15;         # default timeout
my $rhevm_api		= "/api";
my $rhevm_port		= 443;

# Variables
my $prog       = "zabbix_check_rhev";
my $version    = "0.1.0";
my $projecturl = "https://github.com/ovido/zabbix_check_rhev";
my $cookie     = "/var/tmp";   # default path to cookie file
my $auth_file  = "/tmp/.authrc";

my ($o_help, $o_version) = undef;
my $config 	   = {};

# possible items
my @statistics = qw( 'memory.installed' 'memory.used' 'cpu.current.guest' 'cpu.current.hypervisor' 'cpu.current.total' );

# create an empty oVirt::Zabbix element
my $zabbix = oVirt::Zabbix->new();


#----------------------------------------------------------------
# The main program start here.

# parse command line options
parse_options();

if ($ARGV[1] eq "vm"){
  # get vm id
  my $id = eval { $zabbix->get_result( "config"		=> $config,
  									  "path"		=> "/vms?search=name%3D$ARGV[2]",
  									  "component"	=> "vm",
  									  "item"		=> "id") };
#  print $@;
#  print Dumper $id;
  # get item
  my $item = $zabbix->get_result( "config"	=> $config,
  										"path"		=> "/vms/$id/statistics",
  										"component"	=> "statistic", 
  										"item"		=> $ARGV[3]);
  print $item . "\n";
  exit 0;
}


#----------------------------------------------------------------

=head1 METHODS

#----------------------------------------------------------------

=head2 parse_options

=head3 SYNOPSIS

 parse_options()
 
=head3 DESCRIPTION
 
Parse command line parameters.

=cut

sub parse_options {
	
  Getopt::Long::Configure ("bundling");
  GetOptions(
    'h' 	=> \$o_help,			'help' => \$o_help,
    'V' 	=> \$o_version,			'version' => \$o_version,
  );

  # process options
  $zabbix->print_help( "version" => $version)		if defined $o_help;
  $zabbix->print_version( "version" => $version,
  								"prog"	  => $prog )	if defined $o_version;

  die "Hostname of RHEV management server is missing.\n" 		unless defined $ARGV[0];
  die "Component (datacenter|cluster|host|vm) is missing.\n" 	unless defined $ARGV[1];
  die "Component search name is missing.\n"						unless defined $ARGV[2];
  die "Component search key is missing.\n"						unless defined $ARGV[3];
  
  my $rhevm_host = $ARGV[0];
  
  # validate output
  if ($ARGV[1] ne "datacenter" && $ARGV[1] ne "cluster" && $ARGV[1] ne "host" && $ARGV[1] ne "vm"){
  	die "Unsupported component: $ARGV[1].\n";
  }

  # Get username and password from authrc file
  $config = eval { $zabbix->parse_authrc(	"auth_file" 	=> $auth_file,
  												"rhevm_host"	=> $rhevm_host,
  												"rhevm_port"	=> $rhevm_port,
  												"rhevm_api"		=> $rhevm_api,
  												"rhevm_timeout"	=> $rhevm_timeout,
  												"cookie"		=> $cookie ) };

  die ($@) if $@;

}


exit 0;
