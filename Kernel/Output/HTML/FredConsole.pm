# --
# Kernel/Output/HTML/FredConsole.pm - layout backend module
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: FredConsole.pm,v 1.8 2009-09-16 11:21:30 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredConsole;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.8 $) [1];

=head1 NAME

Kernel::Output::HTML::FredConsole - layout backend module

=head1 SYNOPSIS

All layout functions of console object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredConsole->new(
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

    # create the console table
    my $Console
        = 'Activated modules: <b>' . ( join ' - ', @{ $Param{ModuleRef}->{Data} } ) . '</b>';

    if ( $Param{ModuleRef}->{Status} ) {

        if ( $Param{ModuleRef}->{Setting} ) {
            $Self->{LayoutObject}->Block(
                Name => 'Setting',
            );
        }
        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredConsole',
            Data         => {
                Text    => $Console,
                ModPerl => _ModPerl(),
            },
        );
    }

    return 1;
}

sub _ModPerl {

    # find out, if modperl is used

    my $ModPerl = 'is not activated';
    if ( exists $ENV{MOD_PERL} && defined $mod_perl::VERSION ) {
        $ModPerl = $mod_perl::VERSION;
    }
    return $ModPerl;
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

$Revision: 1.8 $ $Date: 2009-09-16 11:21:30 $

=cut
