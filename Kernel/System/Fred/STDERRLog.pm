# --
# Kernel/System/Fred/STDERRLog.pm
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::STDERRLog;
## no critic(Perl::Critic::Policy::OTRS::ProhibitOpen)

use strict;
use warnings;

use IO::Handle;

=head1 NAME

Kernel::System::Fred::STDERRLog

=head1 SYNOPSIS

handle the STDERR log data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::STDERRLog;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $FredObject = Kernel::System::Fred::STDERRLog->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

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
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ModuleRef)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # Make sure that we get everything to disk before trying to read it (otherwise content could be lost).
    STDERR->flush();

    # open the STDERR.log file to get the STDERR messages
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/STDERR.log';
    my $Filehandle;

    if ( !open $Filehandle, '<:encoding(UTF-8)', $File ) {
        $Param{ModuleRef}->{Data} = [
            "Perhaps you don't have permission at /var/fred/ or /Kernel/Config/Files/AAAFred.pm.",
            "Can't read /var/fred/STDERR.log",
        ];
        return;
    }

    # Read log until last "FRED" marker.
    my @LogMessages;
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ m{ \A \s* FRED \s* \z}xms;
        push @LogMessages, $Line;
    }
    close $Filehandle;

    print STDERR "\nFRED\n";

    # trim the log message array
    LINE:
    for my $Line (@LogMessages) {
        last LINE if $Line !~ m{ \A \s* \z }xms;
        shift @LogMessages;
    }

    # trim the log message array
    LINE:
    for my $Line ( reverse @LogMessages ) {
        last LINE if $Line !~ m{ \A \s* \z }xms;
        shift @LogMessages;
    }

    $Param{ModuleRef}->{Data} = \@LogMessages;

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
