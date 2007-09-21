# --
# AAAFred.pm - the config to bind STDERR to an log file usable for fred
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: AAAFred.pm,v 1.3 2007-09-21 07:44:15 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

use strict;
use warnings;

if ($ENV{HTTP_USER_AGENT}) {
    # check log file size
    my $Size = -s $Self->{Home}."/var/fred.log";
    if ($Size > 20*1024*1024) {
        unlink $Self->{Home}."/var/fred.log";
    }

    # move STDOUT to tmp file
    if (!open(STDERR, '>>', "$Self->{Home}/var/fred.log")) {
        print STDERR "ERROR: Can't write $Self->{Home}/var/fred.log: $!";
    }
}
1;
