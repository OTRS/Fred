# --
# Kernel/System/Fred/HTMLValidate.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: HTMLValidate.pm,v 1.1 2009-10-21 18:40:37 mg Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::HTMLValidate;

use strict;
use warnings;

use File::Temp;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1 $) [1];

=head1 NAME

Kernel::System::Fred::HTMLValidate

=head1 SYNOPSIS

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::Fred::HTMLCheck;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $SmallProfObject = Kernel::System::Fred::HTMLCheck->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

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
    my ( $Self, %Param ) = @_;

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

    my $Content = ${ $Param{HTMLDataRef} };

    # cut out HTTP headers
    $Content =~ s/^[^<]+//smx;

    my $Tmp = File::Temp->new( UNLINK => 1, SUFFIX => '.html' );
    print $Tmp $Content;
    close($Tmp);

    my $Result = `/usr/bin/validate --emacs $Tmp`;

    my @ResultLines = split( /\n/, $Result );

    my %Types = (
        E => 'Error',
        W => 'Warning',
    );

    my %ErrorLines;
    my %WarningLines;

    LINE:
    for my $Line (@ResultLines) {
        my ( $LineNumber, $CharNumber, $Type, $Message )
            = $Line =~ m/[^:]+:(\d+):(\d+):([EW]?):?(.*)/;
        next LINE unless $Message;

        $ErrorLines{$LineNumber}   = 1 if ( $Type == 'E' );
        $WarningLines{$LineNumber} = 1 if ( $Type == 'W' );

        # map Type to readable value
        $Type = $Types{$Type};

        push(
            @{ $Param{ModuleRef}->{ValidationData} },
            {
                LineNumber => $LineNumber,
                CharNumber => $CharNumber,
                Type       => $Type,
                Message    => $Message,
            }
        );
    }

    my $Counter = 1;
    for my $OrigLine ( split( /\n/, $Content ) ) {
        my $Style = '';
        if ( $ErrorLines{$Counter} ) {
            $Style = 'background-color: #F4BBAD;'
        }
        elsif ( $WarningLines{$Counter} ) {
            $Style = 'background-color: #FFF4C0;'
        }
        push(
            @{ $Param{ModuleRef}->{OriginalData} },
            {
                LineContent => $OrigLine,
                LineNumber  => $Counter++,
                Style       => $Style,
            }
        );
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
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.1 $ $Date: 2009-10-21 18:40:37 $

=cut
