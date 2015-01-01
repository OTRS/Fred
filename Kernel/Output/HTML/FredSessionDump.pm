# --
# Kernel/Output/HTML/FredSessionDump.pm - layout backend module
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredSessionDump;
## nofilter(TidyAll::Plugin::OTRS::Perl::Dumper)

use strict;
use warnings;

use Data::Dumper;

=head1 NAME

Kernel::Output::HTML::FredSessionDump - layout backend module

=head1 SYNOPSIS

All layout functions of the session dump object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredSessionDump->new(
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

    # Data is generated here, as it is not available in Kernel::System::Fred::SessionDump
    my $SessionID = $Self->{LayoutObject}->{EnvRef}->{SessionID};
    my %SessionData;
    if ($SessionID) {
        %SessionData = $Self->{LayoutObject}->{SessionObject}->GetSessionIDData( SessionID => $SessionID );
    }

    for my $Key ( sort keys %SessionData ) {

        $Self->{LayoutObject}->Block(
            Name => 'SessionDataRow',
            Data => {
                Key   => $Key,
                Value => $SessionData{$Key},
            },
        );
    }

    # output the html
    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredSessionDump',
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
