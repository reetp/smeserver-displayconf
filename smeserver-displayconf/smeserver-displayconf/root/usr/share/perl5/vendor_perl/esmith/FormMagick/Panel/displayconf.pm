#----------------------------------------------------------------------
# $Id: portforwarding.pm,v 1.31 2003/04/08 15:28:55 msoulier Exp $
# vim: ft=perl ts=4 sw=4 et:
#----------------------------------------------------------------------
# copyright (C) 2004 Pascal Schirrmann
# copyright (C) 2002 Mitel Networks Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#----------------------------------------------------------------------

package esmith::FormMagick::Panel::displayconf;

use strict;
use esmith::ConfigDB;
use esmith::AccountsDB;
use esmith::FormMagick;
use esmith::cgi;
use Exporter;

use constant TRUE => 1;
use constant FALSE => 0;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(
     display_conf
    );

our $VERSION = sprintf '%d.%03d', q$Revision: 0.01 $ =~ /: (\d+).(\d+)/;
# our $db = esmith::ConfigDB->open_ro
#         or die "Can't open the Config database : $!\n" ;
our $accountsdb = esmith::AccountsDB->open_ro
        or die "Can't open the Accounts database : $!\n" ;

=head1 NAME

esmith::FormMagick::Panels::displayconf - useful panel functions

=head1 SYNOPSIS

    use esmith::FormMagick::Panels::displayconf

    my $panel = esmith::FormMagick::Panel::displayconf->new();
    $panel->display();

=head1 DESCRIPTION

This module is the backend to the displayconf panel, responsible for
supplying all functions used by that panel. It is a subclass of
esmith::FormMagick itself, so it inherits the functionality of a FormMagick
object.

=head2 new

This is the class constructor.

=cut

sub new {
    my $class = ref($_[0]) || $_[0];
    my $self = esmith::FormMagick->new();
    bless $self, $class;
    # Uncomment the following line for debugging.
    #$self->debug(TRUE);
    return $self;
}

=head2 display_conf

This method displays the whole users configuration

=cut

