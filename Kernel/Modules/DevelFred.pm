# --
# Kernel/Modules/DevelFred.pm - a special developer module
# Copyright (C) 2001-2013 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::DevelFred;

use strict;
use warnings;

use Kernel::System::Fred;

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

    # With framework version 2.5 or higher Kernel::System::Config
    # is renamed to Kernel::System::SysConfig
    my $FrameworkVersion = $Param{ConfigObject}->Get('Version');
    if ( $FrameworkVersion =~ /^2\.(0|1|2|3|4)\./ ) {
        $Param{MainObject}->Require('Kernel::System::Config');
        $Self->{ConfigToolObject} = Kernel::System::Config->new( %{$Self} );
    }
    else {
        $Param{MainObject}->Require('Kernel::System::SysConfig');
        $Self->{ConfigToolObject} = Kernel::System::SysConfig->new( %{$Self} );
    }

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

    #        my $Output   = '';
    #
    #        my @TranslationWhiteList = $Self->{XMLObject}->XMLHashGet(
    #            Type => 'Fred-Translation',
    #            Key  => 1,
    #            Cache => 0,
    #        );
    #
    #        my %WhiteList;
    #        for my $Content (@{$TranslationWhiteList[1]{Translation}}) {
    #            if ($Content->{Content}) {
    #                # add add block
    #                $Self->{LayoutObject}->Block(
    #                    Name => 'Line',
    #                    Data => {
    #                        Word => $Content->{Content},
    #                    },
    #                );
    #            }
    #        }
    #
    #        # build output
    #        $Output .= $Self->{LayoutObject}->Header(Title => "Fred-Overview");
    #        $Output .= $Self->{LayoutObject}->NavigationBar();
    #        $Output .= $Self->{LayoutObject}->Output(
    #            Data => {%Param},
    #            TemplateFile => 'DevelFred',
    #        );
    #        $Output .= $Self->{LayoutObject}->Footer();
    #        return $Output;
    #    }
    #    # ---------------------------------------------------------- #
    #    # handle the translation log
    #    # ---------------------------------------------------------- #
    #    elsif ($Self->{Subaction} eq 'Translation') {
    #        my $Value = $Self->{ParamObject}->GetParam(Param => 'Value');
    #
    #        my @Data = $Self->{XMLObject}->XMLHashGet(
    #            Type => 'Fred-Translation',
    #            Key  => 1,
    #            Cache => 0,
    #        );
    #
    #        if (!@Data) {
    #            my @Hash;
    #
    #            $Hash[1]{Translation}[1]{Content} = $Value;
    #            $Self->{XMLObject}->XMLHashAdd(
    #                Type    => 'Fred-Translation',
    #                Key     => 1,
    #                XMLHash => \@Hash,
    #            );
    #        }
    #        else {
    #            push @{$Data[1]{Translation}}, {Content => $Value};
    #            $Self->{XMLObject}->XMLHashUpdate(
    #                Type => 'Fred-Translation',
    #                Key => '1',
    #                XMLHash => \@Data,
    #            );
    #
    #        }
    #
    #        my $Referer = $ENV{HTTP_REFERER};
    #        if ($Referer =~ /\?(.+)$/) {
    #            $Referer = $1;
    #        }
    #
    #        return $Self->{LayoutObject}->Redirect(OP => $Referer);
    #    }
    #    elsif ($Self->{Subaction} eq 'TranslationDelete') {
    #        my @Data = $Self->{XMLObject}->XMLHashDelete(
    #            Type => 'Fred-Translation',
    #            Key  => 1,
    #        );
    #
    #        my $Referer = $ENV{HTTP_REFERER};
    #        if ($Referer =~ /\?(.+)$/) {
    #            $Referer = $1;
    #        }
    #
    #        return $Self->{LayoutObject}->Redirect(OP => $Referer);
    #    }
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
                    FredModule => $Module,
                    Checked    => $Checked,
                    }
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
                $Self->{ConfigToolObject}->ConfigItemUpdate(
                    Valid => 1,
                    Key   => "Fred::Module###$Module",
                    Value => {
                        'Active' => $SelectedModules{$Module} || 0,

                        #                        'Module' => $ModuleForRef->{$Module}->{Module}
                    },
                );
                $UpdateFlag = 1;
            }
        }

        # this function is neseccary to finish the sysconfig update
        my $Version = $Self->{ConfigObject}->Get('Version');
        if ( $UpdateFlag && $Version =~ m{ ^2\.[012]\. }msx ) {
            $Self->{ConfigToolObject}->ConfigItemUpdateFinish();
        }

        # deactivate fredmodule todos
        for my $Module ( sort keys %{$ModuleForRef} ) {
            if ( $ModuleForRef->{$Module}->{Active} && !$SelectedModules{$Module} ) {

                # Errorhandling should be improved!
                $Self->{FredObject}->DeactivateModuleTodos(
                    ModuleName => $Module,
                );
            }
        }

        # active fred module todos
        for my $Module ( sort keys %{$ModuleForRef} ) {
            if ( !$ModuleForRef->{$Module}->{Active} && $SelectedModules{$Module} ) {

                # Errorhandling should be improved!
                $Self->{FredObject}->ActivateModuleTodos(
                    ModuleName => $Module,
                );
            }
        }

        return $Self->{LayoutObject}->Redirect( OP => 'Action=DevelFred;Subaction=Setting' );
    }

    return 1;
}

1;
