#!/usr/local/bin/perl -T

# index.cgi
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
# $Id: index.cgi,v 1.1.1.1 2008/07/03 16:00:56 sschneid Exp $

BEGIN { unshift @INC, './lib'; }

use strict;

eval {
    require f5poolmgr;

    my $f5poolmgr = f5poolmgr->new(
        tmpl_path => 'thtml/'
    );

    $f5poolmgr->run();
};

if ( $@ ) { print "f5poolmgr error: $@"; }

