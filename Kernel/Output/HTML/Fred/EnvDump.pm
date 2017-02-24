# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Fred::EnvDump;
## nofilter(TidyAll::Plugin::OTRS::Perl::Dumper)

use strict;
use warnings;

use Data::Dumper;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::Output::HTML::FredEnvDump - show dump of the environment ref, data for $Env in dtl

=head1 SYNOPSIS

All layout functions of the layout environment dump object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredEnvDump->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item CreateFredOutput()

Get the session data and create the output of the session dump

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # Kernel::System::Fred::EnvDump::DataGet() is not used,
    # as the data of interest is not easily available there.
    for my $Key ( sort keys %{ $LayoutObject->{EnvRef} } ) {

        $LayoutObject->Block(
            Name => 'EnvDataRow',
            Data => {
                Key   => $Key,
                Value => $LayoutObject->{EnvRef}->{$Key},
            },
        );
    }

    # output the html
    $Param{ModuleRef}->{Output} = $LayoutObject->Output(
        TemplateFile => 'DevelFredEnvDump',
    );

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
