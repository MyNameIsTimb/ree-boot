# ree-boot
Automatic rebooting for your Garry's Mod dedicated server

## Usage
Place the addon into your addon folder as you would any other legacy (filesystem) addon.

Modify the values at the top of the script, above the "Editing below voids warranty" line.

Then, open your GMod installation's `cfg/network.cfg` file and add the following line:

```
alias restart_server_hackylau "exit"
```

You can use the `reeboot` concommand in game to control ree-boot. Type `reeboot help` to see a list of available commands.
