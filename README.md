# ddep
Just another dotfile deployment script.

### Usage

##### To start using ddep:
1. Create a dotfiles git repo. (Probably in Github)
2. Copy ddep.sh to your repo.
3. In the repo, run `sudo ./ddep.sh install`. (Simply symlinks the ddep.sh script to wherever the `env` command is on your system.) (This is technically optional but there is no harm and it will make life much easier.)
4. `ddep add` all of the files you want to sync.
5. `ddep push` to commit and push to github.

##### To sync your ddep to a new computer:
1. Clone your ddep repo.
2. Make sure `$DF_DIR` points to the dotfiles folder!
3. (Technically optional) run `sudo $DF_DIR/ddep.sh install`.
4. Run `ddep deploy`. `ddep` should treat your files nicely; it will unlink soft links (telling you where they point) and will try to move conflicting files to `$DF_DIR/stash`.

```
Usage: ddep [command] [file]
Commands:
    install: installs (symlinks) ddep to wherever 'env' is located
    uninstall: unlinks ddep from wherever 'env' is located
    deploy: symlinks dotfiles to home
    add [file]: adds file to dotfiles
    rm [file]: removes file from dotfiles
    pull: pulls dotfiles repository from github
    push: commits & pushes dotfiles repository to github
```

### Notes
 - By default, `ddep` thinks its working dir is `$HOME/dotfiles`. Change this by setting `$DF_DIR` in your `.bashrc`.
 - Your `ddep.sh` file doesn't actually need to be in `$DF_DIR` at all, but (I think) it helps keep things simple. 
 - `ddep` uses `$DF_DIR/home` and `$DF_DIR/.dfreg` extensively. Messing with either could break your whole setup. Any other files in `$DF_DIR` are pretty much fair game.
 - `ddep` uses `$DF_DIR/home` and `$DF_DIR/.dfreg` extensively, and NEEDS them to be synchronized. Messing with either could break your whole dotfiles setup.

### Caveats
 - If you add a file in a subdirectory of home, then add that subdirectory, I can't guarantee what will happen. It will probably hurt.
 - The above also counts for adding a subdirectory then a file in the subdirectory.

### Todo
 - Fix the caveats!
 - Deployment file-by-file (if we have two files synced in a subdir, deploy that subdir to sync all files in the subdir!)
 - Support for people who want to keep their dotfiles not on github?
 - Support for alternatives of files...?
