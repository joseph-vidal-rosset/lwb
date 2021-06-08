#!/bin/sh

netscape -remote "openURL("$1")" 2> /dev/null 
result=$?

# netscape is not yet running
if [ $result -ne 0 ]; then
  netscape $1 &
fi



