#split section names string to one by one name string, and save to env $last_split_names, e.g. "name1-2 name20 name30-33"=>"name1 name2 name20 name30 name31 name32 name33"
#
#       like:
#       myoldnames="name1-2 name20 name30-33"
#       source ./splitnames.sh "$myoldnames" 
#       mynewnames=$last_split_names
function f_splitnames()
{
        local all_oldnames=$1
        local newnames=""

        for oldnames in $all_oldnames
        do
                local start=${oldnames%-*}
                local end=${oldnames#*-}

                if [ "$end" == "$start" ]
                then
                        if [ "$newnames" == "" ]
                        then
                                newnames=$start
                        else
                                newnames="$newnames $start"
                        fi
                else
                        local length=${#start}
                        local i
                        for((i=length-1;i>=0;i--))
                        do
                                local ch=${start:i:1}
                                if [[ $ch < '0' ]] || [[ $ch > '9' ]]
                                then
                                        break
                                fi
                        done
                        local header=""
                        local tail=""
                        if [[ $i -ge 0 ]]
                        then
                                let i++
                                header=${start:0:i}
                                tail=${start:i}
                        else
                                header=""
                                tail=$start
                        fi

                        local num
                        for((num=$tail;num<=$end;num++))
                        do
                                if [ "$newnames" == "" ]
                                then
                                        newnames="$header$num"
                                else
                                        newnames="$newnames $header$num"
                                fi
                        done
                fi
        done