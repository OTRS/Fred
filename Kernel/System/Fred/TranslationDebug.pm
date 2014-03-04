# --
# Kernel/System/Fred/TranslationDebug.pm
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::TranslationDebug;
## no critic(Perl::Critic::Policy::OTRS::ProhibitOpen)

use strict;
use warnings;

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

    if ( ref $Self->{ConfigObject}->Get('Fred::Module') && $Self->{ConfigObject}->Get('Fred::Module')->{TranslationDebug}) {
        $Self->{Active} = $Self->{ConfigObject}->Get('Fred::Module')->{TranslationDebug}->{Active};
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

=item InsertWord()

Save a word in the translation debug log

    $BackendObject->InsertWord(
        What => 'a word',
    );

=cut

sub InsertWord {
    my ( $Self, %Param ) = @_;

    return if ( !$Self->{Active} );

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
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
