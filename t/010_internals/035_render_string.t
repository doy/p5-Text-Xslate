#!perl
use strict;
use warnings;
use Test::More;

use Text::Xslate;

BEGIN {
    package Text::Xslate::Syntax::Custom;
    use Any::Moose;
    extends 'Text::Xslate::Parser';

    sub init_symbols {
        my $self = shift;

        $self->SUPER::init_symbols(@_);

        $self->symbol('render_string')->set_nud($self->can('nud_render_string'));
    }

    sub nud_render_string {
        my $self = shift;
        my ($symbol) = @_;

        $self->advance('(');
        my $expr = $self->expression(0);
        $self->advance(')');

        return $symbol->clone(arity => 'render_string', first => $expr),
    }

    package Text::Xslate::Compiler::Custom;
    use Any::Moose;
    extends 'Text::Xslate::Compiler';

    sub _generate_render_string {
        my $self = shift;
        my ($node) = @_;

        return (
            $self->compile_ast($node->first),
            $self->opcode('render_string'),
        );
    }

    package Text::Xslate::Custom;
    use base 'Text::Xslate';

    sub options {
        my $class = shift;

        my $options = $class->SUPER::options(@_);

        $options->{compiler} = 'Text::Xslate::Compiler::Custom';
        $options->{syntax}   = 'Custom';

        return $options;
    }
}

my $tx = Text::Xslate::Custom->new;

is(
    $tx->render_string(
        ': if render_string($a) == "foo" { "yes" } else { "no (" ~ render_string($a) ~ ")" }',
        { a => '<: "f" ~ $b :>', b => 'oo' },
    ),
    'yes',
    "render_string works"
);

done_testing;
