# --
# Kernel/Output/HTML/FredSTDERRLog.pm - layout backend module
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: FredSTDERRLog.pm,v 1.9 2009-03-31 12:45:11 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredSTDERRLog;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.9 $) [1];

=head1 NAME

Kernel::Output::HTML::FredSTDERRLog - layout backend module

=head1 SYNOPSIS

All layout functions of STDERR log objects

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredSTDERRLog->new(
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

create the output of the STDERR log

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

    return if !$Param{ModuleRef}->{Data};
    return if ref $Param{ModuleRef}->{Data} ne 'ARRAY';

    # create html string
    my $HTMLLines;
    for my $Line ( reverse @{ $Param{ModuleRef}->{Data} } ) {

        # convert ascii to html
        $HTMLLines .= $Self->{LayoutObject}->Ascii2Html(
            Text           => $Line,
            HTMLResultMode => 1,
            Type           => 'Normal',
        );
    }

    return if !$HTMLLines;

    $HTMLLines = "<tr><td>$HTMLLines</td></tr>";

    # output the html
    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredSTDERRLog',
        Data         => {
            HTMLLines => $HTMLLines,
        },
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

$Revision: 1.9 $ $Date: 2009-03-31 12:45:11 $

=cut
