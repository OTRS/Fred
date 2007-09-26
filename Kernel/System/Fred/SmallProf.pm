# --
# Kernel/System/Fred/SmallProf.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: SmallProf.pm,v 1.5 2007-09-26 08:11:52 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred::SmallProf;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.5 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

=head1 NAME

Kernel::System::Fred::SmallProf

=head1 SYNOPSIS

handle the SmallProf profiling data

=over 4

=cut

=item new()

create a object

    use Kernel::Config;
    use Kernel::System::Log;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );

=cut

sub new {
    my $Type  = shift;
    my %Param = @_;

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
    my $Self       = shift;
    my %Param      = @_;
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
    if (${$Param{HTMLDataRef}} !~ /\<body.*?\>/ ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'This page deliver the HTML by many separate output calls.'
                . ' Please use the usual way to interpret SmallProf',
        );
        return 1;
    }
    if (${$Param{HTMLDataRef}} =~ /Fred-Setting/) {
        return 1;
    }

    # find out which packages are checked by SmallProf
    my @Packages = keys %DB::packages;
    my $CVSCheckProblem = \%DB::packages; # sorry, this is because of the CVSChecker
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

#            # alternative solution 2
#            my @Elements = split (':',$Line);
#            $Elements[0] =~ s/^.*?cgi-bin\/\.\.\/\.\.\///;
#            push @Lines, \@Elements;
        }

        # define the order of the profiling data
        @Lines = sort { $b->[ $Config_Ref->{OrderBy} ] <=> $a->[ $Config_Ref->{OrderBy} ] } @Lines;
        if ( $Config_Ref->{OrderBy} == 1 ) {
            @Lines = reverse @Lines;
        }

        # show only so many lines as wanted
        if (@Lines) {
            splice @Lines, $Config_Ref->{ShownLines};
            $Param{ModuleRef}->{Data} = \@Lines;
        }

#        # alternative solution 1
#        while ( my $Line = <$Filehandle> ) {
#            if ($Line =~ /^\s*?[1-9]/) {
#                if ($Line =~ /^\s*?(\d+?)\s+?(\d.+?)\s+?(\d.+?)\s+?(\d+?):(.*?)$/) {
#                    push @Lines, [$1, $2, $3, $4, $5];
#                }
#            }
#        }
#        @Lines = sort {$b->[1] <=> $a->[1]} @Lines;
#        $Param{ModuleRef}->{Data} = \@Lines;

        close $Filehandle;
    }

    return 1;
}

=item ActivateModuleTodos()

Do all jobs which are necessary to activate this special module.

    $FredObject->ActivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub ActivateModuleTodos {
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l "$File" ) {
        die 'Can\'t manipulate $File because it is a symlink!';
    }

    # to use SmallProf I have to manipulate the index.pl file
    open my $Filehandle, '<', $File || die "Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
    }
    close $Filehandle;

    open my $FilehandleII, '>', $File || die "Can't write $File !\n";
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
    open my $FilehandleIII, '>', $SmallProfFile || die "Can't write $SmallProfFile !\n";
    print $FilehandleIII "# FRED - manipulated don't edit this file!\n";
    print $FilehandleIII "# use ../../ as lib location\n";
    print $FilehandleIII "use FindBin qw(\$Bin);\n";
    print $FilehandleIII "use lib \"\$Bin/../..\";\n";
    print $FilehandleIII "use Kernel::Config;\n";
    print $FilehandleIII "my \$ConfigObject = Kernel::Config->new();\n";
    print $FilehandleIII "if (\$ConfigObject->Get('Fred::SmallProf')->{Packages}) {\n";
    print $FilehandleIII "    my \@Array = \@{ \$ConfigObject->Get('Fred::SmallProf')->{Packages} };\n";
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
    my $Self  = shift;
    my @Lines = ();
    my $File  = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l "$File" ) {
        die 'Can\'t manipulate $File because it is a symlink!';
    }

    # read the index.pl file
    open my $Filehandle, '<', $File || die "Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
    }
    close $Filehandle;

    # remove the manipulated lines
    if ( $Lines[0] =~ /#!\/usr\/bin\/perl -w -d:SmallProf/ ) {
        shift @Lines;
    }
    if ( $Lines[0] =~ /# FRED - manipulated/ ) {
        shift @Lines;
    }

    # save the index.pl file
    open my $FilehandleII, '>', $File || die "Can't write $File !\n";
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
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl.txt.

=cut

=head1 VERSION

$Revision: 1.5 $ $Date: 2007-09-26 08:11:52 $

=cut