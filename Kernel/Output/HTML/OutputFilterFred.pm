# --
# Kernel/Output/HTML/OutputFilterFred.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: OutputFilterFred.pm,v 1.19 2009-04-21 10:28:13 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterFred;

use strict;
use warnings;

use Kernel::System::Fred;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.19 $) [1];

=head1 NAME

Kernel::Output::HTML::OutputFilterFred

=head1 SYNOPSIS

a output filter module specially for developer

=head1 PUBLIC INTERFACE

=over 4

=cut

sub new {
    my ( $Type, %Param ) = @_;

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
        $Self->{FredObject}->InsertLayoutObject22();
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # is a check because OTRS2.2 don't deliver here a LayoutObject
    if ( !$Self->{LayoutObject} ) {
        return 1;
    }

    # perhaps no output is generated
    if ( !$Param{Data} ) {
        die 'Fred: At the moment, your code generates no output!';
    }

    # do nothing if output is a attachment
    if (
        ${ $Param{Data} }    =~ /^Content-Disposition: attachment;/mi
        || ${ $Param{Data} } =~ /^Content-Disposition: inline;/mi
        )
    {
        print STDERR "ATTACHMENT DOWNLOAD\n";
        return 1;
    }

    # do nothing if it is a redirect
    if (
        ${ $Param{Data} }    =~ /^Status: 302 Moved/mi
        && ${ $Param{Data} } =~ /^location:/mi
        && length( ${ $Param{Data} } ) < 800
        )
    {
        print STDERR "REDIRECT\n";
        return 1;
    }

    # do nothing if it is fred it self
    if ( ${ $Param{Data} } =~ m{Fred-Setting<\/title>}msx ) {
        print STDERR "CHANGE FRED SETTING\n";
        return 1;
    }

    # get data of the activated modules
    my $ModuleForRef   = $Self->{ConfigObject}->Get('Fred::Module');
    my $ModulesDataRef = {};
    for my $Module ( keys %{$ModuleForRef} ) {
        if ( $ModuleForRef->{$Module}->{Active} ) {
            $ModulesDataRef->{$Module} = {};
        }
    }

    # load the activated modules
    $Self->{FredObject}->DataGet(
        FredModulesRef => $ModulesDataRef,
        HTMLDataRef    => $Param{Data},
    );

    # create freds output
    $Self->{LayoutObject}->CreateFredOutput( FredModulesRef => $ModulesDataRef );

    # build the content string
    my $Output = '';
    if ( $ModulesDataRef->{Console}->{Output} ) {
        $Output .= $ModulesDataRef->{Console}->{Output};
        delete $ModulesDataRef->{Console};
    }
    for my $Module ( keys %{$ModulesDataRef} ) {
        $Output .= $ModulesDataRef->{$Module}->{Output} || '';
    }

    # include the fred output in the original output
    if ( ${ $Param{Data} } !~ s/(\<body(|.+?)\>)/$1\n$Output\n\n\n\n/mx ) {
        ${ $Param{Data} } =~ s/^(.)/\n$Output\n\n\n\n$1/mx;
    }

    return 1;
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

$Revision: 1.19 $ $Date: 2009-04-21 10:28:13 $

=cut
