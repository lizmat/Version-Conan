#- Version::Conan -----------------------------------------------------------
class Version::Conan:ver<0.0.2>:auth<zef:lizmat> {
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
              if $target.contains(/ <-[a..z 0..9 . *]> /);

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

    method inc(Version::Conan:D: UInt:D $part = @!version.end) {
        my @version = @!version;
        die "Part $part is not a valid index for incrementing"
          if $part >= @version.elems;

        @version[$part]++;
        self.bless(:version(@version[0..$part]), |%_)
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
        self.cmp($other) == Same
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
        self.eqv($other)
    }

    # https://docs.conan.io/2/tutorial/versioning/version_ranges.html#range-expressions
    method as-generic-range(Version::Conan:U: Str:D $spec --> Slip:D) {

        my sub slip-one(Str:D $version, Str:D $comparator = '==') {
            ($comparator, Version::Conan.new($version)).Slip
        }
        my sub slip-range(Version::Conan:D $left, Version::Conan:D $right) {
            ('>=', $left, '<', $right).Slip
        }

        if $spec eq ''
          || $spec eq '*'
          || $spec eq '*-'
          || $spec.contains(/ ^ '*,' \s+ 'include_prerelease=True' $ /) {  # UNCOVERABLE
            slip-one('0.0.0', '>=')
        }
        else {
            $spec.split(/ <[ \s | ]>+ /, :skip-empty).map(-> $version is copy {
                $version .= chop if $version.ends-with('-');  ##  XXX is this correct?

                if $version.starts-with('~') {
                    my $conan := Version::Conan.new($version.substr(1));
                    slip-range($conan, $conan.inc)
                }
                elsif $version.starts-with('^') {  # UNCOVERABLE
                    my $conan := Version::Conan.new($version.substr(1));
                    slip-range($conan, $conan.inc($conan.version - 2))
                }
                elsif $version.starts-with('<=' | '>=') {  # UNCOVERABLE
                    slip-one($version.substr(2), $version.substr(0,2))
                }
                elsif $version.starts-with('<' | '>') {  # UNCOVERABLE
                    slip-one($version.substr(1), $version.substr(0,1))
                }
                elsif $version.starts-with('=') {  # UNCOVERABLE
                    slip-one($version.substr(1))
                }
                elsif $version.ends-with('.*') {  # UNCOVERABLE
                    slip-one($version.substr(0, *-2), '>')
                }
                else {
                    slip-one($version)
                }
            }).Slip
        }
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
    Version::Conan.^add_method: "==", { $^a.cmp($^b) == Same }  # UNCOVERABLE
    Version::Conan.^add_method: "!=", { $^a.cmp($^b) != Same }  # UNCOVERABLE
    Version::Conan.^add_method: "<",  { $^a.cmp($^b) == Less }  # UNCOVERABLE
    Version::Conan.^add_method: "<=", { $^a.cmp($^b) != More }  # UNCOVERABLE
    Version::Conan.^add_method: ">",  { $^a.cmp($^b) == More }  # UNCOVERABLE
    Version::Conan.^add_method: ">=", { $^a.cmp($^b) != Less }  # UNCOVERABLE

    Version::Conan.^add_method: "~~", { $^b.ACCEPTS($^a) }  # UNCOVERABLE
}

# vim: expandtab shiftwidth=4
