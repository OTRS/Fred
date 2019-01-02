# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
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
<div style="font-size:13px; background-color: $BackgroundColor; padding: 6px 6px 12px 6px; text-shadow: 1px 1px 1px #333; width: 400px; text-align: center; position: absolute; left: 50%; margin-left: -206px; top: 0px;">$SystemName</div>
FILTERINPUT_HTML
    ${ $Param{Data} } =~ s{$Search}{$Replace$1}xms;

    return 1;
}

1;
