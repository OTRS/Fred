# --
# Kernel/Output/HTML/FredSTDERRLog.pm - layout backend module
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: FredSTDERRLog.pm,v 1.1 2007-09-21 08:09:09 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::FredSTDERRLog;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::Output::HTML::FredSTDERRLog - layout backend module

=head1 SYNOPSIS

All layout functions of STDERR log objects

=over 4

=cut

=item new()

create a object

    $BackendObject = Kernel::Output::HTML::FredSTDERRLog->new(
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

create the output of the STDERR log

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
            Message  => "Need ModuleRef!",
        );
        return;
    }

    for my $Line ( reverse @{ ${ $Param{ModuleRef} }{Data} } ) {
        $HTMLLines .= "        <tr><td>$Line</td></tr>";
    }

    if ($HTMLLines) {
        ${ $Param{ModuleRef} }{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredSTDERRLog',
            Data         => { HTMLLines => $HTMLLines, },
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

$Revision: 1.1 $ $Date: 2007-09-21 08:09:09 $

=cut
