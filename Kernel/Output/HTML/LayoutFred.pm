# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::LayoutFred;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

=over

=item CreateFredOutput()

create the output of the several fred modules

    $LayoutObject->CreateFredOutput(
        FredModulesRef => $FredModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{FredModulesRef} || ref $Param{FredModulesRef} ne 'HASH' ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need FredModulesRef!',
        );
        return;
    }

    MODULENAME:
    for my $ModuleName ( sort keys %{ $Param{FredModulesRef} } ) {

        # load backend
        my $BackendObject = $Self->_LoadLayoutBackend( ModuleName => $ModuleName );

        # get module data
        next MODULENAME if !$BackendObject;

        $BackendObject->CreateFredOutput(
            ModuleRef => $Param{FredModulesRef}->{$ModuleName},
        );
    }

    return 1;
}

=item _LoadLayoutBackend()

load a special fred layout backends

    $BackendObject = $LayoutObject->_LoadLayoutBackend(
        ModuleName => $ModuleName,
    );

=cut

sub _LoadLayoutBackend {
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
    my $GenericModule = 'Kernel::Output::HTML::Fred' . $Param{ModuleName};
    if ( $Self->{MainObject}->Require($GenericModule) ) {

        my $BackendObject = $GenericModule->new(
            %{$Self},
            %Param,
            LayoutObject => $Self,
        );

        return $BackendObject if $BackendObject;
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
