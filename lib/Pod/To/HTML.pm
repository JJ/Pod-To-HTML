use URI::Escape;
use Pod::Walker;

#try require Term::ANSIColor <&colored>;
#if &colored.defined {
    #&colored = -> $t, $c { $t };
#}

sub colored($text, $how) {
    $text
}

class Pod::List is Pod::Block { };
multi sub pw-recurse($wc, Pod::List $node, $level) {
    $wc.pod-list(@*TEXT)
}

class Pod::To::HTML does Pod::Walker {
    has &.url-munge = -> $url { $url };
    has $!title;
    has $!subtitle;
    has @!meta;
    has @!indexes;
    has @!footnotes;
    has %.crossrefs;

    sub pod2html(|p) is export { Pod::To::HTML.new.render(|p) }

    sub visit($root, :&pre, :&post, :&assemble = -> *%{ Nil }) {
        my ($pre, $post);
        $pre = pre($root) if defined &pre;
        my @content = $root.?content.map: {visit $_, :&pre, :&post, :&assemble};
        $post = post($root, :@content) if defined &post;
        return assemble(:$pre, :$post, :@content, :node($root));
    }

    sub assemble-list-items(:@content, :$node, *% ) {
        my @current;
        my @result;
        my $found;
        for @content -> $c {
            if $c ~~ Pod::Item {
                @current.push: $c;
                $found = True;
            }
            elsif @current {
                @result.push: Pod::List.new(content => @current);
                @current = ();
                @result.push: $c;
            }
            else {
                @result.push: $c;
            }
        }
        @result.push: Pod::List.new(content => @current) if @current;
        @current = ();
        return $found ?? $node.clone(content => @result) !! $node;
    }

