export alias xm = xmake
export alias xmb = xmake build
export alias xmr = xmake run
export alias xmc = xmake clean
export def --wrapped --env xmnc [ name: string, ...args ] {
    xmake create -l c ...$args $name
    cd $name
}
