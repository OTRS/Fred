# --
# Kernel/Output/HTML/FredDProf.pm - layout backend module
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: FredDProf.pm,v 1.7 2008-05-21 10:11:57 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

package Kernel::Output::HTML::FredDProf;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.7 $) [1];

=head1 NAME

Kernel::Output::HTML::FredDProf - layout backend module

=head1 SYNOPSIS

All layout functions of DProf object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredDProf->new(
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

create the output of the DProf profiling tool

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

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
    if ( $Param{ModuleRef}->{Data} ) {
        for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
            for my $TD ( @{$Line} ) {
                if ( !defined($TD) ) {
                    $TD = '';
                }
                $TD = $Self->{LayoutObject}->Ascii2Html( Text => $TD );
            }

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
                TotalCall => $Param{ModuleRef}->{TotalCall},
            },
        );
    }
    elsif ( $Param{ModuleRef}->{FunctionTree} ) {
        for my $Line ( @{ $Param{ModuleRef}->{FunctionTree} } ) {
            for my $TD ( @{$Line} ) {
                $TD = $Self->{LayoutObject}->Ascii2Html( Text => $TD );
            }
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
did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.

=cut

=head1 VERSION

$Revision: 1.7 $ $Date: 2008-05-21 10:11:57 $

=cut