    #= Converts a Pod tree to a HTML document.
    multi method render(Pod::To::HTML:U: |a) returns Str { self.new.render(|a) }
    multi method render(Pod::To::HTML:D: $pod, :$head = '', :$header = '', :$footer = '', :$default-title) returns Str {
        #= Keep count of how many footnotes we've output.
        my Int $*done-notes = 0;
        my @body = $pod.map({visit $_, :assemble(&assemble-list-items)}).map({pod-walk(self, $_)});

        return qq:to/EOHTML/.trim;
            <!doctype html>
            <html>
            <head>
              <title>{ $!title // $default-title }</title>
              <meta charset="UTF-8" />
              <style>
                /* code gets the browser-default font
                 * kbd gets a slightly less common monospace font
                 * samp gets the hard pixelly fonts
                 */
                kbd \{ font-family: "Droid Sans Mono", "Luxi Mono", "Inconsolata", monospace }
                samp \{ font-family: "Terminus", "Courier", "Lucida Console", monospace }
                /* WHATWG HTML frowns on the use of <u> because it looks like a link,
                 * so we make it not look like one.
                 */
                u \{ text-decoration: none }
                .nested \{
                    margin-left: 3em;
                }
                // footnote things:
                aside, u \{ opacity: 0.7 }
                a[id^="fn-"]:target \{ background: #ff0 }
              </style>
              <link rel="stylesheet" href="http://perlcabal.org/syn/perl.css">
              $.do-metadata()
              $head
            </head>
            <body class="pod" id="___top">
                $header
                { "<h1 class='title'>{ $!title }</h1>"   if $!title.defined }
                { "<p class='subtitle'>{$!subtitle}</p>" if $!subtitle.defined }
                $.do-toc()
                @body.join()
                $.do-footnotes()
                $footer
            </body>
            </html>
            EOHTML
    }

    #= Returns accumulated metadata as a string of C«<meta>» tags
    method do-metadata {
        return @!meta.map({
            q[<meta name="] ~ .key ~ q[" value="] ~ .value.subst("\n","",:g) ~ q[" />]
        }).join("\n");
    }

    #= Turns accumulated headings into a nested-C«<ol>» table of contents
    method do-toc {
        my $r = qq[<nav class="indexgroup">\n];

        my $indent = q{ } x 2;
        my @opened;
        for @!indexes -> $p {
            my $lvl  = $p.key;
            my $head = $p.value;
            while @opened && @opened[*-1] > $lvl {
                $r ~= $indent x @opened - 1
                    ~ "</ol>\n";
                @opened.pop;
            }
            my $last = @opened[*-1] // 0;
            if $last < $lvl {
                $r ~= $indent x $last
                    ~ qq[<ol class="indexList indexList{$lvl}">\n];
                @opened.push($lvl);
            }
            $r ~= $indent x $lvl
                ~ qq[<li class="indexItem indexItem{$lvl}">]
                ~ qq[<a href="#{$head<uri>}">{$head<html>}</a></li>\n];
        }
        for ^@opened {
            $r ~= $indent x @opened - 1 - $^left
                ~ "</ol>\n";
        }

        return $r ~ '</nav>';
    }

    #= Flushes accumulated footnotes since last call. The idea here is that we can stick calls to this
    #  before each C«</section>» tag (once we have those per-header) and have notes that are visually
    #  and semantically attached to the section.
    method do-footnotes {
        return '' unless @!footnotes;

        my Int $current-note = $*done-notes + 1;
        my $notes = @!footnotes.kv.map(-> $k, $v {
                        my $num = $k + $current-note;
                        qq{<li><a href="#fn-ref-$num" id="fn-$num">[↑]</a> $v </li>\n}
                    }).join;

        $*done-notes += @!footnotes;
        @!footnotes = ();

        return qq[<aside><ol start="$current-note">\n]
             ~ $notes
             ~ qq[</ol></aside>\n];
    }

    #= block level or below
    #proto sub node2html(|) returns Str is export {*}
    method pod-default (@text) {
        @text # XXX content-inline
    }

    method pod-declarator (@text, $wherefore) {
        given $wherefore {
            when Sub {
                "<article>\n",
                    '<code>',
                        $wherefore.name, $wherefore.signature.perl,
                    "</code>:\n",
                    @text,
                "\n</article>\n";
            }
            default {
                note "I don't know what {$wherefore.perl} is" if $!debug;
                $wherefore.perl, ': ', @text
            }
        }
    }

    method pod-code (@text) {
        '<pre>', @text, "</pre>\n" # XXX inline-content
    }

    method pod-comment (@text) {
        ''
    }

    method pod-named (@text, $name, :%config) {
        given $name {
            when 'config' { return '' }
            when 'nested' {
                qq[<div class="nested">\n], @text, qq[\n</div>\n];
            }
            when 'output' { "<pre>\n", @text, "</pre>\n"; } # inline-content
            when 'pod'  {
                %config<class>
                    ?? (qq[<span class=[%config<class>]>\n], @text, qq[</span>\n])
                    !! @text
            }
            when 'para' { @text }
            when 'defn' { "@text[0]\n", @text[1..*-1] }
            when 'Image' {
                note "Image block, got @text.perl()";
                my $url;
                #if $node.content == 1 {
                #    my $n = $node.content[0];
                #    if $n ~~ Str {
                #        $url = $n;
                #    }
                #    elsif ($n ~~ Pod::Block::Para) &&  $n.content == 1 {
                #        $url = $n.content[0] if $n.content[0] ~~ Str;
                #    }
                #}
                unless $url.defined {
                    die "Found an Image block, but don't know how to extract the image URL :(";
                }

                qq[<img src="$url" />]
            }
            when 'Xhtml' | 'Html' {
                unescape_html [~] @text
            }
            when 'TITLE' {
                $!title = de-tag [~] @text;
                ''
            }
            when 'SUBTITLE' {
                $!subtitle = [~] @text;
                ''
            }
            when any <VERSION DESCRIPTION AUTHOR COPYRIGHT SUMMARY> {
                @!meta.push: Pair.new(
                    key => escape_html($name.lc),
                    value => de-tag [~] @text # XXX text-content
                );
                proceed;
            }
            default {
                "<section>",
                    "<h1>", $name, "</h1>\n",
                    @text,
                "</section>\n"
            }
        }
    }

    method pod-para (@text) {
        '<p>', @text, "</p>\n"; # XXX inline-content
    }
    =begin inline
    method pod-default (@text) {
        node2text(@text);
    }

    method pod-para (@text) {
        return node2inline(@text);
    }

    multi sub node2inline(Positional $node) {
        return $node.map({ node2inline($_) }).join;
    }

    multi sub node2inline(Str $node) {
        return escape_html($node);
    }
    =end inline

    method pod-table (@rows, %config, @headers) {
        my @r = '<table>';

        if %config<caption> -> $caption {
            @r.push("<caption>", $caption, "</caption>");
        }

        if @headers {
            @r.push(
                '<thead><tr>',
                @headers.map("<th>" ~ * ~ "</th>"),
                '</tr></thead>'
            );
        }

        @r.push(
            '<tbody>',
            @rows.map(-> @row {
                '<tr>',
                @row.map("<td>" ~ * ~ "</td>"),
                '</tr>'
            }),
            '</tbody>',
            '</table>'
        );

        return @r.join("\n");
    }

    method pod-config ($type, %config) {
        return '';
    }

    # TODO: would like some way to wrap these and the following content in a <section>; this might be
    # the same way we get lists working...
    method pod-heading (@text, $level) {
        my $lvl = min($level, 6); #= HTML only has 6 levels of numbered headings
        my %escaped = (
            id => escape_id(unescape_html(de-tag(@text.join))), # XXX rawtext-content
            html => de-tag(@text.join), # XXX inline-content
        );

        %escaped<uri> = uri_escape %escaped<id>;

        @!indexes.push: Pair.new(key => $lvl, value => %escaped);

        return sprintf('<h%d id="%s">', $lvl, %escaped<id>)
                    ~ qq[<a class="u" href="#___top" title="go to top of document">]
                        ~ %escaped<html>
                    ~ qq[</a>]
                ~ qq[</h{$lvl}>\n];
    }

    # FIXME
    method pod-list (@text) {
        '<ul>', @text, "</ul>\n";
    }
    method pod-item (@text, $level) {
        '<li>', @text, "</li>\n";
    }

    method pod-plain ($text) {
        escape_html $text
    }

    method pod-fcode (@text, $type, @meta) {
        my %basic-html = (
            B => 'strong',  #= Basis
            C => 'code',    #= Code
            I => 'em',      #= Important
            K => 'kbd',     #= Keyboard
            R => 'var',     #= Replaceable
            T => 'samp',    #= Terminal
            U => 'u',       #= Unusual
        );

        given $type {
            when any(%basic-html.keys) { # XXX inline-content
                "<%basic-html{$_}>", @text, "</%basic-html{$_}>"
            }

            #= Escape
            when 'E' {
                @meta.map({
                    when Int { "&#$_;" }
                    when Str { "&$_;"  }
                }).join
            }

            #= Note
            when 'N' {
                @!footnotes.push: [~] @text; # XXX inline-content
                my $id = $*done-notes + @!footnotes;

                qq{<a href="#fn-$id" id="fn-ref-$id" class="footnote">[$id]</a>}
            }

            #= Links
            when 'L' {
                my $text = [~] @text; # XXX inline-content
                my $url  = @meta[0] // [~] @text; # XXX text-content

                # if we have an internal-only link, strip the # from the text.
                if $text ~~ /^'#'/ {
                    $text = $/.postmatch
                }

                $url = self.url(unescape_html($url));
                if $url ~~ /^'#'/ {
                    $url = '#' ~ uri_escape( escape_id($/.postmatch) )
                }

                qq[<a href="$url">], $text, q[</a>]
            }

            # zero-width comment
            when 'Z' { '' }

            when 'D' {
                # TODO memorise these definitions (in $node.meta) and display them properly
                my $text = [~] @text; # XXX inline-content
                qq[<defn>$text</defn>]
            }

            when 'X' {
                # TODO do something with the crossrefs
                my $text = [~] @text; # XXX inline-content
                my @indices = @meta;
                # my @indices = $defns.split(/\s*';'\s*/).map:
                #     { .split(/\s*','\s*/).join("--") }
                %!crossrefs{$_} = $text for @indices;

                qq[<span name="{@indices}">$text\</span>]
            }
            # Stuff I haven't figured out yet
            default {
                qq[<kbd class="pod2html-todo">$type()&lt;], @text, q[&gt;</kbd>]; # XXX inline-content
            }
        }
    }
}

sub escape_html(Str $str) returns Str {
    return $str unless $str ~~ /<[&<>"']>/;

    $str.trans( [ q{&},     q{<},    q{>},    q{"},      q{'}     ] =>
                [ q{&amp;}, q{&lt;}, q{&gt;}, q{&quot;}, q{&#39;} ] );
}

sub unescape_html(Str $str) returns Str {
    return $str unless $str ~~ /<[&<>"']>/;

    $str.trans( [ rx{'&amp;'}, rx{'&lt;'}, rx{'&gt;'}, rx{'&quot;'}, rx{'&#39;'} ] =>
                [ q{&},        q{<},       q{>},       q{"},         q{'}        ] );
}

sub de-tag(Str $str) returns Str {
    return $str unless $str ~~ /'<'/;

    $str.subst(/'<'.*?'>'\s*/, '', :g);
}

sub escape_id ($id) {
    $id.subst(/\s+/, '_', :g);
}
