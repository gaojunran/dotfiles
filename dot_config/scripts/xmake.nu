export alias xm = xmake
export alias xmb = xmake build
export def xmr [] {
    xmake build
    xmake run
}
export alias xmc = xmake clean
export def --wrapped --env xmnc [ name: string, ...args ] {
    xmake create -l c ...$args $name
    cd $name
}
