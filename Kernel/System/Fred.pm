# --
# Kernel/System/Fred.pm - all fred core functions
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: Fred.pm,v 1.7 2007-10-22 14:15:52 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = '$Revision: 1.7 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred - fred core lib

=head1 SYNOPSIS

All fred standard core functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Log;
    use Kernel::System::DB;
    use Kernel::System::Main;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );
    my $MainObject = Kernel::System::Main->new(
        LogObject => $LogObject,
        ConfigObject => $ConfigObject,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject LogObject MainObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item DataGet()

Evaluate the several data of all fred modules and add them
on the FredModules reference.

    $FredObject->DataGet(
        FredModulesRef => $FredModulesRef,
    );

=cut

sub DataGet {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{FredModulesRef} || ref( $Param{FredModulesRef} ) ne 'HASH' ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need FredModulesRef!',
        );
        return;
    }
    if ( !$Param{HTMLDataRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need HTMLDataRef!',
        );
        return;
    }

    for my $ModuleName ( keys %{ $Param{FredModulesRef} } ) {

        # load backend
        my $BackendObject = $Self->_LoadBackend( ModuleName => $ModuleName );

        # get module data
        if ($BackendObject) {
            $BackendObject->DataGet(
                ModuleRef      => $Param{FredModulesRef}->{$ModuleName},
                HTMLDataRef    => $Param{HTMLDataRef},
                FredModulesRef => $Param{FredModulesRef},
            );
        }
    }

    return 1;
}

=item ActivateModuleTodos()

Do all jobs which are necessary to activate a fred module.

    $FredObject->ActivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub ActivateModuleTodos {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{ModuleName} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleName!',
        );
        return;
    }

    # load backend
    my $BackendObject = $Self->_LoadBackend( ModuleName => $Param{ModuleName} );

    # get module data
    if ($BackendObject) {

        # FIXME Errorhandling
        $BackendObject->ActivateModuleTodos();

        return 1;
    }

    return;
}

=item DeactivateModuleTodos()

Do all jobs which are necessary to deactivate a fred module.

    $FredObject->DeactivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub DeactivateModuleTodos {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{ModuleName} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleName!',
        );
        return;
    }

    # load backend
    my $BackendObject = $Self->_LoadBackend( ModuleName => $Param{ModuleName} );

    # get module data
    if ($BackendObject) {

        # FIXME Errorhandling
        $BackendObject->DeactivateModuleTodos();

        return 1;
    }

    return;
}

=item _LoadBackend()

load a xml item module

    $BackendObject = $FredObject->_LoadBackend(
        ModuleName => $ModuleName,
    );

=cut

sub _LoadBackend {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{ModuleName} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleName!',
        );
        return;
    }

    # load backend
    my $GenericModule = 'Kernel::System::Fred::' . $Param{ModuleName};
    if ( $Self->{MainObject}->Require($GenericModule) ) {
        my $BackendObject = $GenericModule->new( %{$Self}, %Param, );

        if ($BackendObject) {
            # return object
            return $BackendObject;
        }
    }

    return;
}

=item InsertLayoutObject22()

FRAMEWORK-2.2 specific because there is no LayoutObject integration for
FRED in OTRS2.2 Layout.pm

    $FredObject->InsertLayoutObject22();

=cut

sub InsertLayoutObject22 {
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . '/Kernel/Output/HTML/Layout.pm';

    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # read file
    my $InSub;
    open my $Filehandle, '<', $File || die "Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
        if ( $Line =~ /sub Print {/ ) {
            $InSub = 1;
        }
        if ( $InSub && $Line =~ /Debug => \$Self->{Debug},/ ) {
            push @Lines, "# FRED - manipulated\n";
            push @Lines, "                    LayoutObject => \$Self,\n";
            push @Lines, "# FRED - manipulated\n";
            $InSub = 0;
        }
    }
    close $Filehandle;

    # write file
    open my $FilehandleII, '>', $File || die "Can't write $File !\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
    close $FilehandleII;

    # log the manipulation
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the $File!",
    );
    return 1;
}

=item InsertLayoutObject21()

FRAMEWORK-2.1 specific because there is no LayoutObject integration for
FRED in OTRS2.1 InterfaceAgent.pm

    $FredObject->InsertLayoutObject21();

=cut

sub InsertLayoutObject21 {
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . '/Kernel/System/Web/InterfaceAgent.pm';
    my $FileChanged = 0;

    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # read file
    open my $Filehandle, '<', $File || die "Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        if ( $Line =~ /^\s*print \$GenericObject->Run\(\);/ ) {
            my $Manipulated =<<'            END_MANIPULATED';
            # FRED - manipulated
            my $OutputRef = \$GenericObject->Run();

            if ( $Self->{MainObject}->Require( 'Kernel::Output::HTML::OutputFilterFred' ) ) {
                $Self->{LayoutObject} = Kernel::Output::HTML::Layout->new(
                    %{$Self},
                    %Param,
                );

                my $Object = Kernel::Output::HTML::OutputFilterFred->new(
                    ConfigObject => $Self->{ConfigObject},
                    MainObject   => $Self->{MainObject},
                    LogObject    => $Self->{LogObject},
                    Debug        => $Self->{Debug},
                    LayoutObject => $Self->{LayoutObject},
                );

                # run module
                $Object->Run( %{ $Self }, Data => $OutputRef );

            }
            print ${$OutputRef};
            #print $GenericObject->Run();
            # FRED - manipulated
            END_MANIPULATED
            push @Lines, $Manipulated;
            $FileChanged = 1;
            next;
        }
        push @Lines, $Line;
    }
    close $Filehandle;

    # write file
    open my $FilehandleII, '>', $File || die "Can't write $File !\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
    close $FilehandleII;

    # log the manipulation
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the $File!",
    );
    return $FileChanged;
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

$Revision: 1.7 $ $Date: 2007-10-22 14:15:52 $

=cut