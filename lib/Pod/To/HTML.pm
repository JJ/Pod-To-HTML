use Pod::NodeWalker;

unit class Pod::To::HTML;

#| This method is required for perl6 --doc=HTML ...
method render($pod) {
    Pod::To::HTML::Renderer.new.pod-to-html($pod)
}

#| This class only listens for inline text and does not generate block-level
#| tags (<p>, <h1>, etc.).
#
# This should actually be implemented as a role, but because of
# https://rt.perl.org/Ticket/Display.html?id=124393, we can't have multi
# methods in the role that the class shadows. Instead, this causes an error
# from the compiler.
class Pod::To::HTML::InlineListener does Pod::NodeListener {
    use URI::Escape;

    # If this were in a role, it could be private.
    has Str $.accumulator is rw = q{};
    has Pod::NodeWalker $.walker = Pod::NodeWalker.new( :listener(self) );

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
                self.render-start-tag('dfn');
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
                self.handle-index-term($node);
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
        unless $node.meta[0] // $html {
            die 'L<> tag with no content';
        }

        # If the $node.meta has no content, then it was a simple tag
        # like L<doc:Module> or L<http://...>. In that case, we want
        # to use the _default_ text for that link type, rather than
        # the rendered contents.
        my ( $url, $default_text ) = self.url-and-text-for( $node.meta[0] // $html );
        $html = $default_text
        unless $node.meta[0];

        self.render-start-tag( 'a', :href($url) );
        $.accumulator ~= $html // $default_text;
        self.render-end-tag('a');
    }

    method url-and-text-for (Str:D $thing) {
        given $thing {
            #| Link to another module's documentation
            when /^ 'doc:' $<module> = [ <-[#]>+ ] [ '#' $<anchor> = [ .+ ] ]? $/ {
                return (
                    self.perl6-module-uri( :module($<module>), :anchor($<anchor>) ),
                    $<anchor>.defined ?? "$<anchor> in $<module>" !! $<module>,
                );
            }
            #| Internal doc link
            when /^ 'doc:'?  '#' $<anchor> = [ .+  ]$/ {
                return (
                    '#' ~ self.id-for($<anchor>),
                    $<anchor>,
                );
            }
            when /^ 'defn:' $<term> = [ .+ ] $/ {
                return (
                    '#' ~ self.id-for($<term>),
                    $<term>,
                );
            }
            when /^ $<type> = [ 'isbn' || 'issn' ] ':' $<num> = [ .+ ] $/ {
                return (
                    self.book-uri( :type($<type>), :num($<num>) ),
                    $<type>.uc ~ $<num>,
                );
            }
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
        return Pod::To::HTML::InlineListener.new.pod-to-html($node.contents);
    }

    method handle-footnote (Pod::FormattingCode $node) { ... }

    multi method end (Pod::FormattingCode $node) {
        given $node.type {
            when any %basic-html.keys {
                self.render-end-tag( %basic-html{$_} );
            }

            when 'E' {
                return;
            }

            when 'N' {
                return;
            }

            when 'D' {
                self.render-end-tag('dfn');
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
                    take self.escape-html($k) ~ q{="} ~ self.escape-html( %attr{$k} ) ~ q{"};
                }
            };
            $.accumulator ~= @pairs.join( q{ } );
        }
        $.accumulator ~= '>';
        $.accumulator ~= "\n" if $nl;
    }

    method render-end-tag (Cool:D $tag, :$nl = False) {
        $.accumulator ~= "</$tag>";
        $.accumulator ~= "\n" if $nl;
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
}

class Pod::To::HTML::Renderer is Pod::To::HTML::InlineListener {
    has Cool $!title;
    has Cool $!subtitle;
    has Callable $!url-maker;
    has Cool $!prelude;
    has Cool $!postlude;

    has Pair @!toc;
    has Pair @!meta;
    has @!footnotes;
    has %!index;
    has Bool $!render-paras = True;

    submethod BUILD (:$!title? = q{},
                     :$!subtitle? = q{},
                     :$!prelude? = ::?CLASS.default-prelude(),
                     :$!postlude? = ::?CLASS.default-postlude()) { }

    method pod-to-html ($pod) {
        callsame;
        return self.render-html;
    }

    method default-prelude {
        return qq:to/END/;
        <!doctype html>
        <html>
        <head>
          <title>___TITLE___</title>
          <meta charset="UTF-8">
          ___INLINE-STYLES___
          <link rel="stylesheet" href="http://design.perl6.org/perl.css">
          ___METADATA___
        </head>
        <body class="pod" id="___top">
        END
    }

    method default-postlude {
        return Q:to/END/;
        </body>
        </html>
        END
    }

    method render-html {
        return join "\n",
            self.render-prelude,
            self.render-title,
            self.render-subtitle,
            $.accumulator,
            self.render-footnotes,
            self.render-postlude;
    }

    method render-prelude returns Str:D {
        return $!prelude
            .subst( /'___TITLE___'/, $!title )
            .subst( /'___INLINE-STYLES___'/, self.inline-styles )
            .subst( /'___METADATA___'/, self.render-metadata );
    }

    method inline-styles {
        return Q:to/END/
            <style>
              /* code gets the browser-default font
               * kbd gets a slightly less common monospace font
               * samp gets the hard pixelly fonts
               */
              kbd { font-family: "Droid Sans Mono", "Luxi Mono", "Inconsolata", monospace }
              samp { font-family: "Terminus", "Courier", "Lucida Console", monospace }
              /* WHATWG HTML frowns on the use of <u> because it looks like a link,
               * so we make it not look like one.
               */
              u { text-decoration: none }
              .nested { margin-left: 3em; }
              // footnote things:
              aside { opacity: 0.7 }
              a[id ^= "footnote-"]:target { background: #ff0 }
            </style>
        END
    }

    method render-metadata {
        return @!meta.map(
            -> $p {
                qq[<meta name="{self.escape-html($p.key)}" value="{self.escape-html($p.value)}">]
            }
        ).join("\n");
    }

    method render-title {
        return q{} unless $!title.chars;
        return qq[<h1 class="title">{$!title}</h1>];
    }

    method render-subtitle {
        return q{} unless $!subtitle.chars;
        return qq[<h2 class="subtitle">{$!subtitle}</h1>];
    }

    method render-footnotes {
        return q{} unless @!footnotes;

        my $fn = "<aside><ol>\n";
        for @!footnotes.kv -> $i, $f {
            my $num = $i + 1;
            $fn ~= qq{<li><a href="#footnote-ref-$num" id="footnote-$num">[↑]</a>$f\</li>\n};
        }

        $fn ~= "</ol></aside>\n";

        return $fn;
    }

    method render-postlude {
        return $!postlude;
    }

    multi method start (Pod::Heading $node) {
        my $level = min( $node.level, 6 );
        my $id = self.id-for($node);
        my $tag = 'h' ~ $level;

        self.render-start-tag( $tag, :id($id) );

        return True;
    }

    multi method end (Pod::Heading $node) {
        my $level = min( $node.level, 6 );
        my $tag = 'h' ~ $level;

        self.render-end-tag( $tag, :nl );
    }

    multi method start (Pod::Block::Para $node) {
        return True unless $!render-paras;
        self.render-start-tag( 'p', :nl );
        return True;
    }

    multi method end (Pod::Block::Para $node) {
        return unless $!render-paras;
        self.render-end-tag( 'p', :nl );
    }

    multi method start (Pod::Block::Code $node) {
        self.render-start-tag('pre');
        self.render-start-tag('code');
        return True;
    }

    multi method end (Pod::Block::Code $node) {
        self.render-end-tag('code');
        self.render-end-tag( 'pre', :nl );
    }

    multi method start (Pod::Block::Comment $node) {
        return False;
    }
    # No end method needed here

    # See http://design.perl6.org/S26.html#Semantic_blocks for the list of
    # semantic blocks.
    my @semantic-meta-blocks = <
       AUTHOR
       AUTHORS
       COPYRIGHT
       COPYRIGHTS
       CREATED
       DESCRIPTION
       DESCRIPTIONS
       LICENCE
       LICENCES
       LICENSE
       LICENSES
       NAME
       NAMES
       SUMMARY
       SUMMARIES
       VERSION
       VERSIONS
    >;

    my @semantic-blocks = <
       ACKNOWLEDGEMENT
       ACKNOWLEDGEMENTS
       APPENDICES
       APPENDIX
       APPENDIXES
       BUG
       BUGS
       CHAPTER
       CHAPTERS
       DEPENDENCY
       DEPENDENCIES
       DIAGNOSTIC
       DIAGNOSTICS
       DISCLAIMER
       DISCLAIMERS
       EMULATES
       ERROR
       ERRORS
       EXCLUDES
       FOREWORD
       FOREWORDS
       INDEX
       INDEXES
       INTERFACE
       INTERFACES
       METHOD
       METHODS
       OPTION
       OPTIONS
       SECTION
       SECTIONS
       SEE-ALSO
       SUBROUTINE
       SUBROUTINES
       SYNOPSES
       SYNOPSIS
       TOC
       USAGE
       WARNING
       WARNINGS
    >;

    multi method start (Pod::Block::Named $node) {
        given $node.name {
            when 'config' {
                return False;
            }
            when 'defn' {
                # XXX - how to do a <dl> list sanely?
            }
            when 'nested' {
                self.render-start-tag( 'div', :class('nested') );
            }
            when 'output' {
                $!render-paras = False;
                self.render-start-tag('pre');
            }
            when 'para' {
                # We don't need to do anything special with this type of named
                # block, but I added it just so nobody wonders why it's not
                # here.
            }
            when 'pod'  {
                # XXX - not sure what to do with this - old code looked for
                # $node.config<class> but I can't find anything in the docs
                # about this.
                return True;
            }
            when 'Image' {
                self.handle-image-node($node);
                return False;
            }
            when any <Html Xhtml> {
                $.accumulator ~= $.walker.text-contents-of($node);
                return False;
            }
            when 'TITLE' {
                $!title = $.walker.text-contents-of($node);
                return False;
            }
            when 'SUBTITLE' {
                $!subtitle = $.walker.text-contents-of($node);
                return False;
            }
            when any @semantic-meta-blocks {
                self.handle-semantic-block( $node, :meta );
            }
            when any @semantic-blocks {
                self.handle-semantic-block($node);
            }
        }

        return True;
    }

    method handle-image-node (Pod::Block::Named $node) {
        my $url;
        if $node.contents == 1 {
            my $c = $node.contents[0];
            if $c ~~ Str {
                $url = $c;
            }
            elsif $c ~~ Pod::Block::Para && $c.contents == 1 {
                $url = $c.contents[0] if $c.contents[0] ~~ Str;
            }
        }
        unless $url.defined {
            die "Found an Image block, but don't know how to extract the image URL :(";
        }
        
        self.render-start-tag( 'img', :src($url) );
    }

    method handle-semantic-block (Pod::Block::Named $node, Bool :$meta) {
        if $meta {
            @!meta.push: Pair.new(
                key => $node.name.lc,
                value => $.walker.text-contents-of($node),
            );
        }

        self.render-start-tag( 'section', :nl );
        self.render-start-tag('h2');
        $.accumulator ~= $node.name.split(/'-'/).map({ $_.lc.tc }).join(q{ });
        self.render-end-tag( 'h2', :nl );
    }

    multi method end (Pod::Block::Named $node) {
        given $node.name {
            when 'nested' {
                self.render-end-tag('div');
            }
            when 'output' {
                self.render-end-tag('pre');
                $!render-paras = True;
            }
            when any( any(@semantic-meta-blocks), any(@semantic-blocks) ) {
                self.render-end-tag( 'section', :nl );
            }
        }
    }

    multi method start (Pod::Block::Declarator $node) {
        return True;
    }
    multi method end (Pod::Block::Declarator $node) {
    }

    multi method start (Pod::Block::Table $node) {
        self.render-start-tag( 'table', :nl );

        # As of 2015-11-26 $node.caption isn't populated. See
        # https://rt.perl.org/Ticket/Display.html?id=126740. The caption in
        # the config includes quotes from :caption('foo'). See
        # https://rt.perl.org/Ticket/Display.html?id=126742.
        my $caption = $node.caption // $node.config<caption>.subst( /^"'"|"'"$/, q{}, :g );
        if $caption  {
            self.render-start-tag( 'caption' );
            $.accumulator ~= self.escape-html($caption);
            self.render-end-tag( 'caption', :nl );
        }

        if $node.headers {
            self.render-start-tag( 'thead', :nl );
            self.render-start-tag( 'tr', :nl );

            temp $!render-paras = False;
            for $node.headers -> $cell {
                self.render-start-tag( 'th' );
                $.walker.walk-pod($cell);
                self.render-end-tag( 'th', :nl );
            }
            self.render-end-tag( 'tr', :nl );
            self.render-end-tag( 'thead', :nl );
        }

        self.render-start-tag( 'tbody', :nl );

        return True;
    }
    method table-row (Array $row) {
        self.render-start-tag( 'tr', :nl );
        for $row.values -> $cell {
            self.render-start-tag('td');
            $.walker.walk-pod($cell);
            self.render-end-tag( 'td', :nl );
        }
        self.render-end-tag( 'tr', :nl );
    }
    multi method end (Pod::Block::Table $node) {
        self.render-end-tag( 'tbody', :nl );
        self.render-end-tag( 'table', :nl )
    }

    method handle-footnote (Pod::FormattingCode $node) {
        my $id = @!footnotes + 1;
        self.render-start-tag('sup');
        self.render-start-tag( 'a', :href( "#footnote-$id" ), :id( "footnote-ref-$id" ) );
        $.accumulator ~= $id;
        self.render-end-tag('a');
        self.render-end-tag('sup');

        @!footnotes.push(self.rendered-contents-of($node));
    }

    # XXX - this probably isn't useful without adding something like <span
    # id="index-foo">foo</span> around the content of the X<> code.
    method handle-index-term (Pod::FormattingCode $node) {
        my $html = self.rendered-contents-of($node);
        %!index{$_} = $html for $node.meta;
    }

    multi method start (Pod::Item $node) {  }
    multi method end (Pod::Item $node) {  }

    multi method start (Pod::Raw $node) {
        if $node.target && lc $node.target eq 'html' {
            $.accumulator ~= $node.contents.join;
        }
    }
    multi method end (Pod::Raw $node) { }

    method config (Pod::Config $node) {  }
}

# vim: expandtab shiftwidth=4 ft=perl6
