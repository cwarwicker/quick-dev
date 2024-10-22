# quick-dev

`git submodule update --init --recursive` to clone submodules

`mkdir ~/.config/quick-dev`

`cp config ~/.config/quick-dev` Change path if it's wrong

Add `source ~/.config/quick-dev/config` to bottom of .bashrc file

`source .bashrc`

Add a new site:

- `cd apps`
- `git clone <url> <name>`
- `cd <name>`
- `qd config`
- `qd up`
