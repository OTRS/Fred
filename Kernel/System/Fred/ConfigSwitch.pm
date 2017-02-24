# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::ConfigSwitch;
## no critic(Perl::Critic::Policy::OTRS::ProhibitOpen)

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
);

=head1 NAME

Kernel::System::Fred::ConfigSwitch

=head1 SYNOPSIS

handle the config log data

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item DataGet()

Get the data for this Fred module. Returns true or false.
And add the data to the module ref.

    $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    my $Config = $ConfigObject->Get('Fred::ConfigSwitch');

    return if !$Config->{Settings};

    my @ConfigItems;
    for my $Item ( sort @{ $Config->{Settings} } ) {
        push @ConfigItems, {
            Key   => $Item,
            Value => $ConfigObject->Get($Item),
        };
    }

    $Param{ModuleRef}->{Data} = \@ConfigItems;

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
