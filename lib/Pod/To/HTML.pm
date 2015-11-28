unit class Pod::To::HTML;

use Pod::To::HTML::Renderer;

#| This method is required for perl6 --doc=HTML ...
method render($pod) {
    Pod::To::HTML::Renderer.new.pod-to-html($pod)
}

# vim: expandtab shiftwidth=4 ft=perl6
