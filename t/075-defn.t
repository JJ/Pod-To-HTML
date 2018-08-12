#!perl6

use Test; 
use Pod::To::HTML;

plan 1;

=begin pod

=defn  MAD
Affected with a high degree of intellectual independence.

=defn  MEEKNESS
Uncommon patience in planning a revenge that is worth while.

=defn MORAL
Conforming to a local and mutable standard of right.
Having the quality of general expediency.

=end pod


my $html = pod2html($=pod[0]);

ok $html ~~ ms[[
'<dl><dt>MAD</dt><dd>'
  '<p>Affected with a high degree of intellectual independence.</p>'
'</dd></dl>'
'<dl><dt>MEEKNESS</dt><dd>'
  '<p>Uncommon patience in planning a revenge that is worth while.</p>'
'</dd></dl>'
'<dl><dt>MORAL</dt><dd>'
'<p>Conforming to a local and mutable standard of right. Having the quality of general expediency.</p>'
'</dd></dl>'
]], 'generated html for =defn';
