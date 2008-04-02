# --
# Kernel/System/Fred/Console.pm
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: Console.pm,v 1.5 2008-04-02 04:54:06 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

package Kernel::System::Fred::Console;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.5 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred::SmallProf

=head1 SYNOPSIS

gives you all functions which are needed for the console

=over 4

=cut

=item new()

create an object

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
    for my $Object (qw(ConfigObject LogObject)) {
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
    for my $Ref (qw(ModuleRef HTMLDataRef FredModulesRef)) {
        if ( !$Param{$Ref} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Ref!",
            );
            return;
        }
    }

    my @Modules = ();
    for my $Module (keys %{$Param{FredModulesRef}}) {
        if ($Module ne 'Console') {
            push @Modules, $Module;
        }
    }
    $Param{ModuleRef}->{Data} = \@Modules;

    if (${$Param{HTMLDataRef}} !~ /Fred-Setting/ && ${$Param{HTMLDataRef}} =~ /\<body.*?\>/ ) {
        $Param{ModuleRef}->{Status} = 1;
    }

    if ( ${$Param{HTMLDataRef}} !~ /name="Action" value="Login"/ ) {
        $Param{ModuleRef}->{Setting} = 1;
    }

    return 1;
}

=item ActivateModuleTodos()

Do all jobs which are necessary to activate this special module.

    $FredObject->ActivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub ActivateModuleTodos {
    return 1;
}

=item DeactivateModuleTodos()

Do all jobs which are necessary to deactivate this special module.

    $FredObject->DeactivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub DeactivateModuleTodos {
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.

=cut

=head1 VERSION

$Revision: 1.5 $ $Date: 2008-04-02 04:54:06 $

=cut