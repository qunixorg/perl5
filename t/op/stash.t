#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
}

require "./test.pl";

plan( tests => 8 );

# Used to segfault (bug #15479)
fresh_perl_is(
    '%:: = ""',
    'Odd number of elements in hash assignment at - line 1.',
    { switches => [ '-w' ] },
    'delete $::{STDERR} and print a warning',
);

# Used to segfault
fresh_perl_is(
    'BEGIN { $::{"X::"} = 2 }',
    '',
    { switches => [ '-w' ] },
    q(Insert a non-GV in a stash, under warnings 'once'),
);

ok( !defined %oedipa::maas::, q(stashes aren't defined if not used) );
ok( !defined %{"oedipa::maas::"}, q(- work with hard refs too) );

ok( defined %tyrone::slothrop::, q(stashes are defined if seen at compile time) );
ok( defined %{"tyrone::slothrop::"}, q(- work with hard refs too) );

ok( defined %bongo::shaftsbury::, q(stashes are defined if a var is seen at compile time) );
ok( defined %{"bongo::shaftsbury::"}, q(- work with hard refs too) );

package tyrone::slothrop;
$bongo::shaftsbury::scalar = 1;
