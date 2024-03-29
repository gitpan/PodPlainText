#############################################################################
# PlainText.pm -- convert POD data to formatted ASCII text
#
# Derived from Tom Christiansen's Pod::Text module
# (with extensive modifications).
#
# Copyright (C) 1994-1996 Tom Christiansen. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#############################################################################

package Pod::PlainText;

$VERSION = 0.01;   ## Current version of this package
require  5.002;    ## requires Perl version 5.002 or later

=head1 NAME

pod2plaintext - function to convert POD data to formatted ASCII text

Pod::PlainText - a class for converting POD data to formatted ASCII text

=head1 SYNOPSIS

    use Pod::PlainText qw(pod2plaintext);
    pod2plaintext("perlfunc.pod");

or

    use Pod::PlainText;
    package MyFilter;
    @ISA = qw(Pod::PlainText);

    sub new {
       ## constructor code ...
    }

    ## implementation of appropriate subclass methods ...

    package main;
    $filter = new MyFilter;
    @ARGV = ('-')  unless (@ARGV > 0);
    for (@ARGV) {
       $filter->process_file($_);
    }

=head1 DESCRIPTION

Pod::PlainText is a module that can convert documentation in the POD
format (such as can be found throughout the Perl distribution) into
formatted ASCII.  Termcap is optionally supported for
boldface/underline, and can enabled via C<$Pod::PlainText::termcap=1>.
If termcap has not been enabled, then backspaces will be used to
simulate bold and underlined text.

A separate F<pod2plaintext> program is included that is primarily a wrapper for
C<Pod::PlainText::pod2plaintext()>.

The single function C<pod2plaintext()> can take one or two arguments. The first
should be the name of a file to read the pod from, or "<&STDIN" to read from
STDIN. A second argument, if provided, should be a filehandle glob where
output should be sent.

=head1 AUTHOR

Tom Christiansen E<lt>tchrist@mox.perl.comE<gt>

Modified to derive from B<Pod::Filter> by
Brad Appleton E<lt>Brad_Appleton-GBDA001@email.mot.comE<gt>

=head1 TODO

=cut

#############################################################################

require Exporter;
use Term::Cap;
use Pod::Filter;
@ISA = qw(Exporter Pod::Filter);
@EXPORT = qw(&pod2plaintext);

