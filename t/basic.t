use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML::Renderer;

=begin pod
=head1 Head1

Some text here.

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new( :title('My Title'), :subtitle('A Subtitle') );
    my $html = $pth.pod-to-html($=pod);

    like(
        $html,
        rx:s{'<head>' '<title>My Title</title>'},
        'default head section contains title passed to constructor'
    );

    like(
        $html,
        rx{'<head>' .+ '<style>' .+ 'kbd' .+ '</style>' .+ '</head>'},
        'default head section contains default inline styles'
    );

    like(
        $html,
        rx:s{'<h1 class="title">' 'My Title' '</h1>'},
        q{title passed to constructor is rendered as <h1> with a class of "title"}
    );

    like(
        $html,
        rx:s{'<h2 class="subtitle">' 'A Subtitle' '</h2>'},
        q{subtitle passed to constructor is rendered as <h2> with a class of "subtitle"}
    );

    like(
        $html,
        rx:s{'<h1 id="Head1">' 'Head1' '</h1>'},
        'html includes =head1 content with <h1> that has an id attribute'
    );
    like(
        $html,
        rx:s{'<p>' 'Some text here.' '</p>'},
        'html includes paragraph text'
    );
}, 'basic HTML with title and subtitle passed to constructor';

subtest {
    my @html;
    for 0..2 {
        @html.append: Pod::To::HTML::Renderer.new.pod-to-html($=pod);
    }

    for (0..2).combinations(2) -> @combo {
        my $first = @combo[0];
        my $second = @combo[1];
        is(
            @html[$first],
            @html[$second],
            "iteration $first and $second are identical"
        );
    }
}, 'pod-to-html produces the same output each time it is run on the same pod';

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod);

    unlike(
        $html,
        rx:s{'<head>' '<title>My Title</title>'},
        'default head section does not contain a title'
    );

    like(
        $html,
        rx:s{'<head>' '<title></title>'},
        'default head section contains empty title tag'
    );

    unlike(
        $html,
        rx{'<h1 class="title">'},
        q{body does not contain an <h1> with a class of "title"}
    );

    unlike(
        $html,
        rx{'<h2 class="subtitle">'},
        q{body does not contain an <h2> with a class of "subtitle"}
    );
}, 'no title or subtitle passed to constructor';


subtest {
    my $pth = Pod::To::HTML::Renderer.new( :title('Contains >'), :subtitle('Contains <') );
    my $html = $pth.pod-to-html($=pod);

    like(
        $html,
        rx:s{'<head>' '<title>Contains &gt;</title>'},
        'title is escaped in title tag'
    );

    like(
        $html,
        rx:s{'<h1 class="title">Contains &gt;</h1>'},
        'title is escaped in h1 tag'
    );

    like(
        $html,
        rx:s{'<h2 class="subtitle">Contains &lt;</h2>'},
        'subtitle is escaped in h2 tag'
    );
}, 'title and subtitle with characters that need to be HTML escaped';

done-testing;
