# --
# Kernel/Output/HTML/OutputFilterFred.pm
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: OutputFilterFred.pm,v 1.35 2012-10-24 16:50:03 mab Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterFred;

use strict;
use warnings;
use Digest::MD5 qw(md5);

use Kernel::System::Fred;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.35 $) [1];

=head1 NAME

Kernel::Output::HTML::OutputFilterFred

=head1 SYNOPSIS

a output filter module specially for developer

=head1 PUBLIC INTERFACE

=over 4

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(MainObject ConfigObject LogObject )) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{LayoutObject} = $Param{LayoutObject};
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # perhaps no output is generated
    die 'Fred: At the moment, your code generates no output!' if !$Param{Data};

    # do not show the debug bar in Fred's setting window
    if ( $Self->{LayoutObject}->{Action} && $Self->{LayoutObject}->{Action} eq 'DevelFred' ) {

        # Inject CSS into <head></head> for valid HTML
        my $CSSOutput = $Self->{LayoutObject}->Output(
            TemplateFile => 'DevelFredCommonCSS',
        );
        ${ $Param{Data} } =~ s{</head>}{$CSSOutput\n\t</head>}smx;

        return 1;
    }

    # do nothing if output is a attachment
    if (
        ${ $Param{Data} } =~ /^Content-Disposition: attachment;/mi
        || ${ $Param{Data} } =~ /^Content-Disposition: inline;/mi
        )
    {
        print STDERR "ATTACHMENT DOWNLOAD\n";
        return 1;
    }

    # do nothing if it is a redirect
    if (
        ${ $Param{Data} } =~ /^Status: 302 Moved/mi
        && ${ $Param{Data} } =~ /^location:/mi
        && length( ${ $Param{Data} } ) < 800
        )
    {
        print STDERR "REDIRECT\n";
        return 1;
    }

    # do nothing if it is fred it self
    if ( ${ $Param{Data} } =~ m{Fred-Setting<\/title>}msx ) {
        print STDERR "CHANGE FRED SETTING\n";
        return 1;
    }

    # do nothing if it does not contain the <html> element, might be
    # an embedded layout rendering
    if ( ${ $Param{Data} } !~ m{<html[^>]*>}msx ) {
        return 1;
    }

    # get data of the activated modules
    my $ModuleForRef   = $Self->{ConfigObject}->Get('Fred::Module');
    my $ModulesDataRef = {};
    for my $Module ( keys %{$ModuleForRef} ) {
        if ( $ModuleForRef->{$Module}->{Active} ) {
            $ModulesDataRef->{$Module} = {};
        }
    }

    my $FredObject = Kernel::System::Fred->new( %{$Self} );

    # load the activated modules
    $FredObject->DataGet(
        FredModulesRef => $ModulesDataRef,
        HTMLDataRef    => $Param{Data},
    );

    # create freds output
    $Self->{LayoutObject}->CreateFredOutput( FredModulesRef => $ModulesDataRef );

    # build the content string
    my $Output = '';
    if ( $ModulesDataRef->{Console}->{Output} ) {
        $Output .= $ModulesDataRef->{Console}->{Output};
        delete $ModulesDataRef->{Console};
    }
    for my $Module ( keys %{$ModulesDataRef} ) {
        $Output .= $ModulesDataRef->{$Module}->{Output} || '';
    }

    my $JSOutput = '';
    $Output =~ s{(<script.+?/script>)}{
        $JSOutput .= $1;
        "";
    }smxeg;

    # Put output in the Fred Container
    $Output = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredContainer',
        Data         => {
            Data => $Output
        },
    );

    # include the fred output in the original output
    if ( ${ $Param{Data} } !~ s/(\<body(|.+?)\>)/$1\n$Output\n\n\n\n/mx ) {
        ${ $Param{Data} } =~ s/^(.)/\n$Output\n\n\n\n$1/mx;
    }

    # Inject JS at the end of the body
    ${ $Param{Data} } =~ s{</body>}{$JSOutput\n\t</body>}smx;

    # Inject CSS into <head></head> for valid HTML
    my $CSSOutput = $Self->{LayoutObject}->Output(
        TemplateFile => 'DevelFredCommonCSS',
    );
    ${ $Param{Data} } =~ s{</head>}{$CSSOutput\n\t</head>}smx;

    # Add a short JS snippet to make the Fred Box draggable
    my $SystemName = md5( $Self->{ConfigObject}->Get('Home') );
    ${ $Param{Data} } .= <<EOF;
<!--dtl:js_on_document_complete-->
<script type="text/javascript">//<![CDATA[
\$('#DevelFredContainer').draggable({
    handle: 'h1',
    stop: function(event, ui) {
        var Top = ui.offset.top,
            Left = ui.offset.left;

        if (window && window['localStorage'] !== undefined) {
            localStorage['FRED_console_left_$SystemName'] = Left;
            localStorage['FRED_console_top_$SystemName']  = Top;
        }
    }
});

if (window && window['localStorage'] !== undefined) {

    var SavedLeft  = localStorage['FRED_console_left_$SystemName'],
        SavedTop   = localStorage['FRED_console_top_$SystemName'],
        FredWidth  = \$('#DevelFredContainer').width(),
        FredHeight = \$('#DevelFredContainer').height();

    if (SavedLeft > \$('body').width()) {
        SavedLeft = \$('body').width() - FredWidth;
    }
    if (SavedTop > \$('body').height()) {
        SavedTop = \$('body').height() - FredHeight;
    }

    if (SavedLeft && SavedTop) {
        \$('#DevelFredContainer').css('left', SavedLeft + 'px');
        \$('#DevelFredContainer').css('top', SavedTop + 'px');
    }
}

//]]></script>
<!--dtl:js_on_document_complete-->
EOF

    return 1;
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

$Revision: 1.35 $ $Date: 2012-10-24 16:50:03 $

=cut
