#- Version::Conan -----------------------------------------------------------
class Version::Conan:ver<0.0.1>:auth<zef:lizmat> {
    has @.version     is List;
    has @.pre-release is List;
    has @.build       is List;

    multi method new(Version::Conan: Str:D $spec is copy) {
        my %args = %_;

        $spec .= substr(1) if $spec.starts-with("v");  # semver 1.0 compat

        # Generic pre-release / build parsing logic
        my sub parse($type, $index? --> Nil) {
            my $target;
            with $index {
                $target := $spec.substr($index + 1);
                $spec = $spec.substr(0, $index);
            }
            else {
                $target = $spec;
            }

            die "$type.tc() info contains illegal characters"
              if $target.contains(/ <-[a..z 0..9 .]> /);
            my @parts is List = $target.split(".");
            die "$type.tc() info may not contain empty elements"
              with @parts.first(* eq '');
            die "$type.tc() info may not contain leading zeroes"
              if @parts.first: { .starts-with("0") && .Int }

            %args{$type} := @parts.map({ .Int // $_ }).List;
        }

        # Parse from end to front
        parse('build', $_)       with $spec.index("+");
        parse('pre-release', $_) with $spec.index("-");

        $spec
          ?? parse('version')
          !! die "Version can not be empty";

        self.bless(|%args)
    }

    method inc(Version::Conan:D: UInt:D $part) {
        my @version = @!version;
        $part < @version.elems
          ?? @version[$part]++
          !! die "Part $part is not a valid index for incrementing";

        self.bless(:version(@version.List), :@!pre-release, :@!build)
    }

    method major(Version::Conan:D:) { @!version[0]        }
    method minor(Version::Conan:D:) { @!version[1] // Nil }
    method patch(Version::Conan:D:) { @!version[2] // Nil }

    multi method Str(Version::Conan:D:) {
        "@!version.join('.')"
          ~ ("-@!pre-release.join('.')" if @!pre-release)
          ~ ("+@!build.join('.')"       if @!build)
    }
    multi method raku(Version::Conan:D:) {
        self.^name ~ '.new(' ~ self.Str.raku ~ ')'
    }

    method cmp(Version::Conan:D: Version::Conan:D $other --> Order) {
        self!compare(@!version, $other.version, Less)
          || self!compare(@!pre-release, $other.pre-release, Less)
          || self!compare(@!build, $other.build, More)
    }

    method eqv(Version::Conan:D: Version::Conan:D $other) {
        (self!compare(@!version, $other.version, More)
          || self!compare(@!pre-release, $other.pre-release, Less)
          || self!compare(@!build, $other.build, More)) == Same
    }

    method !compare(@lefts, @rights, $default) {

        # at least one piece of data on the right
        if @rights {

            # at least one on left
            if @lefts {
                my int $i;
                for @lefts -> $left {
                    with @rights[$i++] -> $right {
                        if $left cmp $right -> $diff {
                            return $diff;  # UNCOVERABLE
                        }
                    }
                    else {
                        return More;
                    }
                }

                # right not exhausted yet?
                $i <= @rights.end ?? $default !! Same
            }

            # data right, not on left
            else {
                $default == Less ?? More !! Less
            }
        }

        # no info on right
        else {
            @lefts ?? $default !! Same
        }
    }

    multi method ACCEPTS(Version::Conan:D: Version::Conan:D $other) {
        self.cmp($other) == Same
    }
}

#- infixes ---------------------------------------------------------------------
my multi sub infix:<cmp>(
  Version::Conan:D $a, Version::Conan:D $b
--> Order:D) is export {
    $a.cmp($b)
}

my multi sub infix:<eqv>(
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.eqv($b)
}

my multi sub infix:<==>(
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.cmp($b) == Same
}

my multi sub infix:<!=>(
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.cmp($b) != Same
}

my multi sub infix:«<» (
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.cmp($b) == Less
}

my multi sub infix:«<=» (
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.cmp($b) != More
}

my multi sub infix:«>» (
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.cmp($b) == More
}

my multi sub infix:«>=» (
  Version::Conan:D $a, Version::Conan:D $b
--> Bool:D) is export {
    $a.cmp($b) != Less
}

#- other infix methods ---------------------------------------------------------
# Note that this is a bit icky, but it allows for a direct mapping of the
# infix op name to a method for comparison with the $a."=="($b) syntax,
# without having to have the above infixes to be imported
BEGIN {
    Version::Conan.^add_method: "~~", { $^a.cmp($^b) == Same }  # UNCOVERABLE
    Version::Conan.^add_method: "==", { $^a.cmp($^b) == Same }  # UNCOVERABLE
    Version::Conan.^add_method: "!=", { $^a.cmp($^b) != Same }  # UNCOVERABLE
    Version::Conan.^add_method: "<",  { $^a.cmp($^b) == Less }  # UNCOVERABLE
    Version::Conan.^add_method: "<=", { $^a.cmp($^b) != More }  # UNCOVERABLE
    Version::Conan.^add_method: ">",  { $^a.cmp($^b) == More }  # UNCOVERABLE
    Version::Conan.^add_method: ">=", { $^a.cmp($^b) != Less }  # UNCOVERABLE
}

# vim: expandtab shiftwidth=4
