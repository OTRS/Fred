# --
# Kernel/System/Fred/NYTProf.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: NYTProf.pm,v 1.2 2009-12-10 09:40:13 bes Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::NYTProf;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.2 $) [1];

#use Devel::NYTProf::Data;
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

    # in these two cases it makes no sense to generate the profiling list
    if ( ${ $Param{HTMLDataRef} } !~ /\<body.*?\>/ ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'This page deliver the HTML by many separate output calls.'
                . ' Please use the usual way to interpret NYTProf',
        );
        return 1;
    }
    if ( ${ $Param{HTMLDataRef} } =~ m/Fred-Setting/ ) {
        return 1;
    }

    # the config is not used yet
    #my $Config = $Self->{ConfigObject}->Get('Fred::NYTProf');

    # The profiling output from a running process can generally not be analyzed.
    # However we can tell NYTProf that we are done with profile and that the
    # output file should be closed properly.
    DB::finish_profile();

    # The generated file nytprof.out can be parsed with Devel::NYTProf::Data,
    # but the resulting data structure is fairly daunting.
    #my @ProfilingResults;
    #my $Profile = Devel::NYTProf::Data->new( { filename => "$Path/nytprof.out", quiet => 1 } );
    #my $Reader  = Devel::NYTProf::Reader->new('nytprof.out');   # will print to STDOUT

    # So simply call nytprofhtml and provide a link to the generated HTML.
    # The data from the previous request is deleted.
    my $HTMLOutputDir = $Self->{ConfigObject}->Get('Home') . '/var/httpd/htdocs/nytprof';
    my $GenHTMLCmd    = "nytprofhtml -out $HTMLOutputDir 2>&1";
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

    my $File = $Self->{ConfigObject}->Get('Home') . '/bin/cgi-bin/index.pl';

    # check if it is an symlink, because it can be development system which use symlinks
    if ( -l $File ) {
        die "Can't manipulate $File because it is a symlink!";
    }

    # to use NYTProf I have to manipulate the index.pl file
    # TODO: slurp into a scalar
    open my $Filehandle, '<', $File or die "Can't open $File !\n";
    my @Lines = <$Filehandle>;
    close $Filehandle;

    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    print $FilehandleII
        "#!/usr/bin/perl -w -d:NYTProf\n",
        "# FRED - manipulated\n",
        @Lines;
    close $FilehandleII;

    # create a info for the user
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => "FRED manipulated the $File!",
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
    if ( $Lines[0] =~ m{#!/usr/bin/perl -w -d:NYTProf} ) {
        shift @Lines;
    }
    if ( $Lines[0] =~ m{# FRED - manipulated} ) {
        shift @Lines;
    }

    # save the index.pl file
    open my $FilehandleII, '>', $File or die "Can't write $File !\n";
    print $FilehandleII @Lines;
    close $FilehandleII;
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
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.2 $ $Date: 2009-12-10 09:40:13 $

=cut
