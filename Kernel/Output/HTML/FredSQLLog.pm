# --
# Kernel/Output/HTML/FredSQLLog.pm - layout backend module
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id: FredSQLLog.pm,v 1.10 2011-11-26 09:16:10 ub Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredSQLLog;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.10 $) [1];

=head1 NAME

Kernel::Output::HTML::FredSQLLog - layout backend module

=head1 SYNOPSIS

All layout functions of SQL log module

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredSQLLog->new(
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

create the output of the translationdebugging log

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

    for my $Line ( @{ $Param{ModuleRef}->{Data} } ) {
        for my $TD ( @{$Line} ) {
            $TD = $Self->{LayoutObject}->Ascii2Html( Text => $TD );
        }
        my $Class = '';
        if ( $Line->[5] ) {
            $Class = ' class="strong"';
        }

        $HTMLLines .= "        <tr$Class>\n"
            . "          <td>$Line->[0]&nbsp;</td>\n"
            . "          <td class=\"SQLStatement\">$Line->[1]&nbsp;</td>\n"
            . "          <td class=\"BindParameter\"><div>$Line->[2]&nbsp;</div></td>\n"
            . "          <td>$Line->[3]&nbsp;</td>\n"
            . "          <td>$Line->[4]&nbsp;</td>\n"
            . "          <td>$Line->[5]</td>\n"
            . "        </tr>";
    }

    if ($HTMLLines) {
        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredSQLLog',
            Data         => {
                HTMLLines        => $HTMLLines,
                AllStatements    => $Param{ModuleRef}->{AllStatements},
                DoStatements     => $Param{ModuleRef}->{DoStatements},
                SelectStatements => $Param{ModuleRef}->{SelectStatements},
                Time             => $Param{ModuleRef}->{Time},
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
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.10 $ $Date: 2011-11-26 09:16:10 $

=cut
