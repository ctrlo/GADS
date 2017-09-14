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

## Developing

### Sass

We use [Sass](http://sass-lang.com) to manage our styling and generate our final CSS.

#### Editing stylesheets

Sass stylesheets live in `./sass`.

#### Live updating stylesheets

We use [NPM](https://npmjs.org) to manage our autoconversion of SASS -> CSS. Use `npm run watch` to start the watcher.

### Javascript

The main application JS sits in `public/js/linkspace.js`. It's a classic style library, with some page-specific code
where necessary.

