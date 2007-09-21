# --
# Kernel/Output/HTML/OutputFilterFred.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: OutputFilterFred.pm,v 1.6 2007-09-21 07:48:48 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::OutputFilterFred;

use strict;
use warnings;

use Kernel::System::Fred;

use vars qw($VERSION);
$VERSION = '$Revision: 1.6 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::Output::HTML::OutputFilterFred

=head1 SYNOPSIS

a output filter module specially for developer

=head1 PUBLIC INTERFACE

=over 4

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(MainObject ConfigObject LogObject )) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{FredObject} = Kernel::System::Fred->new( %{$Self} );

    if ( $Param{LayoutObject} ) {
        $Self->{LayoutObject} = $Param{LayoutObject};
    }
    else {

        # insert LayoutObject entry in FilterContent function of the Layout.pm
        # this happens only in OTRS 2.2
        $Self->{FredObject}->InsertLayoutObject();
    }

    return $Self;
}

sub Run {
    my $Self  = shift;
    my %Param = @_;
    my $OutputConsole;

    # is a check because OTRS2.2 don't deliver here a LayoutObject
    if ( !$Self->{LayoutObject} ) {
        return 1;
    }

    # do nothing if it is a redirect
    if (   ${ $Param{Data} } =~ /^Status: 302 Moved/mi
        && ${ $Param{Data} } =~ /^location:/mi
        && length( ${ $Param{Data} } ) < 800 )
    {
        return 1;
    }

    # get all activated modules
    my $ModuleForRef   = $Self->{ConfigObject}->Get('Fred::Module');
    my $ModulesDataRef = {};
    for my $Module ( keys %{$ModuleForRef} ) {
        if ( $ModuleForRef->{$Module}->{Active} ) {
            $ModulesDataRef->{$Module} = {};
        }
    }

    # create the console table
    my $Console = 'Activated modules: ';
    for my $Module ( keys %{$ModulesDataRef} ) {
        $Console .= $Module . " - ";
    }
    $Console =~ s/ - $//;
    if ( ${ $Param{Data} } !~ /Fred-Setting/ ) {
        if ( ${ $Param{Data} } !~ /name="Action" value="Login"/ ) {
            $Self->{LayoutObject}->Block(
                Name => 'Setting',
                Data => {                }
            );
        }
        $OutputConsole = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredConsole',
            Data         => {
                Text    => $Console,
            },
        );
    }

    # load the activated modules
    $Self->{FredObject}->DataGet(
        FredModulesRef => $ModulesDataRef,
        HTMLDataRef    => $Param{Data},
    );
    $Self->{LayoutObject}->CreateFredOutput( FredModulesRef => $ModulesDataRef );

    # build the content string
    my $Output = '';
    for my $Module ( %{$ModulesDataRef} ) {
        if ( $ModulesDataRef->{$Module}->{Output} ) {
            $Output .= $ModulesDataRef->{$Module}->{Output};
        }
    }

    # include the fred output in the original output
    if ( ${ $Param{Data} } =~ s/(\<body(|.+?)\>)/$1\n$OutputConsole$Output\n\n\n\n/mx ) {

        # ?
    }
    elsif ( ${ $Param{Data} } =~ s/^(.)/\n$Output\n\n\n\n$1/mx ) {

        # ?
    }

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This Software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.6 $ $Date: 2007-09-21 07:48:48 $

=cut