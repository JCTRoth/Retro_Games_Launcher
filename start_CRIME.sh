#!/bin/bash
cd "$(dirname "$0")/Programs/CRIME" || exit
"dosbox" "CRIME.EXE" -conf "../Configuration/dosbox.conf" -fullscreen -exit
