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
         rx:s{
             '<table>'
             '<caption>My caption</caption>'
             '<thead>'
             '<tr>'
             '<th>Title</th>'
             '<th>Name</th>'
             '<th>Size</th>'
             '</tr>'
             '</thead>'
             '<tbody>'
             '<tr>'
             '<td>' '<p>' 'Captain' '</p>' '</td>'
             '<td>' '<p>' 'Jane' '</p>' '</td>'
             '<td>' '<p>' 'Medium' '</p>' '</td>'
             '</tr>'
             '<tr>'
             '<td>' '<p>' 'Clerk' '</p>' '</td>'
             '<td>' '<p>' 'Bob' '</p>' '</td>'
             '<td>' '<p>' 'Large' '</p>' '</td>'
             '</tr>'
             '</tbody>'
             '</table>'
           },
         'html content'
    );
}, 'table with caption and headers';

done-testing;
