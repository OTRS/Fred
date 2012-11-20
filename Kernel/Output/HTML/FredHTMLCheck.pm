# --
# Kernel/Output/HTML/FredHTMLCheck.pm - layout backend module
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: FredHTMLCheck.pm,v 1.7 2012-11-20 18:59:34 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredHTMLCheck;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.7 $) [1];

=head1 NAME

Kernel::Output::HTML::FredHTMLCheck - layout backend module

=head1 SYNOPSIS

All layout functions of HTML check object

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

    my $HTMLLines = '';

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    my $FrameworkVersion = $Self->{ConfigObject}->Get('Version');
    if ( $FrameworkVersion =~ /^2\.(0|1|2|3|4)\./ ) {
        $Self->{LayoutObject}->Block(
            Name => 'HTMLCheckNotAllowed',
            Data => {},
        );
    }
    else {
        $Self->{LayoutObject}->Block(
            Name => 'HTMLCheckAllowed',
            Data => {},
        );
    }

    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredHTMLCheck',
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
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.7 $ $Date: 2012-11-20 18:59:34 $

=cut
