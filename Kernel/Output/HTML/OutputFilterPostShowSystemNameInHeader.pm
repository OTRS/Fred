# --
# Kernel/Output/HTML/OutputFilterPostShowSystemNameInHeader.pm
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterPostShowSystemNameInHeader;

use strict;
use warnings;

use Cwd;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw( MainObject ConfigObject ParamObject )) {
        if ( !$Self->{$Needed} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Needed!" );
        }
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $TemplateName = $Param{TemplateFile} || '';

    return 1 if !$TemplateName;

    # get valid modules
    my $ValidTemplates = $Self->{ConfigObject}->Get('Frontend::Output::FilterElementPost')
        ->{'OutputFilterPostShowSystemNameInHeader'}->{Templates};

    # apply only if template is valid in config
    return 1 if ( !$ValidTemplates->{$TemplateName} );

    # get config
    my $SystemName = $Self->{ConfigObject}->Get('Fred::SystemName')
        || $Self->{ConfigObject}->Get('Home');
    my $BackgroundColor = $Self->{ConfigObject}->Get('Fred::BackgroundColor')
        || 'red';

    # Add current git branch to output
    my $Home = $Self->{ConfigObject}->Get('Home');
    if ( -d "$Home/.git" ) {
        my $OldWorkingDir = getcwd();
        chdir($Home);
        my $GitResult = `git branch`;
        chdir($OldWorkingDir);

        if ($GitResult) {
            my ($BranchName) = $GitResult =~ m/^[*] \s+ (\S+)/xms;
            $SystemName .= " ($BranchName)";
        }
    }

    # inject system name right into the middle of the header to always have the attention
    my $Search  = '(<div \s* id="Logo"></div>)';
    my $Replace = <<"FILTERINPUT_HTML";
<div style="font-size:18px; background-color: $BackgroundColor; padding: 10px 10px 15px 10px; width: 400px; text-align: center; position: absolute; left: 50%; margin-left: -110px; top: 0px; border-radius: 0px 0px 5px 5px;">$SystemName</div>
FILTERINPUT_HTML
    ${ $Param{Data} } =~ s{$Search}{$Replace$1}xms;

    return 1;
}

1;
