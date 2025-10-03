#!/bin/bash

fcm1="fHWRTKGHjUnvqSlrBdeqQO:APA91bG0tH-fcy44_OBirgoIt04s4s58k-9gEJPFg9vglCoux9nRdgH7SYMmxUD6HWrTgakeFZK3J6OeZIf2Qs8aaxDUpGRlh9zwBVwWU9Lkg9U5c3MzCYzkrAKf2vRSzr3ClqGPWLbU"

JAR=/Users/director/software/tommypush.jar
CONFIG=/Users/director/Yandex.Disk.localized/all/configs/firebase/tommypush-firebase.json
TITLE="Tommypush"
TEXT="Buenas días, Tommy"

java -jar $JAR $CONFIG "$TITLE" "$TEXT" "$fcm1"
