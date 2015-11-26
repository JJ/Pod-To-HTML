use v6;
use Test;
use lib 'lib', 't/lib';;
use Pod::To::HTML;

my $pod_i = 0;

=begin pod

=begin table :caption('My caption')

    Title    | Name   | Size
    ==========================
    Captain  | Jane   | Medium
    Clerk    | Bob    | Large

=end table

=end pod

subtest {
    my $pth = Pod::To::HTML::Renderer.new;
    my $html = $pth.pod-to-html($=pod[$pod_i++]);

    like(
         $html,
         rx{
             '<table>' \s*
             '<caption>My caption</caption>' \s*
             '<thead>' \s*
             '<tr>' \s*
             '<th>Title</th>' \s*
             '<th>Name</th>' \s*
             '<th>Size</th>' \s*
             '</tr>' \s*
             '</thead>' \s*
             '<tbody>' \s*
             '<tr>' \s*
             '<td>' \s* '<p>' \s* 'Captain' \s* '</p>' \s* '</td>' \s*
             '<td>' \s* '<p>' \s* 'Jane' \s* '</p>' \s* '</td>' \s*
             '<td>' \s* '<p>' \s* 'Medium' \s* '</p>' \s* '</td>' \s*
             '</tr>' \s*
             '<tr>' \s*
             '<td>' \s* '<p>' \s* 'Clerk' \s* '</p>' \s* '</td>' \s*
             '<td>' \s* '<p>' \s* 'Bob' \s* '</p>' \s* '</td>' \s*
             '<td>' \s* '<p>' \s* 'Large' \s* '</p>' \s* '</td>' \s*
             '</tr>' \s*
             '</tbody>' \s*
             '</table>'
           },
         'html content'
    );
}, 'table with caption and headers';

done-testing;
