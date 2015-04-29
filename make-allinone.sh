#!/bin/sh

# see https://github.com/tst2005/luamodules-all-in-one-file/
# wget https://raw.githubusercontent.com/tst2005/luamodules-all-in-one-file/newtry/pack-them-all.lua
ALLINONE=./pack-them-all.lua 

(
	cd marin0se/ && ../"$ALLINONE" $(
	find -depth -name '*.lua' -printf '%P\n' | while read -r line; do echo "--mod $(echo "$line" | sed 's,\.lua$,,g' | tr / .) $line"; done
	) --autoaliases --code main.lua
)

# How to use it ?
# Just run :
#   ./make-allinone.sh > main.lua