%HTML_Escapes = (
    'amp'       =>        '&',        #   ampersand
    'lt'        =>        '<',        #   left chevron, less-than
    'gt'        =>        '>',        #   right chevron, greater-than
    'quot'      =>        '"',        #   double quote

    "Aacute"    =>        "\xC1",     #   capital A, acute accent
    "aacute"    =>        "\xE1",     #   small a, acute accent
    "Acirc"     =>        "\xC2",     #   capital A, circumflex accent
    "acirc"     =>        "\xE2",     #   small a, circumflex accent
    "AElig"     =>        "\xC6",     #   capital AE diphthong (ligature)
    "aelig"     =>        "\xE6",     #   small ae diphthong (ligature)
    "Agrave"    =>        "\xC0",     #   capital A, grave accent
    "agrave"    =>        "\xE0",     #   small a, grave accent
    "Aring"     =>        "\xC5",     #   capital A, ring
    "aring"     =>        "\xE5",     #   small a, ring
    "Atilde"    =>        "\xC3",     #   capital A, tilde
    "atilde"    =>        "\xE3",     #   small a, tilde
    "Auml"      =>        "\xC4",     #   capital A, dieresis or umlaut mark
    "auml"      =>        "\xE4",     #   small a, dieresis or umlaut mark
    "Ccedil"    =>        "\xC7",     #   capital C, cedilla
    "ccedil"    =>        "\xE7",     #   small c, cedilla
    "Eacute"    =>        "\xC9",     #   capital E, acute accent
    "eacute"    =>        "\xE9",     #   small e, acute accent
    "Ecirc"     =>        "\xCA",     #   capital E, circumflex accent
    "ecirc"     =>        "\xEA",     #   small e, circumflex accent
    "Egrave"    =>        "\xC8",     #   capital E, grave accent
    "egrave"    =>        "\xE8",     #   small e, grave accent
    "ETH"       =>        "\xD0",     #   capital Eth, Icelandic
    "eth"       =>        "\xF0",     #   small eth, Icelandic
    "Euml"      =>        "\xCB",     #   capital E, dieresis or umlaut mark
    "euml"      =>        "\xEB",     #   small e, dieresis or umlaut mark
    "Iacute"    =>        "\xCD",     #   capital I, acute accent
    "iacute"    =>        "\xED",     #   small i, acute accent
    "Icirc"     =>        "\xCE",     #   capital I, circumflex accent
    "icirc"     =>        "\xEE",     #   small i, circumflex accent
    "Igrave"    =>        "\xCD",     #   capital I, grave accent
    "igrave"    =>        "\xED",     #   small i, grave accent
    "Iuml"      =>        "\xCF",     #   capital I, dieresis or umlaut mark
    "iuml"      =>        "\xEF",     #   small i, dieresis or umlaut mark
    "Ntilde"    =>        "\xD1",     #   capital N, tilde
    "ntilde"    =>        "\xF1",     #   small n, tilde
    "Oacute"    =>        "\xD3",     #   capital O, acute accent
    "oacute"    =>        "\xF3",     #   small o, acute accent
    "Ocirc"     =>        "\xD4",     #   capital O, circumflex accent
    "ocirc"     =>        "\xF4",     #   small o, circumflex accent
    "Ograve"    =>        "\xD2",     #   capital O, grave accent
    "ograve"    =>        "\xF2",     #   small o, grave accent
    "Oslash"    =>        "\xD8",     #   capital O, slash
    "oslash"    =>        "\xF8",     #   small o, slash
    "Otilde"    =>        "\xD5",     #   capital O, tilde
    "otilde"    =>        "\xF5",     #   small o, tilde
    "Ouml"      =>        "\xD6",     #   capital O, dieresis or umlaut mark
    "ouml"      =>        "\xF6",     #   small o, dieresis or umlaut mark
    "szlig"     =>        "\xDF",     #   small sharp s, German (sz ligature)
    "THORN"     =>        "\xDE",     #   capital THORN, Icelandic
    "thorn"     =>        "\xFE",     #   small thorn, Icelandic
    "Uacute"    =>        "\xDA",     #   capital U, acute accent
    "uacute"    =>        "\xFA",     #   small u, acute accent
    "Ucirc"     =>        "\xDB",     #   capital U, circumflex accent
    "ucirc"     =>        "\xFB",     #   small u, circumflex accent
    "Ugrave"    =>        "\xD9",     #   capital U, grave accent
    "ugrave"    =>        "\xF9",     #   small u, grave accent
    "Uuml"      =>        "\xDC",     #   capital U, dieresis or umlaut mark
    "uuml"      =>        "\xFC",     #   small u, dieresis or umlaut mark
    "Yacute"    =>        "\xDD",     #   capital Y, acute accent
    "yacute"    =>        "\xFD",     #   small y, acute accent
    "yuml"      =>        "\xFF",     #   small y, dieresis or umlaut mark

    "lchevron"  =>        "\xAB",     #   left chevron (double less than)
    "rchevron"  =>        "\xBB",     #   right chevron (double greater than)
);

use strict;
use diagnostics;
use Carp;

##---------------------------------
## Function definitions begin here
##---------------------------------

sub version {
    no strict;
    return  $VERSION;
}

sub pod2plaintext {
    my ($infile, $outfile) = @_;
    local $_;
    my $plaintext_filter = new Pod::PlainText;
    $plaintext_filter->process_file($infile, $outfile);
}

##-------------------------------
## Method definitions begin here
##-------------------------------

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %params = @_;
    my $self = {%params};
    bless $self, $class;
    $self->initialize();
    return  $self;
}

sub initialize {
    my $self = shift;
    $self->SUPER::initialize();
    return;
}

sub preprocess {
    my $self = shift;
    local($_) = shift;
    return  $self->SUPER::preprocess($_);
}

sub makespace {
    my $self = shift;
    my $out_fh = $self->{OUTPUT};
    if ($self->{NEEDSPACE}) {
        print $out_fh "\n";
        $self->{NEEDSPACE} = 0;
    }
}

