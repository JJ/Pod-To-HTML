use v6;
use Test;
use lib 'lib', 't/lib';
use Pod::To::HTML::Renderer;

=begin pod

=head1 Head1

Some text here.

=head2 Subheading

More text.

=head2 Another Subheading

Yadda

=head1 Back to the top

Yadda yadda.

=end pod

my $pod_i = 0;

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx:s{
            '<nav>'
            '<ol>'
                '<li>'
                    '<a href="#Head1">Head1</a>'
                    '<ol>'
                        '<li>'
                            '<a href="#Subheading">Subheading</a>'
                        '</li>'
                        '<li>'
                            '<a href="#Another_Subheading">Another Subheading</a>'
                        '</li>'
                    '</ol>'
                '</li>'
                '<li>'
                    '<a href="#Back_to_the_top">Back to the top</a>'
                '</li>'
            '</ol>'
            '</nav>'
        },
        'got expected html'
    );
}, 'table of contents rendering';


=begin pod

=head1 Head1 has C<code>

=head1 Greater than - >

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
        $html,
        rx:s{
            '<nav>'
            '<ol>'
                '<li>'
                    '<a href="#Head1_has_C%3Ccode%3E">Head1 has <code>code</code></a>'
                '</li>'
                '<li>'
                    '<a href="#Greater_than_-_%3E">Greater than - &gt;</a>'
                '</li>'
            '</ol>'
            '</nav>'
        },
        'got expected html'
    );
}, 'headers with formatting code and bare > characters';

done-testing();
