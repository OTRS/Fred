# --
# Kernel/Output/HTML/FredHTMLValidate.pm - layout backend module
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: FredHTMLValidate.pm,v 1.2 2009-10-30 08:27:10 mg Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredHTMLValidate;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

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

    if ( $Param{ModuleRef}->{OriginalData} ) {
        for my $Entry ( @{ $Param{ModuleRef}->{OriginalData} } ) {

            $Self->{LayoutObject}->Block(
                Name => 'OrigRow',
                Data => {
                    %{$Entry},
                },
            );
        }
    }

    if ( $Param{ModuleRef}->{ValidationData} ) {
        for my $Entry ( @{ $Param{ModuleRef}->{ValidationData} } ) {
            $Self->{LayoutObject}->Block(
                Name => 'ValidationRow',
                Data => $Entry,
            );
        }

        $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredHTMLValidate',
            Data         => {},
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
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.2 $ $Date: 2009-10-30 08:27:10 $

=cut
