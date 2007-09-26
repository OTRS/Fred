# --
# Kernel/Output/HTML/FredConsole.pm - layout backend module
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: FredConsole.pm,v 1.3 2007-09-26 10:08:21 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::FredConsole;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.3 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::Output::HTML::FredConsole - layout backend module

=head1 SYNOPSIS

All layout functions of console object

=over 4

=cut

=item new()

create a object

    $BackendObject = Kernel::Output::HTML::FredConsole->new(
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
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    # create the console table
    my $Console = 'Activated modules: <b>' . ( join ' - ', @{ $Param{ModuleRef}->{Data} } ) . '</b>';

    if ( $Param{ModuleRef}->{Status} ) {
        if ( $Param{ModuleRef}->{Setting} ) {
            $Self->{LayoutObject}->Block(
                Name => 'Setting',
            );
        }
        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredConsole',
            Data         => {
                Text => $Console,
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

$Revision: 1.3 $ $Date: 2007-09-26 10:08:21 $

=cut