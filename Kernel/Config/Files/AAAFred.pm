# --
# AAAFred.pm - the config to bind STDERR to an log file usable for fred
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use vars qw($Self);

use Kernel::Language;
use Kernel::System::Fred::TranslationDebug;

if ( $ENV{HTTP_USER_AGENT} ) {

    # check if the needed path is available
    my $Path = $Self->{Home} . '/var/fred';
    if ( !-e $Path ) {
        mkdir $Path;
    }

    my $File = $Self->{Home} . '/var/fred/STDERR.log';

    # check log file size
    if ( -s $File > 20 * 1024 * 1024 ) {
        unlink $File;
    }

    # move STDOUT to tmp file
    if ( !open STDERR, '>>', $File ) { ## no critic
        print STDERR "ERROR: Can't write $File!";
    }
}

# disable redefine warnings in this scope
{
    no warnings 'redefine';

    # Override Kernel::Language::Get() method to intercept missing translations
    if ( Kernel::Language->can('Get') && !Kernel::Language->can('GetOriginal') ) {
        *Kernel::Language::GetOriginal = \&Kernel::Language::Get;
        *Kernel::Language::Get = sub {
            my ($Self, $What) = @_;

            return if !defined $What;
            return '' if $What eq '';

            my $Result = $Self->GetOriginal($What);

            if ( $What && $What =~ /^(.+?)",\s{0,1}"(.*?)$/ ) {
                $What = $1;
            }

            if (!$Self->{Translation}->{$What}) {
                $Self->{TranslationDebugObject} //= Kernel::System::Fred::TranslationDebug->new(%{$Self});
                $Self->{TranslationDebugObject}->InsertWord(What => $What);
            }

            return $Result;
        };
    }

    # Override Kernel::Language::Translate() method to intercept missing translations
    if ( Kernel::Language->can('Translate') && !Kernel::Language->can('TranslateOriginal') ) {
        *Kernel::Language::TranslateOriginal = \&Kernel::Language::Translate;
        *Kernel::Language::Translate = sub {
            my ( $Self, $Text, @Parameters ) = @_;

            if ($Text && !$Self->{Translation}->{$Text}) {
                $Self->{TranslationDebugObject} //= Kernel::System::Fred::TranslationDebug->new(%{$Self});
                $Self->{TranslationDebugObject}->InsertWord(What => $Text);
            }

            return $Self->TranslateOriginal($Text, @Parameters);
        };
    }
}

1;
