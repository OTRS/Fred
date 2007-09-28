# --
# Kernel/Output/HTML/FredConfigLog.pm - layout backend module
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: FredConfigLog.pm,v 1.3 2007-09-28 06:58:23 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::FredConfigLog;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.3 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::Output::HTML::FredConfigLog - layout backend module

=head1 SYNOPSIS

All layout functions of the config log module

=over 4

=cut

=item new()

create a object

    $BackendObject = Kernel::Output::HTML::FredConfigLog->new(
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

create the output of the translationdebugging log

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

    for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
        for my $TD (@{$Line}) {
            $TD = $Self->{LayoutObject}->Ascii2Html(Text => $TD);
        }
        if ($Line->[1] eq 'True') {
            $Line->[1] = '';
        }
        $HTMLLines .= "        <tr>\n"
                    . "          <td align=\"right\">$Line->[3]</td>\n"
                    . "          <td>$Line->[0]</td>\n"
                    . "          <td>$Line->[1]</td>\n"
                    . "          <td>$Line->[2]</td>\n"
                    . "        </tr>";
    }

    if ($HTMLLines) {
        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredConfigLog',
            Data         => {
                HTMLLines => $HTMLLines,
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
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.3 $ $Date: 2007-09-28 06:58:23 $

=cut
