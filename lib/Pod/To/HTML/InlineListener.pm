use Pod::TreeWalker;
use Pod::TreeWalker::Listener;

#| This class only listens for inline text and does not generate block-level
#| tags (<p>, <h1>, etc.).
#
# This should actually be implemented as a role, but because of
# https://rt.perl.org/Ticket/Display.html?id=124393, we can't have multi
# methods in the role that the class shadows. Instead, this causes an error
# from the compiler.
unit class Pod::To::HTML::InlineListener does Pod::TreeWalker::Listener;

use Pod::TreeWalker;
use URI::Escape;

# If this were in a role, it could be private.
has Str $.accumulator is rw = q{};
has Pod::TreeWalker $.walker = Pod::TreeWalker.new( :listener(self) );
has Str $.last-start-tag is rw = q{};
has Str $.last-end-tag is rw = q{};

method pod-to-html ($pod) {
    $.walker.walk-pod($pod);
    return $.accumulator;
}

my %basic-html = (
    B => 'strong',  #= Basis
    C => 'code',    #= Code
    I => 'em',      #= Important
    K => 'kbd',     #= Keyboard
    R => 'var',     #= Replaceable
    T => 'samp',    #= Terminal
    U => 'u',       #= Unusual
);
multi method start (Pod::FormattingCode $node) {
    given $node.type {
        when any %basic-html.keys {
            self.render-start-tag( %basic-html{$_} );
            return True;
        }

        when 'D' {
            my $id = self.id-for( $.walker.text-contents-of($node) );
            self.render-start-tag( 'dfn', :id($id) );
            return True;
        }

        when 'E' {
            given $node.meta[0] {
                when Int { $.accumulator ~= "&#$_;" }
                when Str { $.accumulator ~= "&$_;"  }
            };
            return False;
        }

        when 'L' {
            self.handle-link($node);
            return False;
        }

        when 'N' {
            self.handle-footnote($node);
            return False;
        }

        when 'X' {
            self.start-index-term($node);
            return True;
        }

        #| zero-width comment - we just ignore it
        when 'Z' {
            return False;
        }

        default {
            die "Unknown formatting code for {self.WHAT} - {$node.type}";
        }
    }
}

method handle-link (Pod::FormattingCode $node) {
    my $html = self.rendered-contents-of($node);
    unless $node.meta[0] || $html {
        die "L<> tag with no content - {$node.perl}";
    }

    # If the $node.meta has no content, then it was a simple tag
    # like L<doc:Module> or L<http://...>. In that case, we want
    # to use the _default_ text for that link type, rather than
    # the rendered contents.
    my ( $url, $default_text ) = self.url-and-text-for( $node.meta[0] || $html );
    $html = $default_text
    unless $node.meta[0];

    self.render-start-tag( 'a', :href($url) );
    $.accumulator ~= $html || $default_text;
    self.render-end-tag('a');
}