sub bold {
    my $self = shift;
    my $line = shift;
    my $map  = $self->{FONTMAP};
    return $line if $self->{USE_FORMAT};
    if ($self->{TERMCAP}) {
        $line = "$map->{BOLD}$line$map->{NORM}";
    }
    else {
        $line =~ s/(.)/$1\b$1/g;
    }
#   $line = "$map->{BOLD}$line$map->{NORM}" if $self->{ANSIFY};
    return $line;
}

sub italic {
    my $self = shift;
    my $line = shift;
    my $map  = $self->{FONTMAP};
    return $line if $self->{USE_FORMAT};
    if ($self->{TERMCAP}) {
        $line = "$map->{UNDL}$line$map->{NORM}";
    }
    else {
        $line =~ s/(.)/$1\b_/g;
    }
#   $line = "$map->{UNDL}$line$map->{NORM}" if $self->{ANSIFY};
    return $line;
}

# Fill a paragraph including underlined and overstricken chars.
# It's not perfect for words longer than the margin, and it's probably
# slow, but it works.
sub fill {
    my $self = shift;
    local $_ = shift;
    my $par = "";
    my $indent_space = " " x $self->{INDENT};
    my $marg = $self->{SCREEN} - $self->{INDENT};
    my $line = $indent_space;
    my $line_length;
    foreach (split) {
        my $word_length = length;
        $word_length -= 2 while /\010/g;  # Subtract backspaces

        if ($line_length + $word_length > $marg) {
            $par .= $line . "\n";
            $line= $indent_space . $_;
            $line_length = $word_length;
        }
        else {
            if ($line_length) {
                $line_length++;
                $line .= " ";
            }
            $line_length += $word_length;
            $line .= $_;
        }
    }
    $par .= "$line\n" if $line;
    $par .= "\n";
    return $par;
}

