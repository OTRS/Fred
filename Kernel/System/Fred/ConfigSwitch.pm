# --
# Kernel/System/Fred/ConfigSwitch.pm
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::ConfigSwitch;
## no critic(Perl::Critic::Policy::OTRS::ProhibitOpen)

use strict;
use warnings;

use Scalar::Util();

=head1 NAME

Kernel::System::Fred::ConfigSwitch

=head1 SYNOPSIS

handle the config log data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::ConfigSwitch;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $FredObject = Kernel::System::Fred::ConfigSwitch->new(
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
    for my $Object (qw(ConfigObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    # ConfigObject holds a reference to us, so don't reference it to avoid
    #   a ring reference.
    Scalar::Util::weaken( $Self->{ConfigObject} );

    # Don't call ConfigObject->Get() here, this could cause deep recursions.

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

    my $Config = $Self->{ConfigObject}->Get('Fred::ConfigSwitch');

    return if !$Config->{Settings};

    my @ConfigItems;
    for my $Item ( sort @{ $Config->{Settings} } ) {
        push @ConfigItems, {
            Key   => $Item,
            Value => $Self->{ConfigObject}->Get($Item),
        };
    }

    $Param{ModuleRef}->{Data} = \@ConfigItems;

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
