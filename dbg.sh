#!/bin/bash
cd "$(dirname "$0")"

OPTS=""
# For debuging purposes the script may by run manually:
# ITERP= .deb.sh  <firmware>
# In this case no dap interpreter is eneabled
PORT=3333
if [ -v ITERP ]; then
  OPTS=" -ex \"target extended-remote localhost:$PORT\""
fi

# echo $OPTS
GDB=/opt/gdb-16.1-arm/bin/arm-none-eabi-gdb
CMD="$GDB \
  -x .gdbinit -q \
  "$@" \
  "$OPTS" \
  -ex \"set confirm off\" \
  -ex \"monitor reset halt\""

eval "exec $CMD"
# -ex "set architecture arm" \
# --interpreter=dap
