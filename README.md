[![Actions Status](https://github.com/lizmat/Version-Conan/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Version-Conan/actions) [![Actions Status](https://github.com/lizmat/Version-Conan/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Version-Conan/actions) [![Actions Status](https://github.com/lizmat/Version-Conan/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Version-Conan/actions)

NAME
====

Version::Conan - Implement Conan Version logic

SYNOPSIS
========

```raku
use Version::Conan;

my $left  = Version::Conan.new("1.0");
my $right = Version::Conan.new("1.a");

# method interface
say $left.cmp($right);  # Less
say $left."<"($right);  # True

# infix interface
say $left cmp $right;  # Less
say $left < $right;    # True
```

DESCRIPTION
===========

The `Version::Conan` distribution provides a `Version::Conan` class which encapsulates the logic for creating a `Version`-like object with semantics matching the [Conan version of Semantic Versioning](https://docs.conan.io/2/tutorial/versioning/version_ranges.html#semantic-versioning).

Conan extends the semver specification to any number of digits, and also allows to include lowercase letters in it. Note that the semver standard does not apply any ordering to build-date, but Conan does, with the same logic that is used to order the main version and the pre-releases.

INSTANTIATION
=============

```raku
my $sv = Version::Conan.new("1.2.3-pre.release+build.data");
```

The basic instantion of a `Version::Conan` object is done with the `new` method, taking the version string as a positional argument.

ACCESSORS
=========

major
-----

```raku
my $sv = Version::Conan.new("1.2.3");
say $sv.major;  # 1
```

Returns the major version value.

minor
-----

```raku
my $sv = Version::Conan.new("1.2.3");
say $sv.minor;  # 2
```

Returns the minor version value.

patch
-----

```raku
my $sv = Version::Conan.new("1.2.3");
say $sv.patch;  # 3
```

Returns the patch value.

parts
-----

```raku
my $sv = Version::Conan.new("1.2.3.4");
say $sv.parts;  # (1 2 3 4)
```

Returns the constituent parts of the version specification.

pre-release
-----------

```raku
my $sv = Version::Conan.new("1.2.3-foo.bar");
say $sv.pre-release;  # (foo bar)
```

Returns a `List` with the pre-release tokens.

build
-----

```raku
my $sv = Version::Conan.new("1.2.3+build.data");
say $sv.build;  # (build data)
```

Returns a `List` with the build tokens.

OTHER METHODS
=============

cmp
---

```raku
my $left  = Version::Conan.new("1.0");
my $right = Version::Conan.new("1.a");

say $left.cmp($left);   # Same
say $left.cmp($right);  # Less
say $right.cmp($left);  # More
```

The `cmp` method returns the `Order` of a comparison of the invocant and the positional argument, which is either `Less`, `Same`, or `More`. This method is the workhorse for comparisons.

eqv
---

```raku
my $left  = Version::Conan.new("1.0.0");
my $right = Version::Conan.new("1.0.0");

say $left.eqv($right);  # True
```

The `eqv` method returns whether the internal state of two `Version::Conan` objects is identical.

== != < <= > >=
---------------

```raku
my $left  = Version::Conan.new("1.2.3");
my $right = Version::Conan.new("1.2.4");

say $left."=="($left);  # True
say $left."<"($right);  # True
```

These oddly named methods provide the same functionality as their infix counterparts. Please note that you **must** use the `"xx"()` syntax, because otherwise the Raku compiler will assume you've made a syntax error.

EXPORTED INFIXES
================

The following `infix` candidates handling `Version::Conan` are exported:

  * cmp (returns `Order`)

  * eqv == != < <= > >= (returns `Bool`)

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Version-Conan . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

