MAX_DOWNLOADED_OBJ=30

mkdirs()
{
  local i
  cd $ROOTDIR
  TARGET_DIR=$(echo ${dirs[@]} | tr ' ' '/')
  echo making target directory: $TARGET_DIR
  for ((i = 0; i < ${#dirs[@]}; i++))
  do
   if test -e ${dirs[$i]}
   then
    command="cd ${dirs[$i]}"
    if $debug
    then
     echo $command
    fi
    $command
   else
    command="mkdir ${dirs[$i]}"
    if $debug
    then
     echo $command
    fi
    $command
    if test -e ${dirs[$i]}
    then
     command="cd ${dirs[$i]}"
     if $debug
     then
      echo $command
     fi
     $command
    else
     return -1
    fi
   fi 
  done
  echo -----------------
}

OBSERVERDIR=$(pwd)
ROOTDIR=$(dirname $0)
cd $ROOTDIR
ROOTDIR=$(pwd)
cd $OBSERVERDIR

TMPDIR=$(pwd)
dirs=($ROOTDIR SEMAPHORES READY)
mkdirs
cd $TMPDIR

if test -n "$1"
then
 prog_to_execute=$1 
else
 prog_to_execute=$ROOTDIR/some_download_script.sh
fi

if ! test -x $prog_to_execute
then
 echo Error in $0: $prog_to_execute is not an executable.
 exit 1
fi

if test -n "$2"
then
 prog_info=$2 
else
 prog_info=$ROOTDIR/some_download_info_script.sh
fi

if ! test -x $prog_info
then
 echo Error in $0: $prog_info is not an executable.
 exit 1
fi


if test -n "$3"
then
 param_list=$3 
else
 echo "Using example_params.lst as the default list of parameters"
 param_list=$ROOTDIR/SEMAPHORES/example_params.lst
fi

NITER=$(cat $param_list | wc -l)
echo Iterations: $NITER
for ((i = 0; i < NITER; i++))
do
 touch $ROOTDIR/SEMAPHORES/READY/$i.lock
done
rm -f $ROOTDIR/SEMAPHORES/READY/*.ok

export SEMAPHORES=$ROOTDIR/SEMAPHORES

iter=0
while read param
do
 echo Buffer status: $($prog_info)/$MAX_DOWNLOADED_OBJ
 command="$ROOTDIR/download_script_envelop.sh $prog_to_execute  $iter $param"
 echo $command
 $command
 echo $($prog_info) > $SEMAPHORES/READY/$iter.ok
 
 iter=$((iter + 1))
 test "$iter" -eq "$NITER" && break 999
#echo prog_info: $($prog_info)
 cnt=0
 while ! test "$($prog_info)" -lt "$MAX_DOWNLOADED_OBJ"
 do
  test "$cnt" -eq "0" && echo "Buffer is full: $($prog_info)/$MAX_DOWNLOADED_OBJ"
  cnt=$((cnt + 1))
# echo prog_info: $($prog_info)
  sleep 10s
 done
done < $param_list
echo "All files have been downloaded!"
