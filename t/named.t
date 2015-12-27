use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML::Renderer;

my $pod_i = 0;

=begin pod

Not nested.

=for nested
Nested 1.

=nested
Nested 2.

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<p>' 'Not nested.' '</p>'
             '<div class="nested">' '<p>'
             'Nested 1.' '</p>' '</div>'
             '<div class="nested">' '<p>'
             'Nested 2.' '</p>' '</div>'
           },
         'html content'
    );
}, '=for nested and =nested';

=begin pod

Not nested.

=begin nested

And nested.

    =begin nested

    Even more nested.

    =end nested

=end nested

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<p>' 'Not nested.' '</p>'
             '<div class="nested">' '<p>'
             'And nested.' '</p>'
             '<div class="nested">' '<p>'
             'Even more nested.' '</p>'
             '</div>' '</div>'
           },
         'html content'
    );
}, 'multiple nested blocks';

=begin pod

=for output
For output.

=output
Straight up =output.

=begin output

In an output block.

=end output

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<pre>For output.</pre>'
             '<pre>Straight up =output.</pre>'
             '<pre>In an output block.</pre>'
           },
         'html content'
    );
}, '=for output, =output, and output block';

=begin pod

=for para
For para.

=para
Straight up para.

=begin para

A para block is nothing special.

=end para

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<p>' 'For para.' '</p>'
             '<p>' 'Straight up para.' '</p>'
             '<p>' 'A para block is nothing special.' '</p>'
           },
         'html content'
    );
}, '=for para, =para, and para block';

=begin pod

=for Image
http://www.foo.com/foo.jpg

=Image
http://www.bar.com/bar.jpg

=begin Image

http://www.baz.com/baz.jpg

=end Image

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<img src="http://www.foo.com/foo.jpg">'
             '<img src="http://www.bar.com/bar.jpg">'
             '<img src="http://www.baz.com/baz.jpg">'
           },
         'html content'
    );
}, '=for Image, =Image, and Image block';

=begin pod

=for Html
<span>For html.</span>

=Html
<span>Straight up html.</span>

=begin Html

<span>Html block.</span>

=end Html

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<span>For html.</span>'
             '<span>Straight up html.</span>'
             '<span>Html block.</span>'
           },
         'html content'
    );
}, '=for Html, =Html, and Html block';

=begin pod

=for Xhtml
<span>For html.</span>

=Xhtml
<span>Straight up html.</span>

=begin Xhtml

<span>Html block.</span>

=end Xhtml

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<span>For html.</span>'
             '<span>Straight up html.</span>'
             '<span>Html block.</span>'
           },
         'html content'
    );
}, '=for Xhtml, =Xhtml, and Xhtml block';

=begin pod

=TITLE Title goes here

=SUBTITLE Subtitle goes here

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<title>Title goes here</title>'
             .+
             '<h1 class="title">Title goes here</h1>'
             '<h2 class="subtitle">Subtitle goes here</h2>'
           },
         'html content'
    );
}, '=TITLE and =SUBTITLE blocks';

subtest {
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

    for @semantic-meta-blocks -> $s {
        my $pod = EVAL(qq:to/POD/);
        =begin pod

        =$s block content for $s

        =end pod

        \$=pod[0];
        POD

        my $pth = Pod::To::HTML::Renderer.new;
        my $html = $pth.pod-to-html($pod);

        like(
            $html,
            rx:s{
                "<meta name=\"{$s.lc}\" value=\"block content for {$s}\">"
            },
            "meta tag for $s"
        );

        my $title-form = $s.split(/'-'/).map({ $_.lc.tc }).join(q{ });

        like(
            $html,
            rx:s{
                '<section>' '<h2>' "$title-form" '</h2>'
                '<p>' "block content for $s" '</p>'
                '</section>'
            },
            "section and h2 for $s"
        );
    }
}, 'semantic blocks that go in <meta> tags too';

subtest {
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

    for @semantic-blocks -> $s {
        my $pod = EVAL(qq:to/POD/);
        =begin pod

        =$s block content for $s

        =end pod

        \$=pod[0];
        POD

        my $pth = Pod::To::HTML::Renderer.new;
        my $html = $pth.pod-to-html($pod);

        unlike(
            $html,
            rx:s{
                "<meta name=\"{$s.lc}\" value=\"block content for {$s}\">"
            },
            "no meta tag for $s"
        );

        my $title-form = $s.split(/'-'/).map({ $_.lc.tc }).join(q{ });

        like(
            $html,
            rx:s{
                '<section>' '<h2>' "$title-form" '</h2>'
                '<p>' "block content for $s" '</p>'
                '</section>'
            },
            "section and h2 for $s"
        );
    }
}, 'semantic blocks that do not go in <meta> tags';

done-testing;
