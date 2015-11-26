use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML;

=begin pod

This is main textN<And this is the first footnote.>.

This is more main body textN<More footnoting.>. And yet more.

=end pod

my $pth = Pod::To::HTML::Renderer.new;
my $html = $pth.pod-to-html($=pod[0]);

like(
    $html,
    rx{
        '<p>' \s* 'This is main text<sup>'
        '<a href="#footnote-1" id="footnote-ref-1">1</a></sup>.' \s* '</p>' \s*
        '<p>' \s* 'This is more main body text'
        '<sup><a href="#footnote-2" id="footnote-ref-2">2</a></sup>'
        '. And yet more.' \s* '</p>'
    },
    'html content contains non-footnote content in the expected spots'
);

like(
    $html,
    rx{
        '<aside>' \s* '<ol>' \s*
        '<li>' \s* '<a href="#footnote-ref-1" id="footnote-1">[↑]</a>' \s*
        'And this is the first footnote.' \s* '</li>' \s*
        '<li>' \s* '<a href="#footnote-ref-2" id="footnote-2">[↑]</a>' \s*
        'More footnoting.' \s* '</li>' \s*
        '</ol>' \s* '</aside>'
    },
    'html content contains footnotes'
);

done-testing;
