# --
# AAAFred.pm - the config to bind STDERR to an log file usable for fred
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: AAAFred.pm,v 1.4 2007-09-25 12:30:39 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

if ($ENV{HTTP_USER_AGENT}) {
    my $File = $Self->{'Home'} . '/var/fred/STDERR.log';

    # check log file size
    my $Size = -s $File;
    if ($Size > 20*1024*1024) {
        unlink $File;
    }

    # move STDOUT to tmp file
    if (!open(STDERR, '>>', $File)) {
        print STDERR "ERROR: Can't write $File!";
    }
}
1;
