use v6;
use Test;
use Pod::To::HTML;

plan 1;

# Covershttps://github.com/perl6/Pod-To-HTML/issues/37
#######
# NOTE: It's important for the test below that pod2html is NOT used
# before running the test, as doing so will hide the bug
#######

is-deeply node2html(
    Pod::FormattingCode.new: 
        :type<L>, :meta[], :config{}, :contents["Array"]
), '<a href="Array">Array</a>', 'no crash in node2html with L<>';
