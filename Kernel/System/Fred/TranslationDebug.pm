# --
# Kernel/System/Fred/TranslationDebug.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: TranslationDebug.pm,v 1.3 2007-09-26 09:33:07 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred::TranslationDebug;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.3 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred::TranslationDebug

=head1 SYNOPSIS

handle the translation debug data

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

    # open the TranslationDebug.log file to get the untranslated words
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/TranslationDebug.log';
    if ( open my $Filehandle, '<', $File ) {
        my @Row        = <$Filehandle>;
        my @ReverseRow = reverse @Row;
        my @LogMessages;

        # get the whole information
        for my $Line (@ReverseRow) {
            if ( $Line =~ /FRED/ ) {
                last;
            }
            push @LogMessages, $Line;
        }
        close $Filehandle;

        $Self->InsertWord(What => "FRED\n");
        $Param{ModuleRef}->{Data} = \@LogMessages;
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
    my $Self  = shift;
    my @Lines = ();

    my $File  = $Self->{ConfigObject}->Get('Home') . '/Kernel/Language.pm';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l "$File" ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # to use TranslationDebug I have to manipulate the Language.pm file
    open my $Filehandle, '<', $File || die "Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
    }
    close $Filehandle;

    open my $FilehandleII, '>', $File || die "Can't write $File !\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
        if ( $Line =~ /# warn if the value is not def/ ) {
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "use Kernel::System::Fred::TranslationDebug;\n";
            print $FilehandleII "my \$TranslationDebugObject = Kernel::System::Fred::TranslationDebug->new(\%{\$Self});\n";
            print $FilehandleII "\$TranslationDebugObject->InsertWord(What => \$What);\n";
            print $FilehandleII "# FRED - manipulated\n";
        }
    }
    close $FilehandleII;

    # check if the needed path is available
    my $Path = $Self->{ConfigObject}->Get('Home') . '/var/fred';
    if (!-e $Path) {
        mkdir $Path;
    }

    return 1;
}

=item DeactivateModuleTodos()

Do all jobs which are necessary to deactivate this special module.

    $FredObject->DeactivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub DeactivateModuleTodos {
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . '/Kernel/Language.pm';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l "$File" ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # to use TranslationDebugger I have to manipulate the Language.pm file
    # here I undo my manipulation
    open my $Filehandle, '<', $File || die "Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
    }
    close $Filehandle;

    open my $FilehandleII, '>', $File || die "Can't write $File !\n";

    my %RemoveLine = (
        "# FRED - manipulated\n"                                                                   => 1,
        "use Kernel::System::Fred::TranslationDebug;\n"                                            => 1,
        "my \$TranslationDebugObject = Kernel::System::Fred::TranslationDebug->new(\%{\$Self});\n" => 1,
        "\$TranslationDebugObject->InsertWord(What => \$What);\n"                                  => 1,
    );

    for my $Line (@Lines) {
        if ( !$RemoveLine{$Line} ) {
            print $FilehandleII $Line;
        }
    }
    close $FilehandleII;
    return 1;
}

=item InsertWord()

Save a word in the translation debug log

    $BackendObject->InsertWord(
        What => 'a word',
    );

=cut

sub InsertWord {
    my $Self  = shift;
    my %Param = @_;

    # check needed stuff
    if ( !$Param{What} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need What!',
        );
        return;
    }

    # save the word in log file
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/TranslationDebug.log';
    open my $Filehandle, '>>', $File || die "Can't write $File !\n";
    print $Filehandle $Param{What} . "\n";
    close $Filehandle;

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

$Revision: 1.3 $ $Date: 2007-09-26 09:33:07 $

=cut