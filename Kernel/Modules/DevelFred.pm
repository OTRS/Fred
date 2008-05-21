# --
# Kernel/Modules/DevelFred.pm - a special developer module
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: DevelFred.pm,v 1.12 2008-05-21 10:11:56 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

package Kernel::Modules::DevelFred;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.12 $) [1];

#use Kernel::System::XML;
use Kernel::System::Config;
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
        MainObject  LayoutObject TimeObject
        )
        )
    {
        if ( $Param{$Object} ) {
            $Self->{$Object} = $Param{$Object};
            next OBJECT;
        }
        $Self->{LayoutObject}->FatalError( Message => "Got no $Object!" );
    }

    #    $Self->{XMLObject} = Kernel::System::XML->new(%{$Self});
    $Self->{ConfigToolObject} = Kernel::System::Config->new( %{$Self} );
    $Self->{FredObject}       = Kernel::System::Fred->new( %{$Self} );
    $Self->{Subaction}        = $Self->{ParamObject}->GetParam( Param => 'Subaction' );
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # ---------------------------------------------------------- #
    # show the overview
    # ---------------------------------------------------------- #

    if ( !$Self->{Subaction} ) {
        my $Version = $Self->{ConfigObject}->Get('Version');
        if ( $Version =~ m{ ^2\.1\. }msx ) {
            return $Self->_ActivateFredFor21();
        }
        $Self->{LayoutObject}->FatalError(
            Message => "Sorry, this side is currently under development!"
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
        my $ModuleForRef = $Self->{ConfigObject}->Get('Fred::Module');
        delete $ModuleForRef->{Console};
        for my $Module ( sort keys %{$ModuleForRef} ) {
            my $Checked = '';
            if ( $ModuleForRef->{$Module}->{Active} ) {
                $Checked = 'checked="checked"';
            }

            $Self->{LayoutObject}->Block(
                Name => 'FredModule',
                Data => {
                    FredModule => $Module,
                    Checked    => $Checked,
                    }
            );

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
        my $Output = $Self->{LayoutObject}->Header( Title => "Fred-Setting" );
        $Output .= $Self->{LayoutObject}->Output(
            Data         => {%Param},
            TemplateFile => 'DevelFredSetting',
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

        for my $Module ( keys %{$ModuleForRef} ) {

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
        for my $Module ( keys %{$ModuleForRef} ) {
            if ( $ModuleForRef->{$Module}->{Active} && !$SelectedModules{$Module} ) {

                # Errorhandling should be improved!
                $Self->{FredObject}->DeactivateModuleTodos(
                    ModuleName => $Module,
                );
            }
        }

        # active fred module todos
        for my $Module ( keys %{$ModuleForRef} ) {
            if ( !$ModuleForRef->{$Module}->{Active} && $SelectedModules{$Module} ) {

                # Errorhandling should be improved!
                $Self->{FredObject}->ActivateModuleTodos(
                    ModuleName => $Module,
                );
            }
        }

        return $Self->{LayoutObject}->Redirect( OP => "Action=DevelFred&Subaction=Setting" );
    }
    return 1;
}

sub _ActivateFredFor21 {
    my $Self = shift;

    my $Message = 'File already changed!';

    if ( $Self->{FredObject}->InsertLayoutObject21() ) {
        $Message = 'File changed!';
    }

    my $Output = $Self->{LayoutObject}->Header();
    $Output .= $Self->{LayoutObject}->NavigationBar();
    $Output .= $Self->{LayoutObject}->Notify(
        Info     => $Message,
        Priority => 'Error',
    );
    $Output .= $Self->{LayoutObject}->Footer();
    return $Output;
}
1;
