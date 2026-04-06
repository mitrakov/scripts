#!/usr/bin/env bash
# by: mitrakov-artem@yandex.ru
set -euo pipefail

WORDS=(
    a i ad am an as at be by do ed ex go he hi if in is it me my no of oh ok on or ox pi so to up us we
    act add age ago aid aim air all and ant any ape apt arc are arm art ash ask ate awe axe bad bag
    ban bar bat bay bed bee beg bet bid big bin bit boa bob bog bow box boy bud bug bun bus but buy
    bye cab can cap car cat caw cob cod cog con cop cot cow coy cry cub cue cup cut dab dad dam day
    den dew did die dig dim din dip dog dot dry dub due dug dye ear eat ebb egg ego elk elm end era
    eve eye fan far fat fed fee few fig fin fir fit fix fly fog for fox fry fun fur gap gas gel gem
    get gig gin god got gum gun guy gym had ham has hat hay hem hen her hey hid him hip his hit hog
    hop hot how hub hug hum hut ice ill imp ink inn ion its ivy jam jar jaw jet jig job jog joy jug
    kept key kid kin kit lab lad lag lap law lax lay led leg let lid lie lip lit log lot low mad man
    map mat may men met mid mix mob mom mud mug nab nag nap net new nil nip nod nor not now nut oak
    oat odd off oil old one
)

function encode() {
    od -An -v -t u1 "$1" | while read -r line; do
        for byte in $line; do
            printf "%s " "${WORDS[$byte]}"
        done
    done
    echo ""
}

function decode() {
    for word in $(cat "$1"); do
        for i in "${!WORDS[@]}"; do     # TODO: fix O(N²)
            if [[ "${WORDS[$i]}" == "$word" ]]; then
                printf "\\x$(printf %02x "$i")"
                break
            fi
        done
    done
}

####

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 [-e | -d] <file>"
    exit 1
fi

if [[ ! -f "$2" ]]; then
    echo "File not found: $2"
    exit 2
fi

while getopts "ed" opt; do
    case $opt in
        e)
            encode "$2"
            ;;
        d)
            decode "$2"
            ;;
        *)
            echo "Usage: $0 [-e | -d] <file>"
            ;;
    esac
done
