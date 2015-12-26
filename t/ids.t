use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML::Renderer;

=begin pod

=head1 Head1 with spaces

Link to L<#Head1 with spaces>

=head1 Head1 with C<pod>

Link to L<#Head1 with C<pod>>

=head1 Head1 with B<nested C<codes>>

Link to L<#Head1 with B<nested C<codes>>>

=end pod

my $pod_i = 0;

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i]);

    like(
        $html,
        rx:s{
            '<h1 id="Head1_with_spaces">Head1 with spaces</h1>'
            .*
            '<p>'
            'Link to <a href="#Head1_with_spaces">Head1 with spaces</a>'
            '</p>'
            .*
            '<h1 id="Head1_with_C&lt;pod&gt;">Head1 with <code>pod</code></h1>'
            .*
            '<p>'
            'Link to <a href="#Head1_with_C%3Cpod%3E">Head1 with <code>pod</code></a>'
            '</p>'
            .*
            '<h1 id="Head1_with_B&lt;nested_C&lt;codes&gt;&gt;">Head1 with <strong>nested <code>codes</code></strong></h1>'
            .*
            '<p>'
            'Link to <a href="#Head1_with_B%3Cnested_C%3Ccodes%3E%3E">Head1 with <strong>nested <code>codes</code></strong></a>'
            '</p>'
        },
        'expected html'
    );
}, 'ids and links for heading with spaces and pod in their content';

done-testing;
