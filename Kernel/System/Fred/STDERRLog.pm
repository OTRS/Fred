# --
# Kernel/System/Fred/STDERRLog.pm
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: STDERRLog.pm,v 1.17 2012-11-20 19:00:13 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::STDERRLog;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.17 $) [1];

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
    for my $Needed_Ref (qw(ModuleRef)) {
        if ( !$Param{$Needed_Ref} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed_Ref!",
            );
            return;
        }
    }

    # open the STDERR.log file to get the STDERR messages
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/STDERR.log';
    my $Filehandle;
    if ( !open $Filehandle, '<', $File ) {
        $Param{ModuleRef}->{Data} = [
            "Perhaps you don't have permission at /var/fred/ or /Kernel/Config/Files/AAAFred.pm.",
            "Can't read /var/fred/STDERR.log",
        ];
        return;
    }

    # get the whole information
    my @LogMessages;
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ m{ \A \s* FRED \s* \z}xms;

        # Attention: the last two strings are because of DProf. I have to force the process.
        # So I get this warnings!
        if (
            $Line
            !~ /(Subroutine .+? redefined at|has .+? unstacked calls|Faking .+? exit timestamp)/
            )
        {
            push @LogMessages, $Line;
        }
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

=item ActivateModuleTodos()

Do all jobs which are necessary to activate this special module.

    $FredObject->ActivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub ActivateModuleTodos {
    return 1;
}

=item DeactivateModuleTodos()

Do all jobs which are necessary to deactivate this special module.

    $FredObject->DeactivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub DeactivateModuleTodos {
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

=head1 VERSION

$Revision: 1.17 $ $Date: 2012-11-20 19:00:13 $

=cut
