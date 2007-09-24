# --
# Kernel/System/Fred/SmallProf.pm
# Copyright (C) 2001-2007 OTRS GmbH, http://otrs.org/
# --
# $Id: SmallProf.pm,v 1.2 2007-09-24 14:54:22 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::System::Fred::SmallProf;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '$Revision: 1.2 $';
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
    my $Self  = shift;
    my %Param = @_;
    my $Path  = $Self->{ConfigObject}->Get('Home'). "/bin/cgi-bin/";
    my $Config_Ref = $Self->{ConfigObject}->Get('Fred::SmallProf');
    my @Lines;

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need ModuleRef!",
        );
        return;
    }

    system "cp $Path/smallprof.out $Path/FredSmallProf.out";
    if ( open my $Filehandle, '<', $Path . 'FredSmallProf.out' ) {
        while ( my $Line = <$Filehandle> ) {
            if ($Line =~ /^\//) {
                if ($Line =~ /^.*?cgi-bin\/\.\.\/\.\.\/(.+?):(\d+?):(\d+?):(\d+?):(\d+?):\s*(.*?)$/) {
                    push @Lines, [$1, $2, $3, $4, $5, $6];
                }

                # alternative solution 2
                # my @Elements = split (':',$Line);
                # $Elements[0] =~ s/^.*?cgi-bin\/\.\.\/\.\.\///;
                # push @Lines, \@Elements;
            }
        }

        @Lines = sort {$b->[$Config_Ref->{OrderBy}] <=> $a->[$Config_Ref->{OrderBy}]} @Lines;

        if ($Config_Ref->{OrderBy} == 1) {
            @Lines = reverse @Lines;
        }

        splice @Lines, $Config_Ref->{ShownLines};
        ${ $Param{ModuleRef} }{Data} = \@Lines;

        # alternative solution 1
        # while ( my $Line = <$Filehandle> ) {
        #     if ($Line =~ /^\s*?[1-9]/) {
        #         if ($Line =~ /^\s*?(\d+?)\s+?(\d.+?)\s+?(\d.+?)\s+?(\d+?):(.*?)$/) {
        #             push @Lines, [$1, $2, $3, $4, $5];
        #         }
        #     }
        # }
        # @Lines = sort {$b->[1] <=> $a->[1]} @Lines;
        # ${ $Param{ModuleRef} }{Data} = \@Lines;
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
    my $File  = $Self->{ConfigObject}->Get('Home') . "/bin/cgi-bin/index.pl";

    if ( -l "$File" ) {
        die 'Can\'t manipulate $File because it is a symlink!';
    }

    open my $Filehandle, '<', $File  || die "FILTER: Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
    }
    close $Filehandle;

    open my $FilehandleII, '>', $File || die "FILTER: Can't write $File !\n";
    print $FilehandleII "#!/usr/bin/perl -w -d:SmallProf\n";
    print $FilehandleII "# FRED - manipulated\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
    close $FilehandleII;
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => 'FRED manipulated the $File!',
    );

    my $SmallProfFile = $Self->{ConfigObject}->Get('Home') . "/bin/cgi-bin/.smallprof";
    open my $FilehandleIII, '>', $SmallProfFile || die "FILTER: Can't write $SmallProfFile !\n";
    print $FilehandleIII "%DB::packages = ( 'Kernel::Output::HTML::Layout' => 1, );\n";
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
    my $File  = $Self->{ConfigObject}->Get('Home') . "/bin/cgi-bin/index.pl";

    if ( -l "$File" ) {
        die 'Can\'t manipulate $File because it is a symlink!';
    }

    # read the index.pl file
    open my $Filehandle, '<', $File  || die "FILTER: Can't open $File !\n";
    while ( my $Line = <$Filehandle> ) {
        push @Lines, $Line;
    }
    close $Filehandle;

    # remove the manipulated lines
    if ($Lines[0] =~ /#!\/usr\/bin\/perl -w -d:SmallProf/) {
        shift @Lines;
    }
    if ($Lines[0] =~ /# FRED - manipulated/) {
        shift @Lines;
    }

    # save the index.pl file
    open my $FilehandleII, '>', $File || die "FILTER: Can't write $File !\n";
    for my $Line (@Lines) {
        print $FilehandleII $Line;
    }
    close $FilehandleII;
    $Self->{LogObject}->Log(
        Priority => 'error',
        Message  => 'FRED manipulated the $File!',
    );

    my $SmallProfFile = $Self->{ConfigObject}->Get('Home') . "/bin/cgi-bin/.smallprof";
    system ("rm $SmallProfFile");

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

$Revision: 1.2 $ $Date: 2007-09-24 14:54:22 $

=cut