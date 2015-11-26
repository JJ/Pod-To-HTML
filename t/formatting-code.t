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
         rx:s{'<p>' '<strong>strong</strong>' 'text'},
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
         rx:s{'<p>' '<code>code</code>' 'text'},
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
         rx:s{'<p>' '<em>em</em>' 'text'},
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
         rx:s{'<p>' '<kbd>kbd</kbd>' 'text'},
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
         rx:s{'<p>' '<var>var</var>' 'text'},
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
         rx:s{'<p>' '<samp>samp</samp>' 'text'},
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
         rx:s{'<p>' '<u>u</u>' 'text'},
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
         rx:s{'&lt;tag&gt; &#34; &#39;'},
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
         rx:s{'<dfn>POD</dfn> is Plain Old Documentation.'},
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
         rx:s{'This is ignored. '},
         'html content does not contain contents of Z<>'
    );

    like(
         $html,
         rx:s{'This first. But this is not.'},
         'html content contains content before & after Z<>'
    );
}, 'Z<> code';

done-testing;
