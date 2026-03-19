#!/bin/bash
set -e
cd /app

RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'
USAGE='Usage: docker run --rm --env YANDEX_TOKEN="yandex_music_token" --volume $HOME/Downloads:/app mitrakov/y-music:1.0.0\n - token you can get here: https://yandex-music.readthedocs.io/en/main/token.html\n - links.txt must contain lines in format: https://music.yandex.ru/album/8672292/track/57605743'

if [ -z "$YANDEX_TOKEN" ] || [ "$YANDEX_TOKEN" == "yandex_music_token" ]; then
    echo -e "${RED}Error: YANDEX_TOKEN not set.${NC}"
    echo -e $USAGE
    exit 1
fi

if [ ! -f "links.txt" ]; then
    echo -e "${RED}Error: file links.txt not found in your volume.${NC}"
    echo -e $USAGE
    exit 1
fi

QUALITY=${QUALITY:-1}

success=0
total=0
while IFS= read -r HTTP_URL || [[ -n "$HTTP_URL" ]]; do    # "-n" is to handle last line if it doesn't contain \n
    [[ -z "$HTTP_URL" ]] && continue                       # skip empty lines
    echo -e "Processing: ${PURPLE}${HTTP_URL}${NC}"    
    if yandex-music-downloader --quality $QUALITY --token "$YANDEX_TOKEN" --url "$HTTP_URL"; then
    	((success++))
    fi
    ((total++))
done < "links.txt" || true                        # "|| true" is to pass "set -e" if last line doesn't contain \n

echo "Done: $success/$total track(s) downloaded."
