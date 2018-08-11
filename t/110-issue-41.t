use Test;
use Pod::To::HTML;
plan 2;

=begin pod
=head2 Rendering Perl 6 with no-break space

Nothing to see here

=head2 What's wrong with this rendering?

Nothing to see here either
=end pod

my $r = pod2html $=pod;

ok $r ~~ m/\#What\'s_wrong/;
ok $r ~~ m/\#Rendering_Perl_6/;
