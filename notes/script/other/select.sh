#!/bin/bash
#菜单的两种方式

echo "----------------------------------"
echo "please enter your choise:"
echo "(0) mongotest"
echo "(1) mongomaster"
echo "(2) mongozwt179"
echo "(3) mongobjsc115"
echo "(4) mongobjsc102"
echo "(9) Exit Menu"
echo "----------------------------------"
read input

case $input in
    0)
    echo mongotest
    sleep 1
    mongotest;;
    1)
    echo mongomaster
    sleep 1
    mongomaster;;
    2)
    echo mongozwt179
    sleep 1
    mongozwt179;;
    3)
    echo mongobjsc115
    sleep 1
    mongobjsc115;;
    4)
    echo mongobjsc102
    sleep 1
    mongobjsc102;;
    9)
    exit;;
esac
#select 方式
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