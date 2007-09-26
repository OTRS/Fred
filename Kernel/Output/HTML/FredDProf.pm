# --
# Kernel/Output/HTML/FredDProf.pm - layout backend module
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: FredDProf.pm,v 1.2 2007-09-26 10:02:58 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::FredDProf;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.2 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::Output::HTML::FredDProf - layout backend module

=head1 SYNOPSIS

All layout functions of DProf object

=over 4

=cut

=item new()

create a object

    $BackendObject = Kernel::Output::HTML::FredDProf->new(
        %Param,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

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

create the output of the DProf profiling tool

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my $Self      = shift;
    my %Param     = @_;
    my $HTMLLines = '';

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    # prepare the profiling data for a better readability
    if ($Param{ModuleRef}->{Data}) {
        for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
            map $Self->{LayoutObject}->Ascii2Html(Text => $_), @{$Line};
            $HTMLLines .= "        <tr>\n"
                        . "          <td align=\"right\">$Line->[0]</td>\n"
                        . "          <td align=\"right\">$Line->[1]</td>\n"
                        . "          <td align=\"right\">$Line->[2]</td>\n"
                        . "          <td align=\"right\">$Line->[3]</td>\n"
                        . "          <td align=\"right\">$Line->[4]</td>\n"
                        . "          <td align=\"right\">$Line->[5]:</td>\n"
                        . "          <td>$Line->[6]</td>\n"
                        . "        </tr>\n";
        }
        $Self->{LayoutObject}->Block(
            Name => 'TimeTable',
            Data => {
                HTMLLines => $HTMLLines,
                TotalTime => $Param{ModuleRef}->{TotalTime},
            },
        );
    }
    elsif ($Param{ModuleRef}->{FunctionTree}) {
        for my $Line ( @{ $Param{ModuleRef}->{FunctionTree} } ) {
            map $Self->{LayoutObject}->Ascii2Html(Text => $_), @{$Line};
            $Line->[1] =~ s/ /&nbsp;&nbsp;/g;
            $HTMLLines .= "        <tr>\n"
                        . "          <td align=\"right\">$Line->[0]</td>\n"
                        . "          <td>$Line->[1]</td>\n"
                        . "        </tr>\n";
        }
        $Self->{LayoutObject}->Block(
            Name => 'FunctionList',
            Data => {
                HTMLLines => $HTMLLines,
            },
        );
    }
    # show the profiling data
    if ($HTMLLines) {
        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredDProf',
        );
    }

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.2 $ $Date: 2007-09-26 10:02:58 $

=cut