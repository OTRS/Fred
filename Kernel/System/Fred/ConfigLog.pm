# --
# Kernel/System/Fred/ConfigLog.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: ConfigLog.pm,v 1.4 2007-09-28 06:58:23 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred::ConfigLog;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.4 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred::ConfigLog

=head1 SYNOPSIS

handle the config log data

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
        if ( $Param{$Object} ) {
            $Self->{$Object} = $Param{$Object};
        }
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
    my @LogMessages;

    # open the TranslationDebug.log file to get the untranslated words
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/Config.log';
    if ( open my $Filehandle, '<', $File ) {
        my @Row        = <$Filehandle>;
        my @ReverseRow = reverse(@Row);

        # get the whole information
        for my $Line (@ReverseRow) {
            if ( $Line =~ /FRED/ ) {
                last;
            }
            push @LogMessages, $Line;
        }
        close $Filehandle;
        pop @LogMessages;
        $Self->InsertWord( What => "FRED\n" );
    }

    my %IndividualConfig = ();

    for my $Line (@LogMessages) {
        $Line =~ s/\n//;
        $IndividualConfig{$Line}++;
    }

    @LogMessages = ();
    for my $Line (keys %IndividualConfig) {
        my @SplitedLine = split /;/, $Line;
        push @SplitedLine, $IndividualConfig{$Line};
        push @LogMessages, \@SplitedLine;
    }

    $Param{ModuleRef}->{Data} = \@LogMessages ;
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

    my $File = $Self->{ConfigObject}->Get('Home') . '/Kernel/Config/Defaults.pm';

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
    my $SubGet = '';
    for my $Line (@Lines) {
        print $FilehandleII $Line;
        if ( $Line =~ /sub Get/ ) {
            $SubGet = "Get";
        }
        if ( $SubGet eq 'Get' && $Line =~ /my \$Self = shift;/ ) {
            $SubGet .= 'Self';
        }
        if ( $SubGet eq 'GetSelf' && $Line =~ /my \$What = shift;/ ) {
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "use Kernel::System::Fred::ConfigLog;\n";
            print $FilehandleII "my \$ConfigLogObject = Kernel::System::Fred::ConfigLog->new();\n";
            print $FilehandleII "my \$Caller = caller();\n";
            print $FilehandleII "if (\$Self->{\$What}) { # FRED - manipulated\n";
            print $FilehandleII "    \$ConfigLogObject->InsertWord(What => \"\$What;True;\$Caller;\", Home => \$Self->{Home});\n";
            print $FilehandleII "}                     # FRED - manipulated\n";
            print $FilehandleII "else {                # FRED - manipulated\n";
            print $FilehandleII
                "    \$ConfigLogObject->InsertWord(What => \"\$What;False;\$Caller;\", Home => \$Self->{Home});\n";
            print $FilehandleII "}                     # FRED - manipulated\n";
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
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . '/Kernel/Config/Defaults.pm';

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
        "# FRED - manipulated\n"                                                                 => 1,
        "use Kernel::System::Fred::ConfigLog;\n"                                                 => 1,
        "my \$ConfigLogObject = Kernel::System::Fred::ConfigLog->new();\n"                       => 1,
        "my \$Caller = caller();\n"                                                              => 1,
        "if (\$Self->{\$What}) { # FRED - manipulated\n"                                         => 1,
        "    \$ConfigLogObject->InsertWord(What => \"\$What;True;\$Caller;\", Home => \$Self->{Home});\n"  => 1,
        "}                     # FRED - manipulated\n"                                           => 1,
        "else {                # FRED - manipulated\n"                                           => 1,
        "    \$ConfigLogObject->InsertWord(What => \"\$What;False;\$Caller;\", Home => \$Self->{Home});\n" => 1,
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

    if ( !$Param{Home} ) {
        $Param{Home} = $Self->{ConfigObject}->Get('Home');
    }

    # save the word in log file
    my $File = $Param{Home} . '/var/fred/Config.log';
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

$Revision: 1.4 $ $Date: 2007-09-28 06:58:23 $

=cut
