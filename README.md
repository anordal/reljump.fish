# reljump.fish

**A composable *jump* command with relative abilities, for fish**

Lets you change directory based on more or less relative bookmarks, paths and an edit prompt, in arbitrary combinations. A bit similar to [apparix](http://micans.org/apparix/).

# The problem
The problem I set out to solve: A collection of only absolute bookmarks doesn't scale! Because they refer to absolute paths, they don't apply to other familiar-looking directory trees you may encounter. For example, I had a respectable set of absolute bookmarks for a project I do for work — then I duplicated the workspace… Needless to say, that broke my workflow for a while.

# The solution
This `jump` command can take, not just one bookmark, but arbitrary combinations of more or less relative bookmarks and other arguments, making it easier to extend what you have, and construct previously unimagined franken-paths.

An argument can be:
* A bookmark, which is either
 * Absolute
 * Relative (to where you are)
 * Landmark type relative — relative to a landmark of a given type, like the nearest git root directory
* The *edit* command, which is the minus sign `-`
* A path, which is anything that contains a slash `/`

The change of directory happens once, no matter the number of arguments, to minimize directory history clutter.

# Usage
There is a tutorial:

```fish
jump --tutorial
```

Note, this command is fishy — all in one command that takes options. Hopefully discoverable ;-)

# Installation

    cp -R functions/ completions/ ~/.config/fish/
