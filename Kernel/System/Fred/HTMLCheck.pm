# --
# Kernel/System/Fred/HTMLCheck.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: HTMLCheck.pm,v 1.1 2007-09-21 07:51:06 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred::HTMLCheck;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred::HTMLCheck

=head1 SYNOPSIS

handle the HTML:: lint check

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Log;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(ConfigObject LogObject MainObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }
    return $Self;
}

=item DataGet()

Get the data for this fred module. Returns true or false.
And add the data to the module ref.

    $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    for my $ParamRef (qw( ModuleRef HTMLDataRef )) {
        if ( !$Param{$ParamRef} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $ParamRef!",
            );
            return;
        }
    }

    # Check the HTML-Output with HTML::Lint
    my @HTMLLintMessages;
    if ($Self->{MainObject}->Require('HTML::Lint')) {
        HTML::Lint->import();
        my $HTMLLintObject = HTML::Lint->new( only_types => HTML::Lint::Error->STRUCTURE );
        $HTMLLintObject->parse (${ $Param{HTMLDataRef} });

        my $ErrorCounter = $HTMLLintObject->errors;
        for my $Error ($HTMLLintObject->errors) {
            my $String .= $Error->as_string;
            if ($String !~ /Invalid character .+ should be written as /) {
                push @HTMLLintMessages, $String;
            }
        }
    } else {
        my $Text = 'The HTML-checker of Fred requires HTML::Lint to be installed!'
            . 'Please install HTML::Lint via CPAN or deactivate the HTML-checker via SysConfig.';
        push @HTMLLintMessages, $Text;
    }

    if (@HTMLLintMessages) {
        ${ $Param{ModuleRef} }{Data} = \@HTMLLintMessages;
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

$Revision: 1.1 $ $Date: 2007-09-21 07:51:06 $

=cut