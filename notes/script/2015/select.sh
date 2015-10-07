#!/bin/bash
echo "Please choose a number,1:run w;2:run top;3:run free;4:quit"
echo
PS3="你必须输入1-4之间的数字:"
select command in w top free quit
do
	case $command in
	w)
		w
		;;
	top)
		top
		;;
	free)	
		free
		;;
	quit)
		exit
		;;
	*)
		echo "Please input a number:(1-4)!"
		;;
	esac
done