method url-and-text-for (Str:D $thing) {
    given $thing {
        #| Link to another module's documentation (may have an anchor)
        when /^ 'doc:' $<module> = [ <-[#]>+ ] [ '#' $<anchor> = [ .+ ] ]? $/ {
            return (
                self.perl6-module-uri( :module($<module>), :anchor($<anchor>) ),
                $<anchor>.defined ?? "$<anchor> in $<module>" !! $<module>,
            );
        }
        #| Internal doc link (may have an anchor)
        when /^ 'doc:'?  '#' $<anchor> = [ .+  ]$/ {
            return (
                '#' ~ self.id-for($<anchor>),
                $<anchor>,
            );
        }
        #| Link to a definition in the same document
        when /^ 'defn:' $<term> = [ .+ ] $/ {
            return (
                '#' ~ self.id-for($<term>),
                $<term>,
            );
        }
        #| Book link
        when /^ $<type> = [ 'isbn' || 'issn' ] ':' $<num> = [ .+ ] $/ {
            return (
                self.book-uri( :type($<type>), :num($<num>) ),
                $<type>.uc ~ $<num>,
            );
        }
        #| Man page link (may have an anchor)
        when /^ 'man:' $<page> = [ .+ ] '(' $<section> = [ \d+ ] ')' [ '#' $<anchor> = [ .+ ] ]? $/ {
            return (
                self.man-page-uri( :page($<page>), :section($<section>), :anchor($<anchor>) ),
                ( $<anchor>.defined ?? "$<anchor> in " !! q{} ) ~ "$<page>\($<section>\)",
            );
        }
        when /^ $<uri> = ( 'mailto:' $<address> = [ .+ ] ) $/ {
            return (
                $<uri>,
                $<uri><address>,
            );
        }
        when /^ 'file:' $<file> = [ .+ ] $/ {
            return (
                "file://$<file>",
                $<file>,
            );
        }
        default {
            return $thing xx 2;
        }
    }
}

method perl6-module-uri (Cool:D :$module, Cool :$anchor) {
    my $url = "http://modules.perl6.org/dist/$module";
    $url ~= '#' ~ $anchor if $anchor.defined;
    return $url;
}

method book-uri (Cool:D :$type, Cool:D :$num) {
    my $q = $type eq 'isbn' ?? 'isbn:' !! 'n2:';
    $q ~= $num;
    return 'https://www.worldcat.org/q=' ~ uri_escape($q);
}

method man-page-uri (Cool:D :$page, Cool:D :$section, Cool :$anchor) {
    my $url = 'http://man7.org/linux/man-pages/';
    $url ~= 'man' ~ $section ~ '/' ~ $page ~ '.' ~ $section ~ '.html';
    $url ~= '#' ~ $anchor if $anchor.defined;
    return $url;
}

method rendered-contents-of (Pod::Block:D $node) {
    return Pod::To::HTML::InlineListener.new.pod-to-html( $node.contents );
}

method handle-footnote (Pod::FormattingCode $node) { ... }

multi method end (Pod::FormattingCode $node) {
    given $node.type {
        when any %basic-html.keys {
            self.render-end-tag( %basic-html{$_} );
        }
        when 'D' {
            self.render-end-tag('dfn');
        }
        when 'X' {
            self.end-index-term($node);
        }
    }
}

multi method start (Pod::Block::Para $node) {
    return True;
}

multi method end (Pod::Block::Para $node) {
    return;
}

method text (Str $text) {
    $.accumulator ~= self.escape-html($text);
}

method render-start-tag (Cool:D $tag, Bool :$nl = False, *%attr) {
    $.accumulator ~= "<$tag";
    if (%attr) {
        $.accumulator ~= q{ };
        my @pairs = gather {
            # < emacs perl6-mode hack
            for %attr.keys.sort -> $k {
                my @vals = %attr{$k} ~~ List ?? %attr{$k}.values !! %attr{$k};
                # < emacs perl6-mode hack
                for @vals -> $v {
                    take self.escape-html($k) ~ q{="} ~ self.escape-html($v) ~ q{"};
                }
            }
        };
        $.accumulator ~= @pairs.join( q{ } );
    }
    $.accumulator ~= '>';
    $.accumulator ~= "\n" if $nl;
    $.last-start-tag = $tag;
    $.last-end-tag = q{};
}

method render-end-tag (Cool:D $tag, :$nl = False) {
    $.accumulator ~= "</$tag>";
    $.accumulator ~= "\n" if $nl;
    $.last-start-tag = q{};
    $.last-end-tag = $tag;
}

my %html-escapes = (
    '&'     => '&amp;',
    "\x3c"  => '&lt;',    # Emacs perl6-mode doesn't like a quoted < :(
    '>'     => '&gt;',
    q{"}    => '&quot;',  # "
    q{'}    => '&#39;',   # '
);

method escape-html(Cool:D $str) returns Str {
    state $escapable = rx/( @(%html-escapes.keys) )/;
    return $str.subst( $escapable, { %html-escapes{ $/[0] } }, :g );
}

multi method id-for (Pod::Block:D $pod) {
    return self.escape-id( $.walker.text-contents-of($pod) );
}

multi method id-for (Cool:D $thing) {
    return self.escape-id($thing);
}

method escape-id ($id) {
    return $id.subst( /\s+/, '_', :g );
}

# vim: expandtab shiftwidth=4 ft=perl6
