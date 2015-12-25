use Pod::TreeWalker;
use Pod::TreeWalker::Listener;

#| This class only listens for inline text and does not generate block-level
#| tags (<p>, <h1>, etc.).
#
# Should this be a role? I'm not sure. It would take a bit of re-architecting
# but it might be the right design.
unit class Pod::To::HTML::InlineListener does Pod::TreeWalker::Listener;

use URI::Escape;

# If this were in a role, it could be private.
has Str $.accumulator is rw = q{};
has Pod::TreeWalker $.walker = Pod::TreeWalker.new( :listener(self) );
has Str $.last-start-tag is rw = q{};
has Str $.last-end-tag is rw = q{};
has Str %known-ids;
has Int $!id-counter = 0;

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
            my $id = self.id-for($node);
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
    my $link = $node.meta[0] || self!raw-pod-from($node);
    unless $link  {
        die "L<> tag with no link - {$node.perl}";
    }

    my ( $url, $default-text, $strip-leading ) = self.url-and-text-for($link);

    self.render-start-tag( 'a', :href($url) );

    # There are several cases to consider here ...
    #
    # The link contains text to use inside the <a> tag separate from the thing
    # which we're linking - L<foo|bar>. In that case we simply use the
    # contents of the node for the link text (inside <a>...</a>), and
    # $node.meta[0] contains the thing we turn into a URL.
    #
    # The link contains just one thing which we need to turn into a URL _and_
    # the text to use - L<foo>. In this case $node.meta is empty and so we
    # have to use $node.contents.

    # The url-and-text-for method may either return default text for us to use
    # inside the <a> tag _or_ it will give us a regex to be used to modify the
    # rendered node contents.
    #
    # This behavior is necessary because for some types of links, like links
    # to anchors, we need to turn the Pod objects back into text, then use
    # that to calculate the link. For example, given the link L<#anchor with
    # B<formatting>>, we generate the link from the raw text "#anchor with
    # B<formatting>" but when we go to actually fill in the <a> tag we want to
    # render that B<> code while still stripping the leading "#". Sheesh,
    # complicated!
    $.accumulator ~= $node.meta[0]
        ?? self.rendered-contents-of($node)
        !! $default-text
        ?? self.escape-html($default-text)
        !! self.rendered-contents-of($node).subst( $strip-leading, q{} );

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
        when /^ 'doc:'? '#' $<anchor> = [ .+ ]$/ {
            return (
                '#' ~ uri-escape( self.id-for($<anchor>) ),
                Nil,
                rx{ ^ 'doc:'? '#' },
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
            return (
                $thing,
                Nil,
                rx{^$},
            );
        }
    }
}

method perl6-module-uri (Cool:D :$module, Cool :$anchor) {
    my $url = 'http://modules.perl6.org/dist/' ~ uri-escape($module);
    $url ~= '#' ~ uri-escape($anchor) if $anchor.defined;
    return $url;
}

method book-uri (Cool:D :$type, Cool:D :$num) {
    my $q = $type eq 'isbn' ?? 'isbn:' !! 'n2:';
    $q ~= $num;
    return 'https://www.worldcat.org/q=' ~ uri-escape($q);
}

method man-page-uri (Cool:D :$page, Cool:D :$section, Cool :$anchor) {
    my $url = 'http://man7.org/linux/man-pages/';
    $url ~= 'man' ~ $section ~ '/' ~ uri-escape($page) ~ '.' ~ uri-escape($section) ~ '.html';
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
    return self!raw-text-to-id( self!raw-pod-from($pod) );
}

# This is only called by id-for, which in turn is only called to generate ids
# for headings and definitions. In those cases, we do not expect any nested
# Pod _except_ for formatting codes. In other words, a heading should not
# contain other headings, items, etc.
method !raw-pod-from (Pod::Block:D $pod) {
    my @text = gather {
        for $pod.contents -> $node {
            given $node {
                when Pod::FormattingCode {
                    take $node.type ~ '<' ~ self!raw-pod-from($node) ~ '>';
                }
                when Str {
                    take $node;
                }
                default {
                    take self!raw-pod-from($_);
                }
            }
        }
    }

    return [~] @text;
}

multi method id-for (Cool:D $thing) {
    return self!raw-text-to-id($thing);
}

method !raw-text-to-id (Cool:D $raw) {
    return %known-ids{$raw} //= $raw.subst( /\s+/, '_', :g ) ~ '-' ~ $!id-counter++;
}

# vim: expandtab shiftwidth=4 ft=perl6
