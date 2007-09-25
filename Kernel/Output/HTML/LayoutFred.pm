# --
# Kernel/Output/HTML/LayoutFred.pm - provides generic HTML output for fred
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: LayoutFred.pm,v 1.2 2007-09-25 21:52:09 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::LayoutFred;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.2 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=item CreateFredOutput()

create the output of the several fred modules

    $LayoutObject->CreateFredOutput(
        FredModulesRef => $FredModulesRef,
    );

=cut

sub CreateFredOutput {
    my $Self  = shift;
    my %Param = @_;

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
    my $Self  = shift;
    my %Param = @_;

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
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.2 $ $Date: 2007-09-25 21:52:09 $

=cut