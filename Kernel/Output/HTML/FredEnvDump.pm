# --
# Kernel/Output/HTML/FredEnvDump.pm - layout backend module
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredEnvDump;

use strict;
use warnings;

use Data::Dumper;

=head1 NAME

Kernel::Output::HTML::FredEnvDump - show dump of the environment ref, data for $Env in dtl

=head1 SYNOPSIS

All layout functions of the layout env dump object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredEnvDump->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject LogObject LayoutObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item CreateFredOutput()

Get the session data and create the output of the session dump

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    # Kernel::System::Fred::EnvDump::DataGet() is not used,
    # as the data of interest is not easily available there.

    # create a string representation of the data of interest
    my $Dumper = Data::Dumper->new(
        [ $Self->{LayoutObject}->{EnvRef} ],
        [qw(EnvRef)],
    );

    # impose string representation in double quoted style
    $Dumper->Useqq(1);

    # Sort the hashkeys
    $Dumper->Sortkeys(1);

    my $Dump = $Dumper->Dump();

    # output the html
    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredEnvDump',
        Data => { Dump => $Dump },
    );

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

=cut
