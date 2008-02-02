# --
# Kernel/Output/HTML/FredSmallProf.pm - layout backend module
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: FredSmallProf.pm,v 1.6 2008-02-02 12:44:16 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

package Kernel::Output::HTML::FredSmallProf;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.6 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::Output::HTML::FredSmallProf - layout backend module

=head1 SYNOPSIS

All layout functions of SmallProf object

=over 4

=cut

=item new()

create a object

    $BackendObject = Kernel::Output::HTML::FredSmallProf->new(
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

create the output of the SmallProf profiling tool

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
    for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
        for my $TD (@{$Line}) {
            $TD = $Self->{LayoutObject}->Ascii2Html(Text => $TD);
        }
        $HTMLLines .= "        <tr>\n"
                    . "          <td align=\"right\">$Line->[2]</td>\n"
                    . "          <td align=\"right\">$Line->[3]</td>\n"
                    . "          <td align=\"right\">$Line->[4]</td>\n"
                    . "          <td>$Line->[0]</td>\n"
                    . "          <td align=\"right\">$Line->[1]:</td>\n"
                    . "          <td>$Line->[5]</td>\n"
                    . "        </tr>";
    }

    # get all packages which SmallProf checks
    my $Packages = '';
    if ($Param{ModuleRef}->{Packages}) {
        $Packages = join ' - ', @{ $Param{ModuleRef}->{Packages} };
    }

    # show the profiling data
    if ($HTMLLines) {
        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredSmallProf',
            Data         => {
                HTMLLines => $HTMLLines,
                TotalCall => $Param{ModuleRef}->{TotalCall},
                Packages  => $Packages,
            },
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

$Revision: 1.6 $ $Date: 2008-02-02 12:44:16 $

=cut