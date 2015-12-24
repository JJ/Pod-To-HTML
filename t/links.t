use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML::Renderer;

=begin pod

L<doc:Pod::To::HTML>

L<Pod::To::HTML docs|doc:Pod::To::HTML>

L<doc:Pod::To::HTML#SYNOPSIS>

L<doc:#INTERNAL1>

L<#INTERNAL2>

L<Internal section 1|doc:#INTERNAL1>

L<Internal section 2|#INTERNAL2>

=end pod

my $pod_i = 0;

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="http://modules.perl6.org/dist/Pod::To::HTML">Pod::To::HTML</a>'},
        'simple doc link'
    );

    like(
        $html,
        rx{'<a href="http://modules.perl6.org/dist/Pod::To::HTML">Pod::To::HTML docs</a>'},
        'doc link with link text'
    );

    like(
        $html,
        rx{'<a href="http://modules.perl6.org/dist/Pod::To::HTML#SYNOPSIS">SYNOPSIS in Pod::To::HTML</a>'},
        'doc link with anchor'
    );

    like(
        $html,
        rx{'<a href="#INTERNAL1">INTERNAL1</a>'},
        'simple internal doc link with doc:'
    );

    like(
        $html,
        rx{'<a href="#INTERNAL2">INTERNAL2</a>'},
        'simple internal doc link without doc:'
    );

    like(
        $html,
        rx{'<a href="#INTERNAL1">Internal section 1</a>'},
        'internal doc link with link text and doc:'
    );

    like(
        $html,
        rx{'<a href="#INTERNAL2">Internal section 2</a>'},
        'internal doc link with link text and without doc:'
    );
}, 'doc links';

=begin pod

L<defn:lexiphania>

L<the word lexiphania|defn:lexiphania>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="#lexiphania">lexiphania</a>'},
        'simple defn link'
    );

    like(
        $html,
        rx{'<a href="#lexiphania">the word lexiphania</a>'},
        'defn link with link text'
    );
}, 'defn links';

=begin pod

L<isbn:978-0-425-25656-5>

L<issn:1087-903X>

L<The Rhesus Chart|isbn:978-0-425-25656-5>

L<The Perl Journal|issn:1087-903X>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="https://www.worldcat.org/q=isbn%3A978-0-425-25656-5">ISBN978-0-425-25656-5</a>'},
        'simple isbn link'
    );

    like(
        $html,
        rx{'<a href="https://www.worldcat.org/q=n2%3A1087-903X">ISSN1087-903X</a>'},
        'simple issn link'
    );

    like(
        $html,
        rx{'<a href="https://www.worldcat.org/q=isbn%3A978-0-425-25656-5">The Rhesus Chart</a>'},
        'isbn link with link text'
    );

    like(
        $html,
        rx{'<a href="https://www.worldcat.org/q=n2%3A1087-903X">The Perl Journal</a>'},
        'issn link with link text'
    );
}, 'isbn and issn links';

=begin pod

L<man:find(1)>

L<find man page|man:find(1)>

L<man:find(1)#DESCRIPTION>

L<find man page|man:find(1)#DESCRIPTION>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="http://man7.org/linux/man-pages/man1/find.1.html">find(1)</a>'},
        'simple man page link'
    );

    like(
        $html,
        rx{'<a href="http://man7.org/linux/man-pages/man1/find.1.html">find man page</a>'},
        'man page link with link text'
    );

    like(
        $html,
        rx{'<a href="http://man7.org/linux/man-pages/man1/find.1.html#DESCRIPTION">DESCRIPTION in find(1)</a>'},
        'simple man page link with anchor'
    );

    like(
        $html,
        rx{'<a href="http://man7.org/linux/man-pages/man1/find.1.html#DESCRIPTION">find man page</a>'},
        'man page link with link text and anchor'
    );
}, 'man page links';

=begin pod

L<file:/etc/passwd>

L<password file in /etc|file:/etc/passwd>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="file:///etc/passwd">/etc/passwd</a>'},
        'simple file link'
    );

    like(
        $html,
        rx{'<a href="file:///etc/passwd">password file in /etc</a>'},
        'file link with link text'
    );
}, 'file links';

=begin pod

L<mailto:autarch@urth.org>

L<mail to Dave|mailto:autarch@urth.org>

L<http://www.perl6.org>

L<the Perl 6 site|http://www.perl6.org>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="mailto:autarch@urth.org">autarch@urth.org</a>'},
        'simple mailto link'
    );

    like(
        $html,
        rx{'<a href="mailto:autarch@urth.org">mail to Dave</a>'},
        'mailto link with link text'
    );

    like(
        $html,
        rx{'<a href="http://www.perl6.org">http://www.perl6.org</a>'},
        'simple http link'
    );

    like(
        $html,
        rx{'<a href="http://www.perl6.org">the Perl 6 site</a>'},
        'http link with link text'
    );
}, 'mailto and http links';

=begin pod

L<my>

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx{'<a href="my">my</a>'},
        'simple text in link should be interpreted as relative path'
    );
}, 'link to arbitrary text - L<my>';

# Regression tests - this link was not being rendered at one point in time.
=begin pod
X<|behavior> L<http://www.doesnt.get.rendered.com>
=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{'href="http://www.doesnt.get.rendered.com"'},
         'html content contains content link after X<>'
    );
}, 'X<> followed by L<>';

done-testing;
