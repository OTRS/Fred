# --
# Kernel/System/Fred/SQLLog.pm
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: SQLLog.pm,v 1.25 2012-09-17 10:54:44 mg Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::SQLLog;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.25 $) [1];

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
    my $FredObject = Kernel::System::Fred::SQLLog->new(
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
            "Can't read /var/fred/SQL.log",
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
# SQL-SELECT##!##SELECT 1 + 1 FROM dual WHERE id = ? AND user_id = ?##!##1, 2##!##Kernel::System::User##!##0.004397
        my @SplitLogLine = split /##!##/, $Line;
        if ( $SplitLogLine[0] eq 'SQL-DO' && $SplitLogLine[1] =~ m{ \A SELECT }xms ) {
            $SplitLogLine[0] .= ' - Perhaps you have an error you use DO for a SELECT-Statement:';
        }
        push @LogMessages, \@SplitLogLine;

        if ( $SplitLogLine[0] eq 'SQL-DO' ) {
            $DoStatements++;
        }

        if ( $SplitLogLine[4] ) {
            $Param{ModuleRef}->{Time} += $SplitLogLine[4];
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

    # Fixup multiline SQL statements
    if ( $Param{What} =~ m/^SQL/smx ) {
        my @What = split '##!##', $Param{What};

        # hide white space
        $What[1] =~ s/\r?\n/ /smxg;
        $What[1] =~ s/\s+/ /smxg;
        $Param{What} = join '##!##', @What;
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
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.25 $ $Date: 2012-09-17 10:54:44 $

=cut
