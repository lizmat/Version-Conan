use Version::Semverish:ver<0.0.2+>:auth<zef:lizmat>;

#- Version::Conan -----------------------------------------------------------
class Version::Conan:ver<0.0.3>:auth<zef:lizmat> is Version::Semverish {

    method has-illegal-chars(Version::Conan:U: Str:D $target) {
        $target.contains(/ <-[a..z 0..9 . *]> /)
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

# vim: expandtab shiftwidth=4