## Handle a pending "item" paragraph.  The lone argument (if given) is the
## corresponding item text.  (the item tag should be in $self->{ITEM}).
sub item {
    my $self  = shift;
    local($_) = @_;
    return  unless (defined  $self->{ITEM});
    my $out_fh  = $self->{OUTPUT};
    my $paratag = $self->{ITEM};
    my $prev_indent = $self->{INDENTS}->[$#{$self->{INDEX}} - 1]
                      || $self->{DEF_INDENT};
    undef $self->{ITEM};
    if ((defined $_) && ($_ ne '')
                     && (length($paratag) + 3) < $self->{INDENT}) {
        if (/^=/) {  # tricked!
           $self->output($paratag, INDENT => $prev_indent);
        }
        else {
           $self->IP_output($paratag, $_);
        }
    }
    else {
        $self->output($paratag, INDENT => $prev_indent);
        $self->output($_, REFORMAT => 1);
    }
}

sub remap_whitespace {
    my $self  = shift;
    local($_) = shift;
    tr/\000-\177/\200-\377/;
    return $_;
}

sub unmap_whitespace {
    my $self  = shift;
    local($_) = shift;
    tr/\200-\377/\000-\177/;
    return $_;
}

sub IP_output {
    my $self  = shift;
    my $tag   = shift;
    local($_) = @_;
    my $out_fh  = $self->{OUTPUT};
    my $tag_indent  = $self->{INDENTS}->[$#{$self->{INDEX}} - 1]
                      || $self->{DEF_INDENT};
    my $tag_cols = $self->{SCREEN} - $tag_indent;
    my $cols = $self->{SCREEN} - $self->{INDENT};
    $tag =~ s/\s*$//;
    s/\s+/ /g;
    s/^ //;
    my $fmt_name = 'Pod_PlainText_IP_output_format';
    my $str = "format $fmt_name = \n"
        . (" " x ($tag_indent))
        . '@' . ('<' x ($self->{INDENT} - $tag_indent - 1))
        . "^" .  ("<" x ($cols - 1)) . "\n"
        . '$tag, $_'
        . "\n~~"
        . (" " x ($self->{INDENT} - 2))
        . "^" .  ("<" x ($cols - 5)) . "\n"
        . '$_' . "\n\n.\n1";
    #warn $str; warn "tag is $tag, _ is $_";
    {
        ## reset format (turn off warning about redefining a format)
        local($^W) = 0;
        eval $str;
        croak if ($@);
    }
    select((select($out_fh), $~ = $fmt_name)[0]);
    write $out_fh;
}

sub output {
    my $self = shift;
    local $_ = shift;
    my $out_fh = $self->{OUTPUT};
    my %options;
    if (@_ > 1) {
        ## usage was $self->output($text, NAME=>VALUE, ...);
        %options = @_;
    }
    elsif (@_ == 1) {
        if (ref $_[0]) {
           ## usage was $self->output($text, { NAME=>VALUE, ... } );
           %options = %{$_[0]};
        }
        else {
           ## usage was $self->output($text, $number);
           $options{"REFORMAT"} = shift;
        }
    }
    $options{"INDENT"} = $self->{INDENT}  unless (defined $options{"INDENT"});
    if ((defined $options{"REFORMAT"}) && $options{"REFORMAT"}) {
        my $cols = $self->{SCREEN} - $options{"INDENT"};
        s/\s+/ /g;
        s/^ //;
        my $fmt_name = 'Pod_PlainText_output_format';
        my $str = "format $fmt_name = \n~~"
            . (" " x ($options{"INDENT"} - 2))
            . "^" .  ("<" x ($cols - 5)) . "\n"
            . '$_' . "\n\n.\n1";
        {
            ## reset format (turn off warning about redefining a format)
            local($^W) = 0;
            eval $str;
            croak if ($@);
        }
        select((select($out_fh), $~ = $fmt_name)[0]);
        write $out_fh;
    }
    else {
        s/^/' ' x $options{"INDENT"}/gem;
        s/^\s+\n$/\n/gm;
        print $out_fh $_;
    }
}

sub internal_lrefs {
    my $self = shift;
    local $_ = shift;
    s{L</([^>]+)>}{$1}g;
    my(@items) = split( /(?:,?\s+(?:and\s+)?)/ );
    my $retstr = "the ";
    my $i;
    for ($i = 0; $i <= $#items; $i++) {
        $retstr .= "C<$items[$i]>";
        $retstr .= ", " if @items > 2 && $i != $#items;
        $retstr .= " and " if $i+2 == @items;
    }

   $retstr .= " entr" . ( @items > 1  ? "ies" : "y" )
                      .  " elsewhere in this document ";

   return $retstr;
}

sub begin_input {
    my $self = shift;

    #----------------------------------------------------
    # This class may wish to make use of some of the
    # commented-out code below for initializing pragmas
    #----------------------------------------------------
    # $self->{PRAGMAS} = {
    #     FILL     => 'on',
    #     STYLE    => 'plain',
    #     INDENT   => 0,
    # };
    # ## Initialize all PREVIOUS_XXX pragma values
    # my ($name, $value);
    # for (($name, $value) = each %{$self->{PRAGMAS}}) {
    #     $self->{PRAGMAS}->{"PREVIOUS_${name}"} = $value;
    # }
    #----------------------------------------------------

    $self->{TERMCAP} = 0;
    #$self->{USE_FORMAT} = 1;

    $self->{FONTMAP} = {
        UNDL => "\x1b[4m",
        INV  => "\x1b[7m",
        BOLD => "\x1b[1m",
        NORM => "\x1b[0m",
    };
    if ($self->{TERMCAP} and (! defined $self->{SETUPTERMCAP})) {
        $self->{SETUPTERMCAP} = 1;
        my ($term) = Tgetent Term::Cap { TERM => undef, OSPEED => 9600 };
        $self->{FONTMAP}->{UNDL} = $term->{'_us'};
        $self->{FONTMAP}->{INV}  = $term->{'_mr'};
        $self->{FONTMAP}->{BOLD} = $term->{'_md'};
        $self->{FONTMAP}->{NORM} = $term->{'_me'};
    }
   
    $self->{SCREEN} =
                ((defined $ENV{TERMCAP}) && ($ENV{TERMCAP} =~ /co#(\d+)/)[0])
                || ((defined $ENV{COLUMNS}) && $ENV{COLUMNS})
                || (`stty -a 2>/dev/null` =~ /(\d+) columns/)[0]
                || 72;
   
    $self->{FANCY}      = 0;
    $self->{DEF_INDENT} = 4;
    $self->{INDENTS}    = [];
    $self->{INDENT}     = $self->{DEF_INDENT};
    $self->{INDEX}      = [];
    $self->{NEEDSPACE}  = 0;
}

sub end_input {
    my $self = shift;
    $self->item()  if (defined $self->{ITEM});
}

sub pragma {
    my $self  = shift;
    ## convert remaining args to lowercase
    my $name  = lc shift;
    my $value = lc shift;
    my $rc = 1;
    local($_);
    #----------------------------------------------------
    # This class may wish to make use of some of the
    # commented-out code below for processing pragmas
    #----------------------------------------------------
    # my ($abbrev, %abbrev_table);
    # if ($name eq 'fill') {
    #     %abbrev_table = ('on' => 'on',
    #                      'of' => 'off',
    #                      'p'  => 'previous');
    #     $value = 'on' unless ((defined $value) && ($value ne ''));
    #     return  $rc  unless ($value =~ /^(on|of|p)/io);
    #     $abbrev = $1;
    #     $value = $abbrev_table{$abbrev};
    #     if ($value eq 'previous') {
    #         $self->{PRAGMAS}->{FILL} = $self->{PRAGMAS}->{PREVIOUS_FILL};
    #     }
    #     else {
    #         $self->{PRAGMAS}->{PREVIOUS_FILL} = $self->{PRAGMAS}->{FILL};
    #         $self->{PRAGMAS}->{FILL} = $value;
    #     }
    # }
    # elsif ($name eq 'style') {
    #     %abbrev_table = ('b'  => 'bold',
    #                      'i'  => 'italic',
    #                      'c'  => 'code',
    #                      'pl' => 'plain',
    #                      'pr' => 'previous');
    #     $value = 'plain' unless ((defined $value) && ($value ne ''));
    #     return  $rc  unless ($value =~ /^(b|i|c|pl|pr)/io);
    #     $abbrev = $1;
    #     $value = $abbrev_table{$abbrev};
    #     if ($value eq 'previous') {
    #         $self->{PRAGMAS}->{STYLE} = $self->{PRAGMAS}->{PREVIOUS_STYLE};
    #     }
    #     else {
    #         $self->{PRAGMAS}->{PREVIOUS_STYLE} = $self->{PRAGMAS}->{STYLE};
    #         $self->{PRAGMAS}->{STYLE} = $value;
    #     }
    # }
    # elsif ($name eq 'indent') {
    #     return $rc unless ((defined $value) && ($value =~ /^([-+]?)(\d*)$/o));
    #     my ($sign, $number) = ($1, $2);
    #     $value .= 3  unless ((defined $number) && ($number ne ''));
    #     $self->{PRAGMAS}->{PREVIOUS_INDENT} = $self->{PRAGMAS}->{INDENT};
    #     if ($sign) {
    #         $self->{PRAGMAS}->{INDENT} += $value;
    #     }
    #     else {
    #         $self->{PRAGMAS}->{INDENT} = $value;
    #     } 
    # }
    # else {
    #     $rc = 0;
    # }
    #----------------------------------------------------
    return $rc;
}

sub command {
    my $self = shift;
    my $cmd  = shift;
    local $_ = shift;
    $cmd  = ''  unless (defined $cmd);
    $_    = ''  unless (defined $_);
    my $out_fh  = $self->{OUTPUT};

    $_ = $self->interpolate($_);
    s/\s*$/\n/;
    $self->item()  if (defined $self->{ITEM});

    if ($cmd eq 'head1') {
        $self->makespace();
        print $out_fh $_;
        # print $out_fh uc($_);
    }
    elsif ($cmd eq 'head2') {
        $self->makespace();
        # s/(\w+)/\u\L$1/g;
        #print ' ' x $self->{DEF_INDENT}, $_;
        # print "\xA7";
        s/(\w)/\xA7 $1/ if $self->{FANCY};
        print $out_fh ' ' x ($self->{DEF_INDENT}/2), $_, "\n";
    }
    elsif ($cmd eq 'over') {
        push(@{$self->{INDENTS}}, $self->{INDENT});
        $self->{INDENT} += ($_ + 0) || $self->{DEF_INDENT};
    }
    elsif ($cmd eq 'back') {
        $self->{INDENT} = pop(@{$self->{INDENTS}});
        unless (defined $self->{INDENT}) {
            carp "Unmatched =back\n";
            $self->{INDENT} = $self->{DEF_INDENT};
        }
        $self->{NEEDSPACE} = 1;
    }
    elsif ($cmd eq 'item') {
        $self->makespace();
        # s/\A(\s*)\*/$1\xb7/ if $self->{FANCY};
        # s/^(\s*\*\s+)/$1 /;
        $self->{ITEM} = $_;
    }
    else {
        carp "Unrecognized directive: $cmd\n";
    }
}

sub verbatim {
    my $self = shift;
    local $_ = shift;
    $self->item()  if (defined $self->{ITEM});
    $self->{NEEDSPACE} = 1;
    $self->output($_);
}

sub textblock {
    my $self  = shift;
    my $text  = shift;
    local($_) = $self->interpolate($text);
    if (defined $self->{ITEM}) {
        $self->item($_);
    }
    else {
        s/\s*$/\n/;
        $self->makespace();
        $self->output($_, REFORMAT => 1);
    }
}

sub interior_sequence {
    my $self = shift;
    my $cmd  = shift;
    my $arg  = shift;
    local($_) = $arg;
    if ($cmd eq 'C') {
        no strict;  ## dont complain about $HTML_Escapes without package prefix
        my ($pre, $post) = ("`", "'");
        ($pre, $post) = ($HTML_Escapes{"lchevron"}, $HTML_Escapes{"rchevron"})
                if ((defined $self->{FANCY}) && $self->{FANCY});
        $_ = $pre . $_ . $post;
    }
    elsif ($cmd eq 'E') {
        no strict;  ## dont complain about $HTML_Escapes without package prefix
        if (defined $HTML_Escapes{$_}) {
            $_ = $HTML_Escapes{$_};
        }
        else {
            carp "Unknown escape: E<$_>";
            $_ = "E<$_>";
        }
    # }
    # elsif ($cmd eq 'B') {
    #     $_ = $self->bold($_);
    }
    elsif ($cmd eq 'I') {
        # $_ = $self->italic($_);
        $_ = "*" . $_ . "*";
    }
    elsif (($cmd eq 'X') || ($cmd eq 'Z')) {
        $_ = '';
    }
    elsif ($cmd eq 'S') {
        # Escape whitespace until we are ready to print
        #$_ = $self->remap_whitespace($_);
    }
    elsif ($cmd eq 'L') {
        s/\s+/ /g;
        my ($manpage, $sec, $ref) = ($_, '', '');
        if (/^\s*"\s*(.*)\s*"\s*$/o) {
            ($manpage, $sec) = ('', "\"$1\"");
        }
        elsif (m|\s*/\s*|o) {
            ($manpage, $sec) = ($`, $');
        }
        if ($sec eq '') {
            $ref .= "the $manpage manpage"  if ($manpage ne '');
        }
        elsif ($sec =~ /^\s*"\s*(.*)\s*"\s*$/o) {
            $ref .= "section \"$1\"";
            $ref .= " in the $manpage manpage"  if ($manpage ne '');
        }
        else {
             $ref .= "the \"$sec\" entry";
             $ref .= ($manpage eq '') ? " in this manpage"
                                      : " in the $manpage manpage";
        }
        $_ = $ref;
        #if ( m{^ ([a-zA-Z][^\s\/]+) (\([^\)]+\))? $}x ) {
        #    ## LREF: a manpage(3f)
        #    $_ = "the $1$2 manpage";
        #}
        #elsif ( m{^ ([^/]+) / ([:\w]+(\(\))?) $}x ) {
        #    ## LREF: an =item on another manpage
        #    $_ = "the \"$2\" entry in the $1 manpage";
        #}
        #elsif ( m{^ / ([:\w]+(\(\))?) $}x ) {
        #    ## LREF: an =item on this manpage
        #    $_ = $self->internal_lrefs($1);
        #}
        #elsif ( m{^ (?: ([a-zA-Z]\S+?) / )? "?(.*?)"? $}x ) {
        #    ## LREF: a =head2 (head1?), maybe on a manpage, maybe right here
        #    ## the "func" can disambiguate
        #    $_ = ((defined $1) && $1)
        #            ? "the section on \"$2\" in the $1 manpage"
        #            : "the section on \"$2\"";
        #}
    }
    return  $_;
}

1;
