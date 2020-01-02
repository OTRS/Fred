# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Fred;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

=head1 NAME

Kernel::System::Fred - fred core lib

=head1 SYNOPSIS

All fred standard core functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::Fred;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $FredObject = Kernel::System::Fred->new(
        LogObject    => $LogObject,
        ConfigObject => $ConfigObject,
        MainObject   => $MainObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject LogObject MainObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item DataGet()

Evaluate the several data of all fred modules and add them
on the FredModules reference.

    $FredObject->DataGet(
        FredModulesRef => $FredModulesRef,
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{FredModulesRef} || ref( $Param{FredModulesRef} ) ne 'HASH' ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need FredModulesRef!',
        );
        return;
    }
    if ( !$Param{HTMLDataRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need HTMLDataRef!',
        );
        return;
    }

    for my $ModuleName ( sort keys %{ $Param{FredModulesRef} } ) {

        # load backend
        my $BackendObject = $Self->_LoadBackend( ModuleName => $ModuleName );

        # get module data
        if ($BackendObject) {
            $BackendObject->DataGet(
                ModuleRef      => $Param{FredModulesRef}->{$ModuleName},
                HTMLDataRef    => $Param{HTMLDataRef},
                FredModulesRef => $Param{FredModulesRef},
            );
        }
    }

    return 1;
}

=item _LoadBackend()

load a xml item module

    $BackendObject = $FredObject->_LoadBackend(
        ModuleName => $ModuleName,
    );

=cut

sub _LoadBackend {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleName} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleName!',
        );
        return;
    }

    # load backend
    my $GenericModule = 'Kernel::System::Fred::' . $Param{ModuleName};
    if ( $Self->{MainObject}->Require($GenericModule) ) {
        my $BackendObject = $GenericModule->new( %{$Self}, %Param, );

        if ($BackendObject) {

            # return object
            return $BackendObject;
        }
    }

    return;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
