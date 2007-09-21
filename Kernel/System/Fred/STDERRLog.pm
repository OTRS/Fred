# --
# Kernel/System/Fred/STDERRLog.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: STDERRLog.pm,v 1.1 2007-09-21 08:09:09 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred::STDERRLog;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred::STDERRLog

=head1 SYNOPSIS

handle the STDERR log data

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Log;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(ConfigObject LogObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }
    return $Self;
}

=item DataGet()

Get the data for this fred module. Returns true or false.
And add the data to the module ref.

    $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need ModuleRef!",
        );
        return;
    }

    # open the fred.log file to get the STDERR messages
    my $File = $Self->{ConfigObject}->Get('Home') . "/var/fred.log";
    if ( open my $Filehandle, '<', $File ) {
        my @Row        = <$Filehandle>;
        my @ReverseRow = reverse(@Row);
        my @LogMessages;
        for my $Line (@ReverseRow) {
            if ( $Line =~ /FRED/ ) {
                last;
            }
            if ( $Line !~ /Subroutine .+? redefined at/ ) {
                push @LogMessages, $Line;
            }
        }

        print STDERR "FRED\n";
        close $Filehandle;
        ${ $Param{ModuleRef} }{Data} = \@LogMessages;
    }
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.1 $ $Date: 2007-09-21 08:09:09 $

=cut