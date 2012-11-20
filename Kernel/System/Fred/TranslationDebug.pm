# --
# Kernel/System/Fred/TranslationDebug.pm
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: TranslationDebug.pm,v 1.16 2012-11-20 19:00:27 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::TranslationDebug;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.16 $) [1];

=head1 NAME

Kernel::System::Fred::TranslationDebug

=head1 SYNOPSIS

handle the translation debug data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::TranslationDebug;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $FredObject = Kernel::System::Fred::TranslationDebug->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

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
    my ( $Self, %Param ) = @_;

    # open the TranslationDebug.log file to get the untranslated words
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/TranslationDebug.log';
    my $Filehandle;
    if ( !open $Filehandle, '<', $File ) {
        $Param{ModuleRef}->{Data} = [
            "Perhaps you don't have permission at /var/fred/",
            "Can't read /var/fred/TranslationDebug.log"
        ];
        return;
    }
    my @LogMessages;

    # get the whole information
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ /FRED/;

        chomp $Line;
        next LINE if $Line eq '';

        push @LogMessages, $Line;
    }
    close $Filehandle;

    $Self->InsertWord( What => "FRED\n" );

    $Param{ModuleRef}->{Data} = \@LogMessages;

    return 1;
}

=item ActivateModuleTodos()

Do all jobs which are necessary to activate this special module.

    $FredObject->ActivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub ActivateModuleTodos {
    my $Self = shift;

    my $File = $Self->{ConfigObject}->Get('Home') . '/Kernel/Language.pm';

    # check if it is an symlink, because it can be development system which use symlinks
    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # to use TranslationDebug I have to manipulate the Language.pm file
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
        if ( $Line =~ /# warn if the value is not def/ ) {
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "use Kernel::System::Fred::TranslationDebug;\n";
            print $FilehandleII
                "my \$TranslationDebugObject = Kernel::System::Fred::TranslationDebug->new(\%{\$Self});\n";
            print $FilehandleII "\$TranslationDebugObject->InsertWord(What => \$What);\n";
            print $FilehandleII "# FRED - manipulated\n";
        }
    }
    close $FilehandleII;

    return 1;
}

=item DeactivateModuleTodos()

Do all jobs which are necessary to deactivate this special module.

    $FredObject->DeactivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub DeactivateModuleTodos {
    my $Self = shift;

    my $File = $Self->{ConfigObject}->Get('Home') . '/Kernel/Language.pm';

    # check if it is an symlink, because it can be development system which use symlinks
    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # to use TranslationDebugger I have to manipulate the Language.pm file
    # here I undo my manipulation
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";

    my %RemoveLine = (
        "# FRED - manipulated\n"                        => 1,
        "use Kernel::System::Fred::TranslationDebug;\n" => 1,
        "my \$TranslationDebugObject = Kernel::System::Fred::TranslationDebug->new(\%{\$Self});\n"
            => 1,
        "\$TranslationDebugObject->InsertWord(What => \$What);\n" => 1,
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
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !defined( $Param{What} ) ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need What!',
        );
        return;
    }

    # save the word in log file
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/TranslationDebug.log';
    open my $Filehandle, '>>', $File or die "Can't write $File !\n";
    print $Filehandle $Param{What} . "\n";
    close $Filehandle;

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.16 $ $Date: 2012-11-20 19:00:27 $

=cut
