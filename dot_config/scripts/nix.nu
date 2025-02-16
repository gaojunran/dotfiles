# This file is tested by tests/installer/default.nix.

def getNixLink [] {
    return (if ("NIX_STATE_HOME" in $env) and ($env.NIX_STATE_HOME | is-not-empty) {
        ($env.NIX_STATE_HOME | path join ["profile"])
    } else {
        let home_nix_profile = $"($env.HOME)/.nix-profile"
        let nix_link_new = if "XDG_STATE_HOME" in $env and ($env.XDG_STATE_HOME | is-not-empty) {
            $"($env.XDG_STATE_HOME)/nix/profile"
        } else {
            $"($env.HOME)/.local/state/nix/profile"
        }

        if ($nix_link_new | path exists) {
            if ($nu.env.STDERR_ISATTY) and ($home_nix_profile | path exists) {
                let warning = "warning:"
                print ("\$warning Both \$nix_link_new and legacy \$home_nix_profile exist; using the former.\n")
                if (($home_nix_profile | realpath) == ($nix_link_new | realpath)) {
                    print ("         Since the profiles match, you can safely delete either of them.\n")
                } else {
                    print ("\$warning Profiles do not match. You should manually migrate from \$home_nix_profile to \$nix_link_new.\n")
                }
            }
            $nix_link_new
        } else {
            $home_nix_profile
        }
    })
}

def getNewXdgDataDirs [ nixLink ] {
    return (if not (('XDG_DATA_DIRS' in $env) and ($env.XDG_DATA_DIRS | is-not-empty)) {
        $"/usr/local/share:/usr/share:($nixLink)/share:/nix/var/nix/profiles/default/share"
    } else if ('XDG_DATA_DIRS' in $env) {
        $"($env.XDG_DATA_DIRS):($nixLink)/share:/nix/var/nix/profiles/default/share"
    })
}

def getNixSslCertFile [ nixLink ] {
    return (if ("/etc/ssl/certs/ca-certificates.crt" | path exists) {
        "/etc/ssl/certs/ca-certificates.crt"
    } else if ("/etc/ssl/ca-bundle.pem" | path exists) {
        "/etc/ssl/ca-bundle.pem"
    } else if ("/etc/ssl/certs/ca-bundle.crt" | path exists) {
        "/etc/ssl/certs/ca-bundle.crt"
    } else if ("/etc/pki/tls/certs/ca-bundle.crt" | path exists) {
        "/etc/pki/tls/certs/ca-bundle.crt"
    } else if (($nixLink | path join ["etc" "ssl" "certs" "ca-bundle.crt"]) | path exists) {
        ($nixLink | path join ["etc" "ssl" "certs" "ca-bundle.crt"])
    } else if (($nixLink | path join ["etc" "ca-bundle.crt"]) | path exists) {
        ($nixLink | path join ["etc" "ca-bundle.crt"])
    })
} 

if ($env.HOME | is-not-empty) and ($env.USER | is-not-empty) {
    let nixLink = getNixLink
    $env.PATH = ($env.PATH | split row (char esep) | prepend $nixLink)
    let nix_ssl_cert_file = (getNixSslCertFile $nixLink)
    {
        NIX_PROFILES: $"/nix/var/nix/profiles/default ($nixLink)",
        XDG_DATA_DIRS: (getNewXdgDataDirs $nixLink),
        NIX_SSL_CERT_FILE: (if ($nix_ssl_cert_file | is-not-empty) { $nix_ssl_cert_file }  else { '' }),
        MANPATH: (if (('MANPATH' in $env) and ($env.MANPATH | is-not-empty)) {$"$nix_link/share/man:($env.MANPATH)" })
    } | to json
}
