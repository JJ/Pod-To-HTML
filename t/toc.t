use v6;
use Test;
use lib 'lib', 't/lib';;
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
    my $pth = Pod::To::HTML::Renderer.new( :title('My Title'), :subtitle('A Subtitle') );
    my $html = $pth.pod-to-html($=pod[$pod_i]);

    like(
        $html,
        rx:s{
            '<nav>'
            '<ol>'
                '<li>'
                    '<p>' '<a href="#Head1-0">Head1</a>' '</p>'
                    '<ol>'
                        '<li>'
                            '<p>' '<a href="#Subheading-1">Subheading</a>' '</p>'
                        '</li>'
                        '<li>'
                            '<p>' '<a href="#Another_Subheading-2">Another Subheading</a>' '</p>'
                        '</li>'
                    '</ol>'
                '</li>'
                '<li>'
                    '<p>' '<a href="#Back_to_the_top-3">Back to the top</a>' '</p>'
                '</li>'
            '</ol>'
            '</nav>'
        },
        'got expected html'
    );
}, 'table of contents rendering';

done-testing();
