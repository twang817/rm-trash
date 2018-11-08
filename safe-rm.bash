#!/bin/bash

# TODO : handle sudo  , handle directories

NOOPERAND=1
NOSUCHFILE=2

TRASHPATH="/home/$USER/.local/share/Trash"
TRASHPATHROOT="/root/.local/share/Trash"

RECURSIVE_FLAG=0

usage(){
# $1 = error code ,  $2 = any file or argument name to be shown(like a file name when getting NOSUCHFILE error)
    case $1 in

    $NOOPERAND)
        echo "$0 : missing operand" ;
        echo "Try '$0 --help' for more information" ;;
    
    $NOSUCHFILE)
        echo "rm: cannot remove '$2': No such file or directory" ;;

    $HELP)
        echo "This is the help section which is incomplete" ;;


    *)
        echo something else ;;
    
    esac
}



deleteFromTrash(){
    if [ -e "$TRASHPATH/files/$filebasename" ]; then 
        rm -r "$TRASHPATH/files/$filebasename" ; 
        rm "$TRASHPATH/info/$filebasename.trashinfo"
    fi
}



copyToTrashAndWriteInfo(){

# $1 = relative filepath that is exisiting in the filesystem

echo "Args = $@"
filebasename=$(basename $1)
filefullpath=$(realpath $1)
filedirname=$(dirname $filefullpath)

filename=$1  # Original filename
readonly filename

copyToTrash(){
    # $1 = relative filepath that is exisiting in the filesystem

    if ! test -e $filename
    then echo $filename does not exist ! ; return 1
    fi

    # start the copy process
    duplicateNumber=0

    while test 1 -eq 1
    do
    echo "duplicate Number = $duplicateNumber"

    # first time try to move to trash
    if test $duplicateNumber -eq 0
        then
            if ! test -e "$TRASHPATH/files/$filebasename"
            then
                cp -r "$filename"  "$TRASHPATH/files/$filebasename" -n
                if test $? -eq 0
                    then 
                    return 0 ; 
                else 
                    echo "Error copying the $filename to trash. Trying to move $filename with the name $filename ($duplicateNumber)"
                    return 1 ; 
                fi
            fi

    # if file already present write duplicate filenames followed by duplicate Number
        else
            if ! test -e "$TRASHPATH/files/$filebasename ($duplicateNumber)"
            then
                cp -r $filename "$TRASHPATH/files/$filebasename ($duplicateNumber)"
                if test $? -eq 0
                then
                    filebasename="$filebasename ($duplicateNumber)" 
                    filefullpath="$(realpath $filedirname/"$filebasename")"
                    return 0 ; 
                else
                    echo "Error copying the $filename to trash. Trying to move $filename with the name $filename ($duplicateNumber)"
                    return 1 ; 
                fi
            fi

    fi
    
    ((duplicateNumber++))

    done
    }

    writeTrashInfo(){
        #function Depends on variables filefullpath , filebasename
        # The filefullpath can also be modified filename with the duplicate number
        # The filebasename can  also be modified filename with the duplicate number

        trashmsg="[Trash Info]\nPath=$(realpath $filename)\nDeletionDate=$(date -Is)"
        echo -e $trashmsg | tee "$TRASHPATH/info/$filebasename.trashinfo"
    }

    copyToTrash  &&  writeTrashInfo  # main calls
}


main(){

    # arg_f=0
    # arg_d=0
    # arg_i=0
    # arg_I=0
    # arg_v=0
    # arg_help=0
    # arg_version=0
    # arg_one_file_system=0
    # arg_no_preserve_root=0

    OPTIONS_ONLY_ARGS=()
    FILES_ONLY_ARGS=() #array which contains only those parameters which are files and directories 

    echo "Resursive flag = $recursiveFlag"    


    exit 0 
    for file in $@
    do
        if test -e $file && test -r $file
        then
            set -x
            
            copyToTrashAndWriteInfo $file
            rm $file  || deleteFromTrash 
        fi
    done
}


handleArguments(){
    # requires the argument array of the script $@

    if [ $# -eq 0 ] ; then 
        usage 1
    fi

    while getopts ":rR" opt ; do
        case $opt in 

            r) RECURSIVE_FLAG=1 ;;
            R) RECURSIVE_FLAG=1 ;;

        esac
    done

    for arg in $@ ; do 
        case $arg in 
            '--recursive') RECURSIVE_FLAG=1 ;; 
        esac
    done

}




handleArguments $@
main $@