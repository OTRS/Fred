# --
# Kernel/Output/HTML/FredSessionDump.pm - layout backend module
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: FredSessionDump.pm,v 1.3 2009-12-11 08:46:15 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredSessionDump;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.3 $) [1];

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

    # Data is generated here, as it is not available in Kernel::System::Fred::SessionData
    my $SessionID = $Self->{LayoutObject}->{EnvRef}->{SessionID};
    my %SessionData;
    if ($SessionID) {
        %SessionData
            = $Self->{LayoutObject}->{SessionObject}->GetSessionIDData( SessionID => $SessionID );
    }

    # create a string representation of the data of interest
    my $Dumper = Data::Dumper->new(
        [ $SessionID, \%SessionData ],
        [qw(SessionID SessionData)],
    );

    # impose string representation in double quoted style
    $Dumper->Useqq(1);

    # Sort the hashkeys
    $Dumper->Sortkeys(1);

    my $Dump = $Dumper->Dump();

    # output the html
    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredSessionDump',
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
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.3 $ $Date: 2009-12-11 08:46:15 $

=cut
