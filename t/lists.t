use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML;

my $pod_i = 0;

=begin pod

=item Foo

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<body' .+? '>'
             '<ul>'
             '<li>' '<p>' 'Foo' '</p>' '</li>'
             '</ul>'
             '</body>'
         },
         'html content'
    );
}, 'single item list';

=begin pod

=item Foo
=item Bar

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<body' .+? '>'
             '<ul>'
             '<li>' '<p>' 'Foo' '</p>' '</li>'
             '<li>' '<p>' 'Bar' '</p>' '</li>'
             '</ul>'
             '</body>'
         },
         'html content'
    );
}, 'two item list';

=begin pod

=item1 Foo1
=item1 Bar1
=item2 Baz2
=item1 Quux1

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<body' .+? '>'
             '<ul>'
               '<li>' '<p>' 'Foo1' '</p>' '</li>'
               '<li>'
                 '<p>' 'Bar1' '</p>'
                 '<ul>'
                   '<li>' '<p>' 'Baz2' '</p>' '</li>'
                 '</ul>'
               '</li>'
               '<li>' '<p>' 'Quux1' '</p>' '</li>'
             '</ul>'
             '</body>'
         },
         'html content'
    );
}, 'nested list with 2 levels';

=begin pod

=item2 Foo2
=item2 Bar2
=item3 Baz3
=item2 Quux2

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx:s{
             '<body' .+? '>'
             '<ul>'
               '<li>'
                 '<ul>'
                   '<li>' '<p>' 'Foo2' '</p>' '</li>'
                   '<li>'
                     '<p>' 'Bar2' '</p>'
                     '<ul>'
                       '<li>' '<p>' 'Baz3' '</p>' '</li>'
                     '</ul>'
                   '</li>'
                   '<li>' '<p>' 'Quux2' '</p>' '</li>'
                 '</ul>'
               '</li>'
             '</ul>'
             '</body>'
         },
         'html content'
    );
}, 'nested list with 2 levels starting at level 2';

done-testing;
