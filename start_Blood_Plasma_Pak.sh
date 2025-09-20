#!/bin/bash
cd "$(dirname "$0")/Programs/Blood_Plasma_Pak" || exit
"dosbox" "BLOOD.EXE" -conf "../Configuration/dosbox.conf" -fullscreen -exit
