use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML::Renderer;

# The doc/Language/classtut.pod file from the doc site triggered this bug,
# which I reduced down to X<> followed by L<>. The X<> code has to be of the
# form X<|text> with no text on the LHS of the pipe (|).

=begin pod

X<|foo>
L<bar> link.

=end pod

my $pth = Pod::To::HTML::Renderer.new;
my $html;
lives-ok { $html = $pth.pod-to-html($=pod[0]) },
    'bug parsing X<|foo> followed by L<>';

if $html {
    like(
        $html,
        rx:s{
            '<a href="bar">bar</a> link.'
        },
        'html has expected content'
    );
}

done-testing;
