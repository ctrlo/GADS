# GADS::Developer::Guide

## Setting up

The GADS Distribution is configured via `Makefile.PL`.

### Debian Linux

Set up your build tools.

`apt-get install build-essential`

Install `local::lib`.

`cpan local::lib`

Create a local lib dir.

`mkdir -p ~/perl5/lib/perl5`

Set your shell.

`eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"`

Run your `Makefile.PL` in bootstrap mode.

`perl Makefile.PL --bootstrap`

Run CPAN.

`cpan.`

Make.

`make test`
`make install`

