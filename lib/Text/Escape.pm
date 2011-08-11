use v6;
module Text::Escape;

sub escape($str as Str, Str $how) is export {
    given $how.lc {
        when 'none'         { $str }
        when 'html'         { escape_str($str, &escape_html_char) }
        when 'uri' | 'url'  { escape_str($str, &escape_uri_char)  }
        default { fail "Don't know how to escape format $how yet" }
    }
}

sub escape_html_char(Str $c) returns Str {
    my %escapes = (
        q{<}    => '&lt;',
        q{>}    => '&gt;',
        q{&}    => '&amp;',
        q{"}    => '&quot;',
        q{'}    => '&#39;',
    );
    %escapes{$c} // $c;
}

sub escape_uri_char(Str $c) returns Str {
    return q{+} if $c eq q{ };

    my $allowed = 'abcdefghijklmnopqrstuvwxyz'
                ~ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                ~ '0123456789'
                ~ q{-_.!~*'()};

    return $c if defined $allowed.index($c);

    # TODO: each char should be UTF-8 encoded, then its bytes %-encoded
    return q{%} ~ ord($c).fmt('%x');
}

sub escape_str(Str $str, Callable $callback) returns Str {
    my $result = '';
    for ^$str.chars -> $index {
        $result ~= $callback($str.substr: $index, 1)
    }
    return $result;
}

# vim:ft=perl6
