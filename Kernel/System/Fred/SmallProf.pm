# --
# Kernel/System/Fred/SmallProf.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: SmallProf.pm,v 1.18 2009-12-09 14:35:14 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::SmallProf;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.18 $) [1];

=head1 NAME

Kernel::System::Fred::SmallProf

=head1 SYNOPSIS

handle the SmallProf profiling data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Fred::SmallProf;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $FredObject = Kernel::System::Fred::SmallProf->new(
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

    # in this two cases it makes no sense to generate the profiling list
    if ( ${ $Param{HTMLDataRef} } !~ /\<body.*?\>/ ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'This page deliver the HTML by many separate output calls.'
                . ' Please use the usual way to interpret SmallProf',
        );
        return 1;
    }

    if ( ${ $Param{HTMLDataRef} } =~ m/Fred-Setting/ ) {
        return 1;
    }

    # find out which packages are checked by SmallProf
    my @Packages;
    {

    # avoid the warning:
    # Name "DB::packages" used only once: possible typo at Kernel/System/Fred/SmallProf.pm line 116.
        no warnings 'once';

        @Packages = keys %DB::packages;
    }
    if ( !$Packages[0] ) {
        $Packages[0] = 'all';
    }
    $Param{ModuleRef}->{Packages} = \@Packages;

    # catch the needed profiling data
    my $Path = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin';
    system "cp $Path/smallprof.out $Path/FredSmallProf.out";

    my $Config_Ref = $Self->{ConfigObject}->Get('Fred::DProf');
    my @ProfilingResults;

    if ( open my $Filehandle, '<', "$Path/FredSmallProf.out" ) {

        # convert the file in useable data
        while ( my $Line = <$Filehandle> ) {
            if ( $Line =~ /(.+?):(\d+?):(\d+?):(\d+?):(\d+?):\s*(.*?)$/ ) {
                push @ProfilingResults, [ $1, $2, $3, $4, $5, $6 ];
            }
        }

        close $Filehandle;
    }

    if (@ProfilingResults) {

        # define the order of the profiling data
        @ProfilingResults
            = sort { $b->[ $Config_Ref->{OrderBy} ] <=> $a->[ $Config_Ref->{OrderBy} ] }
            @ProfilingResults;
        if ( $Config_Ref->{OrderBy} == 1 ) {
            @ProfilingResults = reverse @ProfilingResults;
        }

        # remove disabled files or path if necessary
        if ( $Config_Ref->{DisabledFiles} ) {
            my $DisabledFiles = join '|', @{ $Config_Ref->{DisabledFiles} };
            @ProfilingResults = grep { $_->[0] !~ m{^($DisabledFiles)}x } @ProfilingResults;
        }

        # show only so many lines as wanted
        splice @ProfilingResults, $Config_Ref->{ShownLines};
    }

    # compute total calls
    my $TotalCall = 0;
    for my $Time (@ProfilingResults) {
        if ( $Time->[2] =~ /\d/ ) {
            $TotalCall += $Time->[2];
        }
    }

    $Param{ModuleRef}->{Data}      = \@ProfilingResults;
    $Param{ModuleRef}->{TotalCall} = $TotalCall;

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

    my $File = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l $File ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # to use SmallProf I have to manipulate the index.pl file
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    print $FilehandleII
        "#!/usr/bin/perl -w -d:SmallProf\n",
        "# FRED - manipulated\n",
        @Lines;
    close $FilehandleII;

    # create a info for the user
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the $File!",
    );

    # create the configuration file for the SmallProf module
    my $SmallProfFile = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/.smallprof';
    open my $FilehandleIII, '>', $SmallProfFile or die "Can't write $SmallProfFile !\n";
    print $FilehandleIII
        "# FRED - manipulated don't edit this file!\n",
        "# use ../../ as lib location\n",
        "use FindBin qw(\$Bin);\n",
        "use lib \"\$Bin/../..\";\n",
        "use Kernel::Config;\n",
        "my \$ConfigObject = Kernel::Config->new();\n",
        "if (\$ConfigObject->Get('Fred::SmallProf')->{Packages}) {\n",
        "    my \@Array = \@{ \$ConfigObject->Get('Fred::SmallProf')->{Packages} };\n",
        "    my \%Hash = map { \$_ => 1; } \@Array;\n",
        "    \%DB::packages = \%Hash;\n",
        "}\n",
        "\$DB::drop_zeros = 1;\n",
        "\$DB::grep_format = 1;\n";
    close $FilehandleIII;

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

    my $File = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l $File ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # read the index.pl file
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    # remove the manipulated lines
    if ( $Lines[0] =~ /#!\/usr\/bin\/perl -w -d:SmallProf/ ) {
        shift @Lines;
    }
    if ( $Lines[0] =~ /# FRED - manipulated/ ) {
        shift @Lines;
    }

    # save the index.pl file
    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    print $FilehandleII @Lines;
    close $FilehandleII;
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the $File!",
    );

    # delete the .smallprof because it is no longer needed
    my $SmallProfFile = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/.smallprof';
    unlink $SmallProfFile;

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

$Revision: 1.18 $ $Date: 2009-12-09 14:35:14 $

=cut
