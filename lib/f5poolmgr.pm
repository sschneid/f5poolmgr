# f5poolmgr.pm
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# $Id: f5poolmgr.pm,v 1.1.1.1 2008/07/03 16:00:57 sschneid Exp $

package f5poolmgr;

use base 'CGI::Application';

use f5poolmgr::Util;

use MIME::Base64;
use Net::LDAP;
use POSIX qw( strftime );
use SOAP::Lite;

use Socket;
use iControlTypeCast;

use strict;
use warnings;

sub setup {
    my $self = shift;

    $self->{'util'} = f5poolmgr::Util->new();

    # Read configuration from f5poolmgr.cfg
    $self->{'config'} = $self->{'util'}->readConfig(
        configFile => 'f5poolmgr.cfg'
    )
    || die qq(Error reading configuration file f5poolmgr.cfg\n);

    # Read and untaint CGI parameters
    $self->{'cgi'} = $self->query();

    map {
        my $raw = [ $self->{'cgi'}->param($_) ];
        $self->{'arg'}->{$_} = @$raw > 1 ? $raw : $raw->[0];
    } $self->{'cgi'}->param();

    $self->{'arg'} = $self->{'util'}->untaintCGI( cgi => $self->{'cgi'} );

    # Get (LDAP) pool access list
    my $ldap = Net::LDAP->new( $self->{'config'}->{'ldap.server'} );

    my $mesg = $ldap->search(
        base => $self->{'config'}->{'ldap.base.group'},
        filter => "(uniquemember=uid=$ENV{'REMOTE_USER'},$self->{'config'}->{'ldap.base.people'})"
    );

    foreach my $entry ( $mesg->entries() ) {
        next unless $self->{'config'}->{'pools.' . $entry->get_value(  'cn' )};

        foreach my $pool ( @{$self->{'config'}->{'pools.' . $entry->get_value(  'cn' )}} ) {
            $self->{'access'}->{$pool} = '1';
        }
    }

    $ldap->disconnect();

    # Logging
    if ( $self->{'config'}->{'audit.log'} ) {
        if ( open( LOG, ">>$self->{'config'}->{'audit.log'}" ) ) {
            $self->{'audit'} = 1;
        }
    }

    # Initialize and authenticate SOAP::Lite connections
    $self->{'soap'}->{'pool'} = SOAP::Lite
        ->uri  ( 'urn:iControl:LocalLB/Pool' )
        ->proxy(
            'https://'
          . $self->{'config'}->{'server'}
          . ':443/iControl/iControlPortal.cgi'
        );
    $self->{'soap'}->{'pool'}->transport->http_request->header(
        'Authorization' => 'Basic ' . MIME::Base64::encode(
            $self->{'config'}->{'username'} . ':'
          . $self->{'config'}->{'password'}, ''
        )
    );

    $self->{'soap'}->{'member'} = SOAP::Lite
        ->uri  ( 'urn:iControl:LocalLB/PoolMember' )
        ->proxy(
            'https://'
          . $self->{'config'}->{'server'}
          . ':443/iControl/iControlPortal.cgi'
        );
    $self->{'soap'}->{'member'}->transport->http_request->header(
        'Authorization' => 'Basic ' . MIME::Base64::encode(
            $self->{'config'}->{'username'} . ':'
          . $self->{'config'}->{'password'}, ''
        )
    );

    # CGI::Application run-mode initialization
    $self->run_modes( [ qw/
        actionClearStats
        actionSetSession
        actionSetState
        displayPool
        displayPoolList
    / ] );

    $self->start_mode( 'displayPool' );

    return( $self );
}

sub teardown {
    my $self = shift;

    close( LOG ) if $self->{'audit'};
}

sub actionClearStats {
    my $self = shift;

    unless (
        $self->{'access'}->{$self->{'arg'}->{'pool'}} ||
        $self->{'access'}->{'*'}
    ) {
        return $self->displayPoolList();
    }

    $self->{'soap'}->{'pool'}->reset_statistics(
        SOAP::Data->name( pool_names => [ $self->{'arg'}->{'pool'} ] )
    );

    return $self->displayPool();
}

sub actionSetSession {
    my $self = shift;

    unless (
        $self->{'access'}->{$self->{'arg'}->{'pool'}} ||
        $self->{'access'}->{'*'}
    ) {
        return $self->displayPoolList();
    }

    my $state = $self->{'arg'}->{'state'} eq '0'
        ? 'ENABLED'
        : 'DISABLED';

    my ( $addr, $port ) = split( /:/, $self->{'arg'}->{'member'} );

    my $set = {
        member => {
            address => $addr,
            port    => $port
        },
        session_state => 'STATE_' . $state
    };

    $self->{'soap'}->{'member'}->set_session_enabled_state(
        SOAP::Data->name( pool_names => [ $self->{'arg'}->{'pool'} ] ),
        SOAP::Data->name( session_states => [ [ $set ] ] )
    );

    $self->_log(
        pool => $self->{'arg'}->{'pool'},
        member => "$addr:$port",
        type => 'session',
        state => $state
    ) if $self->{'audit'};

    return $self->displayPool();
}