sub display_conf {
    my $self = shift ;
    my $q = $self->cgi ;

    my @all = $accountsdb->get_all;
    
    # what do we want to display ?
    # print "\$filter = $filter<br>\n" ;
    my $filtadd = '' ;
    my $filtrem = '' ;
    my $chk_all        = $q->param('chk_all')        || 0 ;
    my $chk_users      = $q->param('chk_users')      || 0 ;
    my $chk_groups     = $q->param('chk_groups')     || 0 ;
    my $chk_pseudonyms = $q->param('chk_pseudonyms') || 0 ;
    my $chk_printers   = $q->param('chk_printers')   || 0 ;
    my $chk_ibays      = $q->param('chk_ibays')      || 0 ;
    my $chk_misc       = $q->param('chk_misc')       || 0 ;

    $self->debug_msg("\$chk_all        = $chk_all") ;
    $self->debug_msg("\$chk_users      = $chk_users") ;
    $self->debug_msg("\$chk_groups     = $chk_groups") ;
    $self->debug_msg("\$chk_pseudonyms = $chk_pseudonyms") ;
    $self->debug_msg("\$chk_printers   = $chk_printers") ;
    $self->debug_msg("\$chk_ibays      = $chk_ibays") ;
    $self->debug_msg("\$chk_misc       = $chk_misc") ;

    $filtadd   .= 'user|user-deleted|'           if ( $chk_users ) ;
    $filtadd   .= 'group|group-deleted|'         if ( $chk_groups ) ;
    $filtadd   .= 'pseudonym|pseudonym-deleted|' if ( $chk_pseudonyms ) ;
    $filtadd   .= 'printer|printer-deleted|'     if ( $chk_printers ) ;
    $filtadd   .= 'ibay|ibay-deleted|'           if ( $chk_ibays ) ;
    if ( $chk_misc ) { 
        $filtrem  = 'user|user-deleted|group|group-deleted|pseudonym|pseudonym-deleted|' ;
        $filtrem .= 'printer|printer-deleted|ibay|ibay-deleted' ;
    }
    # finally, if 'all' is checked, reset all others values !!!
    $filtadd    = $filtrem = ''                  if ( $chk_all ) ;
    # print "\$filtout = $filtout<br>\n" ;
    my $undef  = '&nbsp;' ;
    my $fundef = $q->param('displayundef') || 'BLANK' ;
    $undef     = $self->localise('IS_UNDEF') if ( $fundef eq 'UNDEF' ) ;
    my $blank  = "''" ;
    my $fblank = $q->param('displayblank') || 'QUOTES' ;
    $blank     = '&nbsp;'                    if ($fblank eq 'BLANK' ) ;
    $blank     = $self->localise('IS_EMPTY') if ($fblank eq 'EMPTY' ) ;

    # to complete user and group information, we read 
    # /etc/passwd and /etc/group in two arrays.
    my %User ; my %Group ;
    if ( open (USER, "/etc/passwd") ) {
        while ( defined(my $user = <USER> ) ) {
            chomp $user ;
            my $UID = $user ; $UID =~ s/^(.*:){2}(\d+):.*$/$2/ ;
            $User{ $UID } = $user ;
        }
    }
    close USER ;
    if ( open (GROUP, "/etc/group") ) {
        while ( defined(my $group = <GROUP> ) ) {
            chomp $group ;
            my $GID = $group ; $GID =~ s/^(.*:){2}(\d+):.*$/$2/ ;
            $Group{ $GID } = $group ;
        }
    }
    close GROUP ;


    # we create two 'normal' arrays : one for the columns label
    # one for the row label.
    # we create also a aray of aray, to store a two dimensional result.
    my %dblArr ; my %props; my @account ;

    foreach my $u ( @all ) {
        my $utype = $u->prop('type') || '';
        my $miscflag = 0 ;
        if ( $filtrem ne '' &&     $filtrem =~ /$utype/ ) { $miscflag = 1 ; }
        if ( $filtrem eq '' )                             { $miscflag = 1 ; }
        if ( $filtadd ne '' && ! ( $filtadd =~ /$utype/ ) && $miscflag ) { next }
        push @account, $u->key ;
        my %rops = $u->props ;

        foreach my $tp ( sort keys %rops ) {
            $props{ $tp } = 1;
            $dblArr{ $u->key, $tp } = $rops{ $tp } ;
            if ( $tp =~ /^uid$/i && defined $User{ $rops{ $tp } } ) { 
                # User exists in /etc/passwd !
                my @tmp = split /:/, $User{ $rops{ $tp } } ;
                my $du = 0;
                open(DU, "-|") or exec '/usr/bin/du', '-sh', $tmp[5];
                while (<DU>) { $du = $_ ; chomp $du ; $du =~ s/^(\S+)\s+.*$/$1/ ; }
                close DU;

                $props{ 'HomeDir' } = 1;
                $dblArr{ $u->key, 'HomeDir' } = $tmp[5] ;
                $props{ 'HomeDir_Usage' } = 1;
                $dblArr{ $u->key, 'HomeDir_Usage' } = $du ;
                $props{ 'Shell' } = 1;
                $dblArr{ $u->key, 'Shell' } = $tmp[6] ;
                $props{ '/etc/passwd : Name' } = 1;
                $dblArr{ $u->key, '/etc/passwd : Name' } = $tmp[0] ;
                $props{ '/etc/passwd : Comment' } = 1;
                $dblArr{ $u->key, '/etc/passwd : Comment' } = $tmp[4] ;
            }
            if ( $tp =~ /^gid$/i && defined $Group{ $rops{ $tp } } ) { 
                # Group exists in /etc/group !
                my @tmp = split /:/, $Group{ $rops{ $tp } } ;
                $props{ '/etc/group : Name' } = 1;
                $dblArr{ $u->key, '/etc/group : Name' } = $tmp[0] ;
                $props{ '/etc/group : Members' } = 1;
                $dblArr{ $u->key, '/etc/group : Members' } = $tmp[3] ;
            }
        }
    }

    # create the CSV output file
    my $CSVSep = ";" ;
    open (CSV, ">/etc/e-smith/web/common/displayconfig.csv" ) ;
    # 'spreadsheet' printout
    print "<table border=\"1\">\n" ;

    # Headers :
    my $header = "Record" . $CSVSep . "type" ;
    print "<tr><th>Record</th><th>type</th>" ;
    foreach my $t ( sort keys %props ) { 
        if ( $t ne 'type' ) {
            print "<th>$t</th>" ;
            $header .= $CSVSep . $t ;
        }
    } 
    print "</tr>\n" ;
    print CSV "$header\n" ;

    # Values
    foreach my $U ( sort @account ) {
        my $line = $U ;        
        print "<tr><td>$U</td>" ;
        my $type = $undef ;
        if ( defined $dblArr{ $U, 'type' } ) {
            $type  = $dblArr{ $U, 'type' } ;
        }
        print "<td>$type</td>" ;
        $line .= $CSVSep . $type ;
        foreach my $t ( sort keys %props ) {
            next if ( $t eq 'type' ) ;
            my $out = $undef ;
            # my $out = "&lt;Undef&gt;" ;
            $out = $dblArr{ $U,$t } if ( defined $dblArr{ $U,$t } ) ;
            $out = $blank if ( $out eq '' ) ;
            print "<td>$out</td>" ;
            $line .= $CSVSep . $out ;
        }
        print "</tr>\n" ;
        # &nbsp; are very nice in a HTML table, but are not so nice in 
        # a csv file.... So are also &lt; and &gt;
        $line =~ s/&nbsp;//ig ;
        $line =~ s/&lt;/</ig ;
        $line =~ s/&gt;/>/ig ;
        print CSV "$line\n" ;
    }  
    print "</table>\n" ;
    close CSV ;
    return undef ;

}

=head2 display_button

This method is used to display a button on the right place.

=cut

sub display_button {
    my $self = shift ;
    my $q = $self->cgi ;

    return "<a href=\"/server-common/displayconfig.csv\" type=\"application/vnd.ms-excel\">"
           . $self->localise('DOWNLOAD_FILE')
           . "</a>&nbsp;&nbsp;<input type=\"submit\" name=\"display\" value=\""
           . $self->localise('BUTTON_LABEL_DISPLAY' ) . "\">" ;
}

=head2 display_form

This method is used to start a new display.

=cut

sub display_form {
    my $self = shift ;
    my $q = $self->cgi ;

    $self->debug_msg("'display_form' begins.") ;
    # $self->cleanup_checkboxes() ;
    my @boxes = qw(all users groups ibays printers pseudonyms misc) ;
    foreach my $box (@boxes) {
        my $mbox = "chk_" . $box ;
        if ( ! ( $q->param( $mbox ) ) ) {
            $q->delete( $mbox ) ;
        }
    }

    $self->debug_msg("\$self->wherenext(\"First\");") ;
    $self->wherenext("First") ;
}

# never forget the final 1 ;-)
1;
