# --
# Kernel/Output/HTML/FredBenchmark.pm - layout backend module
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: FredBenchmark.pm,v 1.4 2009-04-06 10:25:13 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredBenchmark;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.4 $) [1];

=head1 NAME

Kernel::Output::HTML::FredBenchmark - layout backend module

=head1 SYNOPSIS

All layout functions of the benchmark object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredBenchmark->new(
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

    my $HTMLLines = '';
    for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
        $HTMLLines .= '<tr>';
        for my $Cell ( @{$Line} ) {
            $HTMLLines .= "<td>$Cell</td>";
        }
        $HTMLLines .= '</tr>';
    }

    return if !$HTMLLines;

    # output the html
    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredBenchmark',
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

$Revision: 1.4 $ $Date: 2009-04-06 10:25:13 $

=cut
