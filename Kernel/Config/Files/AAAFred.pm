# --
# AAAFred.pm - the config to bind STDERR to an log file usable for fred
# Copyright (C) 2003-2007 OTRS GmbH, http://otrs.com/
# --
# $Id: AAAFred.pm,v 1.1 2007-02-27 20:48:38 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

    if ($ENV{HTTP_USER_AGENT}) {
        # check log file size
        my $Size = -s $Self->{Home}."/var/fred.log";
        if ($Size > 20*1024*1024) {
            unlink $Self->{Home}."/var/fred.log";
        }
        # create tmp file handle
        open(OLDOUT, ">&STDERR");
        # move STDOUT to tmp file
        if (!open(STDERR, ">> ".$Self->{Home}."/var/fred.log")) {
            print STDERR "ERROR: Can't write $Self->{Home}/var/fred.log: $!";
        }
        # restore STDOUT file handle
#       open(STDOUT, ">&OLDOUT");
        close(OLDOUT);
    }

1;
