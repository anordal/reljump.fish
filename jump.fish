
# Based on "shell bookmarks" by J.Janssens:
# http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html

function jump
	if set -q XDG_CONFIG_HOME
		set markpath $XDG_CONFIG_HOME/marks
	else
		set markpath $HOME/.config/marks
	end

	if test (count $argv) -eq 0
		set argv -l
	end
	switch $argv[1]
		case -
		case '-*'
			set have_option
	end

	if not set -q have_option
		set -l dst .
		for arg in $argv
			switch $arg
				case -
					if test $dst = .
						set dst $PWD
					end
					read -p "set_color $fish_color_cwd; printf 'cd '; set_color normal" -sc $dst path
					set dst .
				case '*/*'
					set path $arg
				case '*'
					if not set path (readlink $markpath/$arg)
						echo "No such mark: $arg" >&2
						return 1
					end
			end
			switch $path
				case '//scm/*'
					set path (printf '%s' $path | tail -c+7)
					if not set path (git -C $dst rev-parse --show-cdup)"$path"
						echo "Not in a recognised scm repo" >&2
						return 1
					end
			end
			if test $dst = .
				set dst $path
			else
				set dst $dst/$path
			end
			if not set i (stat -c '%i' $dst)
				return 1
			end
		end
		cd $dst
		return $status
	end

	switch $argv[1]
		case -l --ls
			set -l oldcollate $LC_COLLATE
			set -x LC_COLLATE C
			for i in $markpath/*
				printf '%s/%s\0' (readlink $i) (basename $i)
			end | sort -zn | while read -zl i
				set -l dst (dirname $i)
				set -l color purple
				switch $dst
					case '//*'
						set color f70
					case '/*'
						set color -o blue
				end
				printf '%8s → %s%s%s\n' (basename $i) (set_color $color) $dst (set_color normal)
			end
			set -x LC_COLLATE $oldcollate
		case -r --rm
			if test (count $argv) -gt 1
				rm $markpath/$argv[2..-1]
			end
		case -m --mv
			if test (count $argv) -eq 3
				mv $markpath/$argv[2..-1]
			end
		case -s --set
			mkdir -p $markpath
			or return 1
			if test (count $argv) -le 2
				ln -s $PWD $markpath/$argv[2]
			else
				ln -s $argv[3] $markpath/$argv[2]
			end
		case -c --set{scm,vcs}
			if test (count $argv) -ne 2; or not mkdir -p $markpath
				return 1
			end
			# TODO: Detect & support other things than git, if needed
			ln -s //scm/(git rev-parse --show-prefix) $markpath/$argv[2]
		case --tutorial
			_jump_tutorial
		case '*'
			echo 'jump - change directory using any combination of'
			echo '* absolute bookmarks'
			echo '* relative bookmarks'
			echo '* typed bookmarks, which are absolute within a certain type'
			echo '  of directory (currently an "scm" type that supports git)'
			echo '* regular paths'
			echo '* editing your current location'
			echo ''
			echo 'Usage:'
			echo 'jump                     List bookmarks'
			echo 'jump JUMPARGS            Jump to a path constructed from JUMPARGS'
			echo 'jump -h|--help           Print usage'
			echo 'jump -r|--rm NAMES       Delete bookmarks named NAMES'
			echo 'jump -m|--mv OLD NEW     Rename bookmark from OLD to NEW'
			echo 'jump -s|--set NAME       Bookmark the absolute path to the current directory'
			echo 'jump -s|--set NAME PATH  Bookmark PATH (use to create a relative bookmark)'
			echo 'jump -c|--setscm NAME    Bookmark the current directory within an scm repo'
			echo 'jump    --setvcs NAME    Alias for --setscm'
			echo ''
			echo 'Explanation of JUMPARGS:'
			echo 'Jump changes directory to the path formed by concatenating each argument'
			echo 'after expanding it according to its category:'
			echo '* the single "-" (dash) character means "edit";'
			echo '* anything containing a "/" (slash) character is a path;'
			echo '* anything else is a bookmark.'
			echo ''
			echo 'For examples, see `jump --tutorial`.'
	end
end

function _jump_tutorial
printf '%s' "\
Tutorial

Level 1: An absolute bookmark

~> mkdir -p /tmp/{blue,straw}berry
~> /tmp/strawberry
/tmp/strawberry> # Let's bookmark this location
/tmp/strawberry> jump --set straw
/tmp/strawberry> # See how the bookmark list looks like now
/tmp/strawberry> jump
   straw → /tmp/strawberry
/tmp/strawberry> # Congratulations, you have a bookmark
/tmp/strawberry> # Let's test it
/tmp/strawberry> cd
~> jump straw
/tmp/strawberry>

Level 2: Edit your location

/tmp/strawberry> jump -
# Now, replace \"straw\" with \"blue\"
/tmp/blueberry>

Level 3: Combine arguments

/tmp/blueberry> cd
~> # How to get to blueberry from somewhere else? Hint: We have a bookmark
~> # that is almost what we need, and we know how to edit; combine these
~> jump straw -
# Et voilà, now it is only for you to replace \"straw\" with \"blue\"
/tmp/blueberry>
/tmp/blueberry> cd
~> # Another way, using a path instead of editing
~> jump straw ../blueberry
/tmp/blueberry>
/tmp/blueberry> # Having reached the destination, let's bookmark it
/tmp/blueberry> jump --set blue

Level 4: Relative bookmarks

/tmp/blueberry> ..
/tmp> # Suppose we have some very similar directory trees
/tmp> mkdir -p {blue,straw}berry/{'ice cream',muffin}
/tmp>
/tmp> # ...and we want bookmarks to subdirectories of both trees. With
/tmp> # absolute bookmarks, we would need to duplicate these for each tree
/tmp> # - relative bookmarks to the rescue.
/tmp> jump --set ice 'ice cream'
/tmp> jump --set muf muffin
/tmp> jump
     ice → ice cream
     muf → muffin
    blue → /tmp/blueberry
   straw → /tmp/strawberry
~> jump blue ice
/tmp/blueberry/ice cream>
/tmp/blueberry/ice cream> jump blue muf
/tmp/blueberry/muffin>
/tmp/blueberry/muffin> jump straw muf
/tmp/strawberry/muffin>
/tmp/strawberry/muffin> jump straw ice
/tmp/strawberry/ice cream>

Level 5: Scm bookmarks

/tmp/strawberry/ice cream> # The problem with relative bookmarks is...
/tmp/strawberry/ice cream> jump muf
'muffin': No such file or directory
/tmp/strawberry/ice cream> # ...they are relative.
/tmp/strawberry/ice cream>
/tmp/strawberry/ice cream> # But suppose
/tmp/strawberry/ice cream> jump straw
/tmp/strawberry> git init
/tmp/strawberry> jump blue
/tmp/blueberry> git init
/tmp/blueberry>
/tmp/blueberry> # ...we make scm bookmarks instead of relative ones
/tmp/blueberry>
/tmp/blueberry> # yeah, and this extremely handy one too
/tmp/blueberry> jump --setscm up
/tmp/blueberry>
/tmp/blueberry> jump ice
/tmp/blueberry/ice cream> jump --rm ice
/tmp/blueberry/ice cream> jump --setscm ice
/tmp/blueberry/ice cream>
/tmp/blueberry/ice cream> jump up muf
/tmp/blueberry/muffin> jump --rm muf
/tmp/blueberry/muffin> jump --setscm muf
/tmp/blueberry/muffin>
/tmp/blueberry/muffin> # They behave as absolute within the repository...
/tmp/blueberry/muffin> jump ice
/tmp/blueberry/ice cream> jump muf
/tmp/blueberry/muffin> jump up
/tmp/blueberry>
/tmp/blueberry> # ...but apply just as well to another repository
/tmp/blueberry> jump straw muf
/tmp/strawberry/muffin> jump ice
/tmp/strawberry/ice cream> jump up
/tmp/strawberry>
"
end
