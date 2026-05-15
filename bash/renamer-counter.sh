#!/bin/bash

# El primer argumento es nuestro patrón (ej. apple_%02d.txt)
PATTERN=$1
shift

# Contador inicial
COUNT=1

for FILE in "$@"; do
    # Extraemos la extensión si fuera necesario, o simplemente aplicamos el patrón
    # Generamos el nuevo nombre usando printf para procesar los %d, %02d, etc.
    NEW_NAME=$(printf "$PATTERN" "$COUNT")

    if [ "$FILE" != "$NEW_NAME" ]; then
        mv -iv "$FILE" "$NEW_NAME"
    fi

    COUNT=$((COUNT + 1))
done