sub actionSetState {
    my $self = shift;

    unless (
        $self->{'access'}->{$self->{'arg'}->{'pool'}} ||
        $self->{'access'}->{'*'}
    ) {
        return $self->displayPoolList();
    }

    my $state = $self->{'arg'}->{'state'} eq '0'
        ? 'ENABLED'
        : 'DISABLED';

    my ( $addr, $port ) = split( /:/, $self->{'arg'}->{'member'} );

    my $set = {
        member => {
            address => $addr,
            port    => $port
        },
        monitor_state => 'STATE_' . $state
    };

    $self->{'soap'}->{'member'}->set_monitor_state(
        SOAP::Data->name( pool_names => [ $self->{'arg'}->{'pool'} ] ),
        SOAP::Data->name( monitor_states => [ [ $set ] ] )
    );

    $self->_log(
        pool => $self->{'arg'}->{'pool'},
        member => "$addr:$port",
        type => 'state',
        state => $state
    ) if $self->{'audit'};

    return $self->displayPool();
}

sub displayPool {
    my $self = shift;

    return $self->displayPoolList() unless $self->{'arg'}->{'pool'};

    unless (
        $self->{'access'}->{$self->{'arg'}->{'pool'}} ||
        $self->{'access'}->{'*'}
    ) {
        return $self->displayPoolList();
    }

    my ( $pool, $member, $memberList );

    # Get member statistics
    foreach (
        @{${$self->{'soap'}->{'member'}->get_all_statistics(
            SOAP::Data->name( pool_names => [ $self->{'arg'}->{'pool'} ] )
        )->result()}[0]->{'statistics'}}
    ) {
        my $node = "$_->{'member'}->{'address'}:$_->{'member'}->{'port'}";

        foreach my $stat ( @{$_->{'statistics'}} ) {
            for ( $stat->{'type'} ) {
                /STATISTIC_SERVER_SIDE_CURRENT_CONNECTIONS/ && do {
                    $member->{$node}->{'connections'}->{'active'} =
                        $stat->{'value'}->{'low'};
                    $pool->{'connections'}->{'active'} +=
                        $stat->{'value'}->{'low'};
                };
                /STATISTIC_SERVER_SIDE_TOTAL_CONNECTIONS/ && do {
                    $member->{$node}->{'connections'}->{'total'} =
                        $stat->{'value'}->{'low'};
                    $pool->{'connections'}->{'total'} +=
                        $stat->{'value'}->{'low'};
                };
            }
        }
    }

    # Get member state/session status
    foreach (
        @{${$self->{'soap'}->{'member'}->get_object_status(
            SOAP::Data->name( pool_names => [ $self->{'arg'}->{'pool'} ] )
        )->result()}[0]}
    ) {
        $memberList .= $self->_wrap(
            container  => 'poolMember',
            pool => $self->{'arg'}->{'pool'},
            memberFQDN => gethostbyaddr(
                inet_aton( $_->{'member'}->{'address'} ), AF_INET
            ) || $_->{'member'}->{'address'},
            memberIP => "$_->{'member'}->{'address'}:$_->{'member'}->{'port'}",
            connectionActive => $member
                ->{"$_->{'member'}->{'address'}:$_->{'member'}->{'port'}"}
                ->{'connections'}->{'active'},
            connectionTotal => $member
                ->{"$_->{'member'}->{'address'}:$_->{'member'}->{'port'}"}
                ->{'connections'}->{'total'},
            desc => $_->{'object_status'}->{'status_description'},
            session =>
                $_->{'object_status'}->{'enabled_status'} =~ /ENABLED$/
                ? 1 : 0,
            state  =>
                $_->{'object_status'}->{'availability_status'} =~ /GREEN$/
                ? 1 : 0
        );
    }

    return $self->_wrapAll(
        container => 'pool',
        pool => $self->{'arg'}->{'pool'},
        connectionsActive => $pool->{'connections'}->{'active'},
        connectionsTotal => $pool->{'connections'}->{'total'},
        memberList => $memberList
    );
}

sub displayPoolList {
    my $self = shift;

    my ( @poolList );

    if ( $self->{'access'}->{'*'} ) {
        @poolList = @{$self->{'soap'}->{'pool'}->get_list->result()};
    }
    else {
        foreach my $pool ( @{$self->{'soap'}->{'pool'}->get_list->result()} ) {
            push @poolList, $pool if $self->{'access'}->{$pool};
        }
    }

    return $self->_wrapAll(
        container => 'poolList',
        poolList => $self->{'cgi'}->popup_menu(
            -name => 'pool',
            -values => [ sort { lc( $a ) cmp lc( $b ) } @poolList ]
        )
    );
}

sub _log {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;
    
    my $stamp = '[' . strftime( "%e/%b/%Y:%H:%M:%S", localtime() ) . ']';

    print LOG join( ' ', 
        $ENV{'REMOTE_USER'}, $stamp,
        $arg->{'pool'}, $arg->{'member'}, $arg->{'type'}, $arg->{'state'}
    ) . "\n";

    return 1;
}

sub _wrap {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    my $template = $self->load_tmpl(
        $arg->{'container'} . '.thtml',
        die_on_bad_params => 0,
        cache => 1
    );

    delete $arg->{'container'};

    map {
        chomp( $arg->{$_} );
        $template->param( $_ => $arg->{$_} );
    } keys %{$arg};

    return( $template->output() );
}

sub _wrapAll {
    my $self = shift;

    my ( $arg );
    %{$arg} = @_;

    my $template = $self->load_tmpl(
        $arg->{'container'} . '.thtml',
        die_on_bad_params => 0,
        cache => 1
    );

    delete $arg->{'container'};

    map {
        chomp( $arg->{$_} );
        $template->param( $_ => $arg->{$_} );
    } keys %{$arg};

    my $page = $self->load_tmpl(
        'index.thtml',
        die_on_bad_params => 0,
        cache => 1
    );

    $page->param( container => $template->output() );

    return( $page->output() );
}

1;
