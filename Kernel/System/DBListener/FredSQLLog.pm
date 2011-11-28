# --
# Kernel/System/DBListener/FredSQLLog.pm
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id: FredSQLLog.pm,v 1.1 2011-11-28 13:49:37 mg Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DBListener::FredSQLLog;

use Kernel::System::Fred::SQLLog;

use Time::HiRes qw(gettimeofday tv_interval);

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.1 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(ConfigObject LogObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{SQLLogObject} = Kernel::System::Fred::SQLLog->new(%Param);

    $Self->{Active} = $Self->{ConfigObject}->Get('Fred::Module')->{SQLLog}->{Active};

    return $Self;
}

sub PrePrepare {
    my ( $Self, %Param ) = @_;

    return if ( !$Self->{Active} );

    $Self->{PrepareStart} = [gettimeofday];
}

sub PostPrepare {
    my ( $Self, %Param ) = @_;

    return if ( !$Self->{Active} );

    my $DiffTime = tv_interval( $Self->{PrepareStart} );
    my $Caller   = caller(1);

    my @Array = map { defined $_ ? $_ : 'undef' } @{ $Param{Bind} || [] };
    my $BindString = @Array ? join ', ', @Array : '';
    $Self->{SQLLogObject}->InsertWord(
        What => "SQL-SELECT##!##$Param{SQL}##!##$BindString##!##$Caller##!##$DiffTime",
    );
}

sub PreDo {
    my ( $Self, %Param ) = @_;

    return if ( !$Self->{Active} );

    $Self->{DoStart} = [gettimeofday];
}

sub PostDo {
    my ( $Self, %Param ) = @_;

    return if ( !$Self->{Active} );

    my $DiffTime = tv_interval( $Self->{DoStart} );
    my $Caller   = caller(1);

    my @Array = map { defined $_ ? $_ : 'undef' } @{ $Param{Bind} || [] };
    my $BindString = @Array ? join ', ', @Array : '';
    $Self->{SQLLogObject}->InsertWord(
        What => "SQL-DO##!##$Param{SQL}##!##$BindString##!##$Caller##!##$DiffTime",
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.1 $ $Date: 2011-11-28 13:49:37 $

=cut
