use Test;
use Pod::To::HTML;
plan 3;

=begin pod
X<|behavior> L<http://www.doesnt.get.rendered.com>
=end pod

my $r = pod2html $=pod, :url({ $_ });
ok $r ~~ m/'href="http://www.doesnt.get.rendered.com"'/;

=begin pod

When indexing X<an item> the X<X format> is used.

It is possible to index X<an item> in repeated places.
=end pod

$r = node2html $=pod[1];

like $r, /
    'When indexing'
    \s* '<a name="index-entry-an_item">'
    \s* '<span ' .* '>an item</span>'
    .+ 'the'
    .+ '<span ' .+ '>X format</span>'
    .+ 'to index'
    .+ '<span' .+ '>an item</span>'
    .+ 'in repeated places.'
    /, 'X format in text';

=begin pod

When indexing X<an item|Define an item> another text can be used for the index.

It is possible to index X<hierarchical items|defining, a term>with hierarchical levels.

And then index the X<same place|Same; Place> with different index entries.
=end pod

$r = node2html $=pod[2];
like $r, /
    'When indexing <a name="index-entry-Define_an_item-an_item">'
    .* '<span' .+ '>an item</span>'
    .+ 'to index ' .+ 'index-entry-defining__a_term-hierarchical_items' .+ '<span' .+ '>hierarchical items</span>'
    .+ 'index the ' .+ '>same place</span>'
    /,  'Text with indexed items correct';
