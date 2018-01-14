## Take note snippets

### Requirements

- [ripgrep](https://github.com/BurntSushi/ripgrep): for full-text searching
- [ranger](https://github.com/ranger/ranger): for browsing directory
- [fzf](https://github.com/junegunn/fzf): for fuzzy selection

### Feature highlights

- Written directly in zsh script, no extra runtime
- Full zsh completion support
- Filtering with tags
- Full text search
- Plain text notes stored anywhere (syncable with external services like Dropbox)
- Freedom!

### Installation

Clone this repo and include the following line in your `.zshrc`.

    source path/to/n.zsh

### Usage

Just follow the auto-completion:

    n <press tab>

Commands:

- `new <note name>`: create new note with given name
- `ls`: list notes
- `edit [note name...]`: edit given notes, if no arguments specified, launch selection program
- `cat [note name...]`: same as edit, but for viewing rather than editing
- `manage`: launch file manager
- `grep [options] <pattern>`: full text search with ripgrep, options will be passed to ripgrep
- `filter <tag>`: list notes with matched tag

### Configuration

To change the location of `CONFIG_FILE`, set this environment variable before sourcing the script. Otherwise it defaults to `~/.config/n.conf`.

The config file is a shell script that generates configuration items as environment variables.

Available configurations:

- `NOTE_PATH`: directory where notes are stored (default: `~/Documents/notes`)
- `NOTE_DEFAULT_EXT`: default extension for note files (default: `.md`)
- `NOTE_EDITOR`: editor used to edit notes (default: `$EDITOR` or `vim`)
- `NOTE_VIEWER`: viewer used to cat notes (default: `$PAGER` or `less -F`)

You may create a file `<NOTE_PATH>/.template` to hold the default content for new notes.



Example configuration:

    # ~/.config/n.conf

    if [[ `uname` = 'Darwin' ]]; then
      NOTE_PATH="$HOME/Dropbox/Documents/notes/Snippets"
    else
      NOTE_PATH="$HOME/Documents/notes/Snippets"
    fi
    
    NOTE_EDITOR='emacs -c'
    NOTE_VIEWER='vim -R'
    
    NOTE_DEFAULT_EXT=.markdown

### License

Copyright 2018 Shou Ya

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


