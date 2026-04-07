#!/usr/bin/env bash
# by: mitrakov-artem@yandex.ru
set -euo pipefail

# top 2000 english words containing up to 3 chars
WORDS=(
    be am are is was I you the a an to it not and of do did had has we in get got my me go oh can no on for all so he but out up
    say now at one hey see saw if how she guy let her uh um him why who as our yes man men his us or OK way too by day two God
    off big try dad kid boy put bad any Mr use mom may hi new lot ask hmm hm met huh old wow eat ate run ran car ah aah job fun
    buy son sit sat own dog die sir sex pay hot win won eye aw hit yet ten ass gay few ow yow lie lay ago end its ha hah fat cut
    bit bed six set bar bye box bet tho Mrs cat hat mm cry act eh god bag shh sh key red yep mad ice war fly top far leg air gun
    ahh fix ugh hid sad pie ho law egg art arm bus age yay fan owe led pee cup cop pig Jew rid Ms Mss pop cow ear toy Net fit gas
    ew eww fed ma tea cab pen sea yo add low nah rat tie sun dig dug tip rip pal gee gym wet beg uhh sox gum mix hoo lip oil bra
    tax nut sue pot due rub sky lab row hug van tub ad ads bee dry toe hip pet bum bug nap tag per ton odd
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
