
complete -c jump -n 'test (commandline) = "jump -"' -f -a '-h'

function __fish_jump_suggest
	set pre (commandline -co)

	switch (count $pre)
		case 0
		case 1
			set pre
		case 2
			test $pre[2] = --
			and set pre
			or set pre $pre[2]
		case '*'
			test $pre[2] = --
			and set pre $pre[3..-1]
			or set pre $pre[2..-1]
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

complete -c jump -n 'test (commandline) != "jump -"' -f -a '(__fish_jump_suggest)'
