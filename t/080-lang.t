use v6;
use Test;
use Pod::To::HTML;

plan 2;

=begin pod

Je suis Napoleon!

=end pod

like pod2html($=pod), /'<html lang="en">'/, 'default lang is English';
like pod2html($=pod, :lang<fr>), /'<html lang="fr">'/, 'custom lang';
