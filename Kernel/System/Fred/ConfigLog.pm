# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::ConfigLog;
## no critic(Perl::Critic::Policy::OTRS::ProhibitOpen)

use strict;
use warnings;

use Scalar::Util();

=head1 NAME

Kernel::System::Fred::ConfigLog

=head1 SYNOPSIS

handle the config log data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::ConfigLog;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $FredObject = Kernel::System::Fred::ConfigLog->new(
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
    for my $Object (qw(ConfigObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    # ConfigObject holds a reference to us, so don't reference it to avoid
    #   a ring reference.
    Scalar::Util::weaken( $Self->{ConfigObject} );

    # Don't call ConfigObject->Get() here, this could cause deep recursions.

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

    my @LogMessages;

    # open the TranslationDebug.log file to get the untranslated words
    my $File = $Self->{ConfigObject}->Get('Home') . '/var/fred/Config.log';
    my $Filehandle;
    if ( !open $Filehandle, '<', $File ) {
        print STDERR "Perhaps you don't have permission at /var/fred/\n" .
            "Can't read /var/fred/Config.log";
        return;
    }

    # get the whole information
    LINE:
    for my $Line ( reverse <$Filehandle> ) {
        last LINE if $Line =~ /FRED/;
        push @LogMessages, $Line;
    }

    close $Filehandle;
    pop @LogMessages;
    $Self->InsertWord( What => "FRED\n" );

    my %IndividualConfig = ();

    for my $Line (@LogMessages) {
        $Line =~ s/\n//;
        $IndividualConfig{$Line}++;
    }

    @LogMessages = ();
    for my $Line ( sort keys %IndividualConfig ) {
        my @SplitedLine = split /;/, $Line;
        push @SplitedLine, $IndividualConfig{$Line};
        push @LogMessages, \@SplitedLine;
    }

    # sort the data
    my $Config = $Self->{ConfigObject}->Get('Fred::ConfigLog');
    my $OrderBy = defined( $Config->{OrderBy} ) ? $Config->{OrderBy} : 3;
    if ( $OrderBy == 3 ) {
        @LogMessages = sort { $b->[$OrderBy] <=> $a->[$OrderBy] } @LogMessages;
    }
    else {
        @LogMessages = sort { $a->[$OrderBy] cmp $b->[$OrderBy] } @LogMessages;
    }

    $Param{ModuleRef}->{Data} = \@LogMessages;
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

    my $FredSettings = $Self->{ConfigObject}->GetOriginal('Fred::Module');

    if ( !$FredSettings || !$FredSettings->{ConfigLog} || !$FredSettings->{ConfigLog}->{Active} ) {
        return;
    }

    if ( !$Param{Home} ) {
        $Param{Home} = $Self->{ConfigObject}->GetOriginal('Home');
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

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
