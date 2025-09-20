#!/bin/bash
cd "$(dirname "$0")/Programs/WWF" || exit
"dosbox" "WWF4.EXE" -conf "../Configuration/dosbox.conf" -fullscreen -exit
