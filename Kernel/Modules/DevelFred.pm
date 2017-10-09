# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::DevelFred;

use strict;
use warnings;

use Kernel::System::Fred;
use Kernel::System::SysConfig;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed Objects
    OBJECT:
    for my $Object (
        qw(
        ParamObject DBObject     LogObject ConfigObject
        MainObject  LayoutObject TimeObject EncodeObject
        )
        )
    {
        if ( $Param{$Object} ) {
            $Self->{$Object} = $Param{$Object};
            next OBJECT;
        }
        $Self->{LayoutObject}->FatalError( Message => "Got no $Object!" );
    }

    $Self->{SysConfigObject} = Kernel::System::SysConfig->new( %{$Self} );

    $Self->{FredObject} = Kernel::System::Fred->new( %{$Self} );
    $Self->{Subaction} = $Self->{ParamObject}->GetParam( Param => 'Subaction' );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # ---------------------------------------------------------- #
    # show the overview
    # ---------------------------------------------------------- #

    if ( !$Self->{Subaction} ) {
        my $Version = $Self->{ConfigObject}->Get('Version');

        $Self->{LayoutObject}->FatalError(
            Message => 'Sorry, this page is currently under development!',
        );
    }

    # ---------------------------------------------------------- #
    # fast handle for fred settings
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'Setting' ) {

        # get hashref with all Fred-plugins
        my $ModuleForRef = $Self->{ConfigObject}->Get('Fred::Module');

        # The Console can't be deactivated
        delete $ModuleForRef->{Console};

        # loop over Modules which can be activated and deactivated
        for my $Module ( sort keys %{$ModuleForRef} ) {
            my $Checked = $ModuleForRef->{$Module}->{Active} ? 'checked="checked"' : '';
            $Self->{LayoutObject}->Block(
                Name => 'FredModule',
                Data => {
                    FredModule  => $Module,
                    Checked     => $Checked,
                    Description => $ModuleForRef->{$Module}->{Description} || '',
                },
            );

            # Provide a link to the SysConfig only for plugins that have config options
            if ( $Self->{ConfigObject}->Get("Fred::$Module") ) {
                $Self->{LayoutObject}->Block(
                    Name => 'Config',
                    Data => {
                        ModuleName => $Module,
                        }
                );
            }
        }

        # build output
        my $Output = $Self->{LayoutObject}->Header(
            Title => 'Fred-Setting',
            Type  => 'Small',
        );
        $Output .= $Self->{LayoutObject}->Output(
            Data         => {%Param},
            TemplateFile => 'DevelFredSetting',
        );
        $Output .= $Self->{LayoutObject}->Footer(
            Type => 'Small',
        );

        return $Output;
    }

    # ---------------------------------------------------------- #
    # fast handle for fred settings
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'SettingAction' ) {
        my $ModuleForRef        = $Self->{ConfigObject}->Get('Fred::Module');
        my @SelectedFredModules = $Self->{ParamObject}->GetArray( Param => 'FredModule' );
        my %SelectedModules     = map { $_ => 1; } @SelectedFredModules;
        my $UpdateFlag;
        delete $ModuleForRef->{Console};

        for my $Module ( sort keys %{$ModuleForRef} ) {

            # update the sysconfig settings
            if (
                $ModuleForRef->{$Module}->{Active} && !$SelectedModules{$Module}
                ||
                !$ModuleForRef->{$Module}->{Active} && $SelectedModules{$Module}
                )
            {
                # update certain values
                $ModuleForRef->{$Module}->{Active} = $SelectedModules{$Module} || 0;

                $Self->{SysConfigObject}->ConfigItemUpdate(
                    Valid => 1,
                    Key   => "Fred::Module###$Module",
                    Value => $ModuleForRef->{$Module},
                );
                $UpdateFlag = 1;
            }
        }

        return $Self->{LayoutObject}->PopupClose(
            Reload => 1,
        );
    }

    return 1;
}

1;
