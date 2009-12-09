# --
# Kernel/System/Fred/SmallProf.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: SmallProf.pm,v 1.15 2009-12-09 08:36:25 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::SmallProf;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.15 $) [1];

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
    my $SmallProfObject = Kernel::System::Fred::SmallProf->new(
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

    my $Path       = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/';
    my $Config_Ref = $Self->{ConfigObject}->Get('Fred::SmallProf');
    my @Lines;

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

    return 1 if ${ $Param{HTMLDataRef} } =~ /Fred-Setting/;

    # find out which packages are checked by SmallProf
    my @Packages        = keys %DB::packages;
    my $CVSCheckProblem = \%DB::packages;       # sorry, this is because of the CVSChecker
    if ( !$Packages[0] ) {
        $Packages[0] = 'all';
    }
    $Param{ModuleRef}->{Packages} = \@Packages;

    # catch the needed profiling data
    system "cp $Path/smallprof.out $Path/FredSmallProf.out";

    if ( open my $Filehandle, '<', $Path . 'FredSmallProf.out' ) {

        # convert the file in useable data
        while ( my $Line = <$Filehandle> ) {
            if ( $Line =~ /(.+?):(\d+?):(\d+?):(\d+?):(\d+?):\s*(.*?)$/ ) {
                push @Lines, [ $1, $2, $3, $4, $5, $6 ];
            }
        }

        # define the order of the profiling data
        @Lines = sort { $b->[ $Config_Ref->{OrderBy} ] <=> $a->[ $Config_Ref->{OrderBy} ] } @Lines;
        if ( $Config_Ref->{OrderBy} == 1 ) {
            @Lines = reverse @Lines;
        }

        # remove disabled files or path if necessary
        if ( $Config_Ref->{DisabledFiles} ) {
            my $DisabledFiles = join '|', @{ $Config_Ref->{DisabledFiles} };
            @Lines = grep { $_->[0] !~ m{^($DisabledFiles)}x } @Lines;
        }

        # show only so many lines as wanted
        if (@Lines) {
            splice @Lines, $Config_Ref->{ShownLines};
            $Param{ModuleRef}->{Data} = \@Lines;
        }
        close $Filehandle;
    }

    # compute total calls
    my $TotalCall = 0;
    for my $Time (@Lines) {
        if ( $Time->[2] =~ /\d/ ) {
            $TotalCall += $Time->[2];
        }
    }
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
    die "Can't manipulate $File because it is a symlink!" if -l $File;

    # to use SmallProf I have to manipulate the index.pl file
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    print $FilehandleII "#!/usr/bin/perl -w -d:SmallProf\n";
    print $FilehandleII "# FRED - manipulated\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
    close $FilehandleII;

    # create a info for the user
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the $File!",
    );

    # create the configuration file for the SmallProf module
    my $SmallProfFile = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/.smallprof';
    open my $FilehandleIII, '>', $SmallProfFile or die "Can't write $SmallProfFile !\n";
    print $FilehandleIII "# FRED - manipulated don't edit this file!\n";
    print $FilehandleIII "# use ../../ as lib location\n";
    print $FilehandleIII "use FindBin qw(\$Bin);\n";
    print $FilehandleIII "use lib \"\$Bin/../..\";\n";
    print $FilehandleIII "use Kernel::Config;\n";
    print $FilehandleIII "my \$ConfigObject = Kernel::Config->new();\n";
    print $FilehandleIII "if (\$ConfigObject->Get('Fred::SmallProf')->{Packages}) {\n";
    print $FilehandleIII
        "    my \@Array = \@{ \$ConfigObject->Get('Fred::SmallProf')->{Packages} };\n";
    print $FilehandleIII "    my \%Hash = map { \$_ => 1; } \@Array;\n";
    print $FilehandleIII "    \%DB::packages = \%Hash;\n";
    print $FilehandleIII "}\n";
    print $FilehandleIII "\$DB::drop_zeros = 1;\n";
    print $FilehandleIII "\$DB::grep_format = 1;\n";
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
    die "Can't manipulate $File because it is a symlink!" if -l $File;

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
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
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

$Revision: 1.15 $ $Date: 2009-12-09 08:36:25 $

=cut
