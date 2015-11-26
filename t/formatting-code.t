use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML;

=begin pod

B<strong> text

=end pod

my $pod_i = 0;

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<strong>strong</strong>' \s+ 'text'},
         'html content'
    );
}, 'B<> code';

=begin pod

C<code> text

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<code>code</code>' \s+ 'text'},
         'html content'
    );
}, 'C<> code';

=begin pod

I<em> text

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<em>em</em>' \s+ 'text'},
         'html content'
    );
}, 'I<> code';

=begin pod

K<kbd> text

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<kbd>kbd</kbd>' \s+ 'text'},
         'html content'
    );
}, 'K<> code';

=begin pod

R<var> text

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<var>var</var>' \s+ 'text'},
         'html content'
    );
}, 'R<> code';


=begin pod

T<samp> text

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<samp>samp</samp>' \s+ 'text'},
         'html content'
    );
}, 'S<> code';

=begin pod

U<u> text

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<p>' \s* '<u>u</u>' \s+ 'text'},
         'html content'
    );
}, 'U<> code';

=begin pod

E<lt>tagE<gt> E<34> E<0x0027>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'&lt;tag&gt; &#34; &#39;'},
         'html content'
    );
}, 'multiple E<> codes';

=begin pod

D<POD> is Plain Old Documentation.

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{'<dfn>POD</dfn> is Plain Old Documentation.'},
         'html content'
    );
}, 'D<> code';


=begin pod

This first. Z<This is ignored. >But this is not.

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    unlike(
         $html,
         rx{'This is ignored. '},
         'html content does not contain contents of Z<>'
    );

    like(
         $html,
         rx{'This first. But this is not.'},
         'html content contains content before & after Z<>'
    );
}, 'Z<> code';

done-testing;
