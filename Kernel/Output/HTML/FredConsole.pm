# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FredConsole;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

use Cwd;

=head1 NAME

Kernel::Output::HTML::FredConsole - layout backend module

=head1 SYNOPSIS

All layout functions of console object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredConsole->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject LogObject LayoutObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item CreateFredOutput()

create the output of the STDERR log

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    # create the console table
    my $Console = 'Activated modules: <strong>'
        . ( join ' - ', @{ $Param{ModuleRef}->{Data} } )
        . '</strong>';

    return 1 if !$Param{ModuleRef}->{Status};

    if ( $Param{ModuleRef}->{Setting} ) {
        $Self->{LayoutObject}->Block(
            Name => 'Setting',
        );
    }

    # get config
    my $SystemName = $Self->{ConfigObject}->Get('Fred::SystemName')
        || $Self->{ConfigObject}->Get('Home');
    my $BackgroundColor = $Self->{ConfigObject}->Get('Fred::BackgroundColor')
        || 'red';
    my $BranchName = 'could not be detected';

    # Add current git branch to output
    my $Home = $Self->{ConfigObject}->Get('Home');
    if ( -d "$Home/.git" ) {
        my $OldWorkingDir = getcwd();
        chdir($Home);
        my $GitResult = `git branch`;
        chdir($OldWorkingDir);

        if ($GitResult) {
            ($BranchName) = $GitResult =~ m/^[*] \s+ (\S+)/xms;
        }
    }

    my $BranchClass;
    my $BugNumber;

    if ( $BranchName eq 'master' ) {
        $BranchClass = 'Warning';
    }
    elsif ( $BranchName =~ m{bug-((\d){1,6}).*} ) {
        $BugNumber = $1;
    }

    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredConsole',
        Data         => {
            Text            => $Console,
            ModPerl         => _ModPerl(),
            Perl            => sprintf( "%vd", $^V ),
            SystemName      => $SystemName,
            BranchName      => $BranchName,
            BranchClass     => $BranchClass,
            BackgroundColor => $BackgroundColor,
            BugNumber       => $BugNumber,
        },
    );

    return 1;
}

sub _ModPerl {

    # find out, if modperl is used
    my $ModPerl = 'not active';

    ## no critic
    if ( exists $ENV{MOD_PERL} && defined $mod_perl::VERSION ) {
        $ModPerl = $mod_perl::VERSION;
    }
    ## use critic

    return $ModPerl;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
