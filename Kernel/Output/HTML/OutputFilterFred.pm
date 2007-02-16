# --
# Kernel/Output/HTML/OutputFilterFred.pm
# Copyright (C) 2001-2006 OTRS GmbH, http://otrs.org/
# --
# $Id: OutputFilterFred.pm,v 1.1.1.1 2007-02-16 17:59:15 tr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Output::HTML::OutputFilterFred;

use strict;

use vars qw($VERSION);
$VERSION = '$Revision: 1.1.1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

sub new {
    my $Type = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless ($Self, $Type);

    # get needed objects
    foreach (qw(ConfigObject LogObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }

    return $Self;
}

sub Run {
    my $Self = shift;
    my %Param = @_;
    my $Text = '';
    my $Home = $Self->{ConfigObject}->Get('Home');

    # Check the HTML-Output with HTML::Lint
    if ($Self->{ConfigObject}->Get('Fred::HTMLCheck')) {
        use HTML::Lint;
        my $HTMLText = '';
        my $HTMLLintObject = HTML::Lint->new( only_types => HTML::Lint::Error::STRUCTURE );
        $HTMLLintObject->parse (${$Param{Data}});

        my $ErrorCounter = $HTMLLintObject->errors;
        foreach my $Error ($HTMLLintObject->errors) {
            my $String .= $Error->as_string;
            if ($String !~ /Invalid character .+ should be written as /) {
                $HTMLText .=  $String . "\n";
            }
        }
        if ($HTMLText) {
            $Text .= $Self->_HTMLQuote(
                Text => $HTMLText,
                Title => "HTML-Checker",
            );
        }
    }

    # Search for apache errorlog warning
    if ($Self->{ConfigObject}->Get('Fred::ApacheErrorlogWarnings')) {
        if (open (OUTPUT, "< /var/log/apache2/error_log")) {
            my $ErrorLogText = '';
            my @Row = <OUTPUT>;
            my @ReverseRow = reverse(@Row);
            foreach (@ReverseRow) {
                if ($_ =~ /FRED/) {
                    last;
                }
                $ErrorLogText .= $_;
            }

            print STDERR "FRED\n";

            close (OUTPUT);

            if ($ErrorLogText) {
                $Text .= $Self->_HTMLQuote(
                    Text => $ErrorLogText,
                    Title => "Apache2 error_log",
                );
            }
        }
    }
    # use the cvs checks
    if ($Self->{ConfigObject}->Get('Fred::CVSFilter')) {
        my $PathToCVSFilter = $Self->{ConfigObject}->Get('Fred::PathToCVSFilter');
        if (${$Param{Data}} =~ /Notify.+?Action.+?value="(.+?)">.*?$/mxs) {
            my $Action = $1;
            my $FilterText = '';
            if (-e "$Home/Kernel/Modules/$Action.pm") {
                if (open (OUTPUT, "perl $PathToCVSFilter/filter-extended.pl $Home/Kernel/Modules $Home/Kernel/Modules/$Action.pm |")) {
                    my $Merge = 0;
                    while (<OUTPUT>) {
                        if ($_!~ /^NOTICE/) {
                            $FilterText .= $_;
                            $Merge = 1;
                        }
                    }
                    close (OUTPUT);
                    if ($Merge) {
                        $FilterText = $Action . ".pm\n" . $FilterText;
                    }
                }
            }

            my $SystemModule = '';
            if ($Action =~ /(Agent|Admin|Customer|Public)(.+)$/) {
                $SystemModule = $2;
            }

            if (-e "$Home/Kernel/System/$SystemModule.pm") {
                if (open (OUTPUT, "perl $PathToCVSFilter/filter-extended.pl $Home/Kernel/System $Home/Kernel/System/$SystemModule.pm |")) {
                    my $Merge = 0;
                    while (<OUTPUT>) {
                        if ($_!~ /^NOTICE/) {
                            $FilterText .= $_;
                            $Merge = 1;
                        }
                    }
                    close (OUTPUT);
                    if ($Merge) {
                        $FilterText = $SystemModule . ".pm\n" . $FilterText;
                    }
                }
            }
            if ($FilterText) {
                $Text .= $Self->_HTMLQuote(
                    Text => $FilterText,
                    Title => "filter-extended.pl",
                );
            }
        }
    }
    #-----------------------------------------

    if ($Text) {
        if (${$Param{Data}} =~ s/(\<body\>)/$1\n$Text\n\n\n\n/mx) {
        }
    }

    return 1;
}

sub _HTMLQuote {
    my $Self = shift;
    my %Param = @_;
        $Param{Text} =~ s/&/&amp;/g;
        $Param{Text} =~ s/</&lt;/g;
        $Param{Text} =~ s/>/&gt;/g;
        $Param{Text} =~ s/\n/\n\<br\>/g;
        $Param{Text} = "<b>$Param{Title}</b><br>\n" . $Param{Text};

    return $Param{Text};
}

1;
