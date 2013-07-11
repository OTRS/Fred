# --
# Kernel/System/Fred/NYTProf.pm
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::NYTProf;

use strict;
use warnings;

use Devel::NYTProf::Reader;

=head1 NAME

Kernel::System::Fred::NYTProf

=head1 SYNOPSIS

handle the NYTProf profiling data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::NYTProf;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $FredObject = Kernel::System::Fred::NYTProf->new(
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

    # check needed stuff
    for my $NeededRef (qw(HTMLDataRef ModuleRef)) {
        if ( !$Param{$NeededRef} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $NeededRef!",
            );
            return;
        }
    }

    # in these two cases it makes no sense to generate the profiling list
    if ( ${ $Param{HTMLDataRef} } !~ /\<body.*?\>/ ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'This page deliver the HTML by many separate output calls.'
                . ' Please use the usual way to interpret Devel::NYTProf',
        );
        return 1;
    }
    if ( ${ $Param{HTMLDataRef} } =~ m/Fred-Setting/ ) {
        return 1;
    }

    # get config for this plugin
    my $Config = $Self->{ConfigObject}->Get('Fred::NYTProf');

    # The profiling output from a running process can generally not be analyzed.
    # However we can tell NYTProf that we are done with profile and that the
    # output file should be closed properly.
    DB::finish_profile();

    # Generate HTML with 'nytprofhtml' and provide a link to the generated HTML.
    # The data from the previous request is deleted.
    my $HTMLOutputDir = $Self->{ConfigObject}->Get('Home') . '/var/httpd/htdocs/nytprof';
    my $GenHTMLCmd    = "$Config->{GenHTMLCmd} -out $HTMLOutputDir 2>&1";
    $Param{ModuleRef}->{GenHTMLCmd}    = $GenHTMLCmd;
    $Param{ModuleRef}->{GenHTMLOutput} = `$GenHTMLCmd`;

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

    # the file index.pl needs to be modified for turning on Devel::NYTProf
    my $File = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l $File ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # read the whole file
    open my $ReadFH, '<', $File or die "Can't open $File: $!";
    my ( $OldShebang, @Lines ) = <$ReadFH>;
    close $ReadFH;
    chomp $OldShebang;

    # add -d:NYTProf to the shebang and overwrite the file
    open my $WriteFH, '>', $File or die "Can't write $File: $!";
    if ( $OldShebang !~ m/-d:NYTProf/ ) {
        my $Now = localtime();
        print $WriteFH
            "$OldShebang -d:NYTProf\n",
            "# FRED - manipulated $Now\n",
    }
    print $WriteFH
        "$OldShebang\n",
        @Lines;
    close $WriteFH;

    # create a info for the user
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED added -d:NYTProf to the first line of '$File'",
    );

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

    # modification of index.pl is reverted
    my $File = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l $File ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # read the index.pl file
    open my $ReadFH, '<', $File or die "Can't open $File: $!";
    my @Lines = <$ReadFH>;
    close $ReadFH;

    # remove the manipulated lines
    if ( $Lines[0] =~ m{-d:NYTProf} ) {
        shift @Lines;
    }
    if ( $Lines[0] =~ m{^# FRED - manipulated} ) {
        shift @Lines;
    }

    # save the index.pl file
    open my $WriteFH, '>', $File or die "Can't write $File: $!";
    print $WriteFH @Lines;
    close $WriteFH;
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the file $File!",
    );

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

=cut
