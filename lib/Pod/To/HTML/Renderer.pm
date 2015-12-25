use Pod::To::HTML::InlineListener;

unit class Pod::To::HTML::Renderer is Pod::To::HTML::InlineListener;

has Bool $!include-toc;
has Cool $!title;
has Cool $!subtitle;
has Cool $!prelude;
has Cool $!postlude;

has Hash @!toc;
has Pair @!meta;
has @!footnotes;
has %!index;
has Bool $!render-paras = True;

submethod BUILD (
    $class:
    $!include-toc = True,
    :$!title = q{},
    :$!subtitle = q{},
    :$!prelude? = $class.default-prelude,
    :$!postlude? = $class.default-postlude,
) { }

method pod-to-html ($pod) {
    callsame;
    return self.render-html;
}

method default-prelude {
    return Q:to/END/
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
    return (
        self.render-prelude,
        self.render-toc,
        self.render-title,
        self.render-subtitle,
        $.accumulator,
        self.render-footnotes,
        self.render-postlude
    ).grep( { .defined } ).join("\n");
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
            qq[<meta name="{self.escape-html( $p.key )}" value="{self.escape-html( $p.value )}">]
        }
    ).join("\n");
}

method render-toc {
    return unless @!toc;

    my $renderer = Pod::To::HTML::Renderer.new;
    $renderer.render-start-tag( 'nav', :nl );

    # We already have all the code necessary to handle nested lists in
    # Pod::TreeWalker. Rather than repeat it all here again for HTML
    # generation, we'll make a fake POD document containing just list items
    # based on our headings. Then we render that POD to HTML and poof, we have
    # a nice, correct nested list.
    my $fake-pod = "=begin pod\n\n=config item :numbered\n\n";
    for @!toc -> $item {
        $fake-pod ~= "=for item{$item<level>} :numbered\n";
        $fake-pod ~= "L<#{$item<pod>}>\n\n";
    }
    $fake-pod ~= "\n=end pod\n";

    use MONKEY-SEE-NO-EVAL;
    my $pod = EVAL( $fake-pod ~ "\n\$=pod;" );

    $renderer.pod-to-html($pod);
    $renderer.render-end-tag( 'nav', :nl );

    return $renderer.accumulator;
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

method title {
    return $!title;
}

method subtitle {
    return $!subtitle;
}

multi method start (Pod::Heading $node) {
    my $level = min( $node.level, 6 );
    my $id = self.id-for($node);
    my $tag = 'h' ~ $level;

    self.render-start-tag( $tag, :id($id) );
    @!toc.push: {
        :level($level),
        :pod( $node.contents.map( { .contents[0] } ).join(q{}) ),
    };

    $!render-paras = False;

    return True;
}

multi method end (Pod::Heading $node) {
    my $level = min( $node.level, 6 );
    my $tag = 'h' ~ $level;

    $!render-paras = True;

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
            # XXX - this is impossible to do properly until
            # https://rt.perl.org/Ticket/Display.html?id=126651 is
            # fixed. Without that fix, we can't separate the term from the
            # definition.
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
        when (@semantic-meta-blocks, @semantic-blocks).flat.any {
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

    if $node.caption  {
        self.render-start-tag( 'caption' );
        $.accumulator ~= self.escape-html( $node.caption );
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

    @!footnotes.push( self.rendered-contents-of($node) );
}

method start-index-term (Pod::FormattingCode $node) {
    my $term = self!term-from-node($node)
        or return;
    my $id = 'index-' ~ self.id-for($term);
    $.accumulator ~= qq{<span id="$id">};
    %!index{$term} = $id;
}

method end-index-term (Pod::FormattingCode $node) {
    return unless self!term-from-node($node);
    $.accumulator ~= '</span>';
}

method !term-from-node (Pod::FormattingCode $node) {
    return $node.meta[0] || $.walker.text-contents-of($node);
}

method start-list (Int :$level, Bool :$numbered) {
    my $tag = $numbered ?? 'ol' !! 'ul';
    # This is a nested list, in which case we unclose to the <li> that
    # contains the nested list. We'll close it down below.
    if $.last-end-tag eq 'li' {
        $.accumulator.subst-mutate( rx{'</li>'\s*$}, q{} );
    }
    self.render-start-tag('li')
    if $.last-start-tag ~~ <ol ul>.any;
    self.render-start-tag( $tag, :nl );
}

multi method start (Pod::Item $node) {
    # If the last end tag was a list, that means it was the end of a
    # _nested_ list, in which case we need to close the <li> that we
    # unclosed up in start-list above. This corresponds to POD like this:
    #
    # =item1 Foo
    # =item2 Bar
    # =item1 Baz
    if $.last-end-tag ~~ <ol ul>.any {
        self.render-end-tag('li');
    }
    self.render-start-tag('li');
    return True;
}
multi method end (Pod::Item $node) {
    self.render-end-tag( 'li', :nl );
}

method end-list (Int :$level, Bool :$numbered) {
    my $tag = $numbered ?? 'ol' !! 'ul';
    # If the last end tag was a list, that means it was the end of a
    # _nested_ list, in which case we need to close the <li> that we
    # unclosed up in start-list above. This corresponds to POD like this:
    #
    # =item1 Foo
    # =item2 Bar
    if $.last-end-tag ~~ <ol ul>.any {
        self.render-end-tag('li');
    }
    self.render-end-tag( $tag, :nl );
}

multi method start (Pod::Raw $node) {
    if $node.target && lc $node.target eq 'html' {
        $.accumulator ~= $.walker.text-contents-of($node);
    }
    return False
}

method config (Pod::Config $node) {  }

method index {
    return %!index;
}

# vim: expandtab shiftwidth=4 ft=perl6
