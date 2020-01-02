# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::FredConsole;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

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

    $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredConsole',
        Data         => {
            Text    => $Console,
            ModPerl => _ModPerl(),
            Perl    => sprintf( "%vd", $^V ),
        },
    );

    return 1;
}

sub _ModPerl {

    # find out, if modperl is used
    my $ModPerl = 'is not activated';

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

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
