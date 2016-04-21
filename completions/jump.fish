
complete -c jump -s h -l help -d 'Print usage'
complete -c jump -s m -l mv -x -a '(command ls (jump --get-markpath))' -d 'Rename bookmark'
complete -c jump -s r -l rm -x -a '(command ls (jump --get-markpath))' -d 'Delete bookmarks'
complete -c jump -s s -l set -x -d 'Create bookmark'
complete -c jump -s c -l setscm -x -d 'Create scm bookmark'

function __fish_jump_suggest
	set pre (commandline -co)

	switch (count $pre)
		case 0
		case 1
			set pre
		case 2
			switch $pre[2]
				case -- -p --print
					set pre
				case '*'
					set pre $pre[2]
			end
		case '*'
			switch $pre[2]
				case -- -p --print
					set pre $pre[3..-1]
				case '*'
					set pre $pre[2..-1]
			end
	end

	set pre (jump -p $pre ^/dev/null)
	or return 0

	switch (commandline -t)
		case '.*' '*/*'
			set candidates ./(command ls $pre)/
		case '*'
			set candidates (command ls (jump --get-markpath))
	end

	test $pre = .
	and set pre

	set dejavu (stat . | grep -Ei '(device|inode)')
	for i in $candidates
		set -l path (jump -p $pre/ $i ^/dev/null)
		and set -l pathstat (stat -L $path | grep -Ei '(device|inode)')
		and test "$pathstat" != "$dejavu"
		and printf '%s\n' $i
	end
end

complete -c jump -s p -l print -x -a '(__fish_jump_suggest)' -d 'Show destination'
complete -c jump -n 'test (commandline) != "jump -"' -f -a '(__fish_jump_suggest)'
