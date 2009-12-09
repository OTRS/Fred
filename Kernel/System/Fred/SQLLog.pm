# --
# Kernel/System/Fred/SQLLog.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: SQLLog.pm,v 1.16 2009-12-09 08:42:08 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::SQLLog;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.16 $) [1];

=head1 NAME

Kernel::System::Fred::SQLLog

=head1 SYNOPSIS

Show a log of the SQL statements executed since the last view of the log.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::SQLLog;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $SQLLogObject = Kernel::System::Fred::SQLLog->new(
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

    # open the file SQL.log
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/SQL.log';
    my $Filehandle;
    if ( !open $Filehandle, '<', $File ) {
        $Param{ModuleRef}->{Data} = [
            "Perhaps you don't have permission at /var/fred/",
            "Can't read /var/fred/SQL.log"
        ];
        return;
    }

    my @LogMessages;
    my $DoStatements     = 0;
    my $SelectStatements = 0;

    # slurp in the whole logfile, in order to access the lines at the end
    LINE:
    for my $Line ( reverse <$Filehandle> ) {

        # do not show the log from the previous request
        last LINE if $Line =~ /FRED/;

        # a typical line from SQL.log looks like:
        # SQL-SELECT;SELECT 1 + 1 FROM dual;Kernel::System::User;0.004397
        my @SplitLogLine = split /;/, $Line;
        if ( $SplitLogLine[0] eq 'SQL-DO' && $SplitLogLine[1] =~ /^SELECT/ ) {
            $SplitLogLine[0] .= ' - Perhaps you have an error you use DO for a SELECT-Statement:';
        }
        push @LogMessages, \@SplitLogLine;

        if ( $SplitLogLine[0] eq 'SQL-DO' ) {
            $DoStatements++;
        }

        # transfer in 1/100 sec
        if ( $SplitLogLine[3] ) {
            $Param{ModuleRef}->{Time} += $SplitLogLine[3];
            $SplitLogLine[3] *= 100;
        }
    }

    pop @LogMessages;
    close $Filehandle;

    # find SQL-statements used multiple times
    my %MultiUsed;
    for my $StatementRef (@LogMessages) {
        $MultiUsed{ $StatementRef->[1] }++;
    }
    for my $StatementRef (@LogMessages) {
        push @{$StatementRef}, ( $MultiUsed{ $StatementRef->[1] } - 1 );
    }

    # Add marker for the next view
    $Self->InsertWord( What => "FRED\n" );

    # set the data for the output template
    $Param{ModuleRef}->{Data}             = \@LogMessages;
    $Param{ModuleRef}->{AllStatements}    = scalar @LogMessages;
    $Param{ModuleRef}->{DoStatements}     = $DoStatements;
    $Param{ModuleRef}->{SelectStatements} = $Param{ModuleRef}->{AllStatements} - $DoStatements;

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

    my $File = $Self->{ConfigObject}->Get('Home') . '/Kernel/System/DB.pm';

    # check if it is an symlink, because it can be development system which use symlinks
    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # to use SQLLog I have to manipulate the DB.pm file
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    $Self->{LogObject}->Log( Priority => 'notice', Message => "write file!" );
    my $Prepare;
    my $DoSQL;
    for my $Line (@Lines) {
        if (
            $Line =~ m[^                               \s*
                        if                              \s*
                        \(                              \s*
                        !                               \s*
                        \(                              \s*
                        \$Self->{Curs(e|o)r}            \s* # because of an typo bugfix in 2.3
                        =                               \s*
                        \$Self->{dbh}->prepare\(\$SQL\) \s*
                        \)                              \s*
                        \)                              \s*
                        {
            ]x
            )
        {
            $Self->{LogObject}->Log( Priority => 'notice', Message => "insert fred log Prepare!" );
            $Prepare = 1;
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "use Kernel::System::Fred::SQLLog;\n";
            print $FilehandleII "use Time::HiRes qw(gettimeofday tv_interval);\n";
            print $FilehandleII "my \$t0 = [gettimeofday];\n";
            print $FilehandleII
                "my \$SQLLogObject = Kernel::System::Fred::SQLLog->new(\%{\$Self});\n";
            print $FilehandleII "my \$Caller = caller();\n";
            print $FilehandleII "# FRED - manipulated\n";

        }
        if ( $Line =~ m{^    # slow log feature} && $Prepare ) {
            $Prepare = 0;
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "my \$DiffTime = tv_interval(\$t0);\n";
            print $FilehandleII
                "\$SQLLogObject->InsertWord(What => \"SQL-SELECT;\$SQL;\$Caller;\$DiffTime\");\n";
            print $FilehandleII "# FRED - manipulated\n";
        }

        if ( $Line =~ /^    # send sql to database/ ) {
            $Self->{LogObject}->Log( Priority => 'notice', Message => "insert fred log do!" );
            $DoSQL = 1;
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "use Kernel::System::Fred::SQLLog;\n";
            print $FilehandleII "use Time::HiRes qw(gettimeofday tv_interval);\n";
            print $FilehandleII "my \$t0 = [gettimeofday];\n";
            print $FilehandleII
                "my \$SQLLogObject = Kernel::System::Fred::SQLLog->new(\%{\$Self});\n";
            print $FilehandleII "my \$Caller = caller();\n";
            print $FilehandleII "# FRED - manipulated\n";
        }

        if ( $Line =~ m{^    return 1;} && $DoSQL ) {
            $DoSQL = 0;
            print $FilehandleII "# FRED - manipulated\n";
            print $FilehandleII "my \$DiffTime = tv_interval(\$t0);\n";
            print $FilehandleII
                "\$SQLLogObject->InsertWord(What => \"SQL-DO;\$Param{SQL};\$Caller;\$DiffTime\");\n";
            print $FilehandleII "# FRED - manipulated\n";
        }

        print $FilehandleII $Line;
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

    my $File = $Self->{ConfigObject}->Get('Home') . '/Kernel/System/DB.pm';

    # check if it is an symlink, because it can be development system which use symlinks
    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # to use SQLLog I had to manipulate the DB.pm file
    # here I undo my manipulation
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";

    my %RemoveLine = (
        "# FRED - manipulated\n"                                                              => 1,
        "use Kernel::System::Fred::SQLLog;\n"                                                 => 1,
        "my \$SQLLogObject = Kernel::System::Fred::SQLLog->new(\%{\$Self});\n"                => 1,
        "my \$Caller = caller();\n"                                                           => 1,
        "\$SQLLogObject->InsertWord(What => \"SQL-DO;\$Param{SQL};\$Caller\;\$DiffTime\");\n" => 1,
        "\$SQLLogObject->InsertWord(What => \"SQL-SELECT;\$SQL;\$Caller\;\$DiffTime\");\n"    => 1,
        "use Time::HiRes qw(gettimeofday tv_interval);\n"                                     => 1,
        "my \$t0 = [gettimeofday];\n"                                                         => 1,
        "my \$DiffTime = tv_interval(\$t0);\n"                                                => 1,
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

Append a semicolon seperated record line to the the SQL log.

    $BackendObject->InsertWord(
        What => 'SQL-SELECT;SELECT 1 + 1 FROM dual;Kernel::System::User;0.004397',
    );

=cut

sub InsertWord {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{What} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need What!',
        );
        return;
    }

    # apppend the line to log file
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/SQL.log';
    open my $Filehandle, '>>', $File or die "Can't write $File !\n";
    print $Filehandle $Param{What}, "\n";
    close $Filehandle;

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

$Revision: 1.16 $ $Date: 2009-12-09 08:42:08 $

=cut
