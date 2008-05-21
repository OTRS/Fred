# --
# AAAFred.pm - the config to bind STDERR to an log file usable for fred
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: AAAFred.pm,v 1.8 2008-05-21 10:11:56 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

if ( $ENV{HTTP_USER_AGENT} ) {

    # check if the needed path is available
    my $Path = $Self->{Home} . '/var/fred';
    if ( !-e $Path ) {
        mkdir $Path;
    }

    my $File = $Self->{Home} . '/var/fred/STDERR.log';

    # check log file size
    if ( -s $File > 20 * 1024 * 1024 ) {
        unlink $File;
    }

    # move STDOUT to tmp file
    if ( !open STDERR, '>>', $File ) {
        print STDERR "ERROR: Can't write $File!";
    }
}

1;
