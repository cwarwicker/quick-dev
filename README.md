# quick-dev

`mkdir ~/.config/quick-dev`

`cp config ~/.config/quick-dev` Change path if it's wrong

Add `source ~/.config/quick-dev/config` to bottom of .bashrc file

`source .bashrc`

`docker network create quick-dev-network`

Add a new site:

- `cd sites`
- `git clone <url> <name>`
- `cd <name>`
- Set the project type and image in the `.quick-dev.env` file
- `qd add`
- `qd up`
