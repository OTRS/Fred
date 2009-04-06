# --
# Kernel/Output/HTML/LayoutFred.pm - provides generic HTML output for fred
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: LayoutFred.pm,v 1.4 2009-04-06 10:25:13 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::LayoutFred;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.4 $) [1];

=item CreateFredOutput()

create the output of the several fred modules

    $LayoutObject->CreateFredOutput(
        FredModulesRef => $FredModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{FredModulesRef} || ref( $Param{FredModulesRef} ) ne 'HASH' ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need FredModulesRef!',
        );
        return;
    }

    for my $ModuleName ( keys %{ $Param{FredModulesRef} } ) {

        # load backend
        my $BackendObject = $Self->_LoadLayoutBackend( ModuleName => $ModuleName );

        # get module data
        if ($BackendObject) {
            $BackendObject->CreateFredOutput( ModuleRef => $Param{FredModulesRef}->{$ModuleName} );
        }
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

        if ($BackendObject) {
            return $BackendObject;
        }
    }

    return;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.4 $ $Date: 2009-04-06 10:25:13 $

=cut
