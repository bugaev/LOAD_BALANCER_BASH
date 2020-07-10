#!/bin/bash
# vim:tw=999:nowrap

# accepts arguments:
# 1: (optional) script to parallelize


#--------- BEGIN USER-DEFINED PARAMETERS ----------
WAIT_FIRST_PROC=60s
NMBR_PROC_WAIT=3

hostname=$(hostname)

case "$hostname" in
 jupiter*)
  nodes=( 	jupiter 	 io  	galileo 	cassini 	megadon		monolith	europa 	callisto	ganymede	jovian	marduk	)
  methods=(   	    ssh 	ssh  	ssh     	ssh 		ssh     	ssh    		ssh     ssh 		ssh		ssh	ssh	)
  max_nrunning=(      1		  1  	1		1 		1       	2      		1       1 		1		1	1	) #<---- This is my limit of maximum.
# max_nrunning=(      2		 16  	16		16 		8       	8      		8       8 		8		4	4	) #<---- This is my limit of maximum.
     ip=( 	jupiter  	 io  	galileo		cassini 	megadon 	monolith 	europa 	callisto 	ganymede	jovian	marduk	) 
 ;;
 teradon*)
  nodes=( optimus teradon )
  methods=(   ssh     ssh )
  max_nrunning=(0       20)
     ip=( optimus teradon ) 
 ;;
 optimus*)
  nodes=( optimus teradon )
  methods=(   ssh     ssh )
  max_nrunning=(2       0)
     ip=( optimus teradon ) 
 ;;
 *) echo Unknown hostname: $hostname; exit 1;
esac



debug=false
#-------------- END OF PARAMETERS -----------------

INTERRUPTED=false
OBSERVERDIR=$(pwd)
ROOTDIR=$(dirname $0)
cd $ROOTDIR
ROOTDIR=$(pwd)
cd $OBSERVERDIR

nnodes=${#nodes[@]}

export SEMAPHORES=$ROOTDIR/SEMAPHORES

launched_proc=0

echo shell ID: $$



int_trapfunc()
{
 INTERRUPTED_SOFTLY=true
 local inode
 local pid
 local menu_killall=false  
 local menu_delay=false
 local menu_nodes=false
 local menu_info=false

 clear
 PS3='Please enter a choice from the above menu: '

 select CHOICE in "Kill All" "Setup Delay" "Setup Nodes" "Continue" "Show Info"
 do
  case "$CHOICE" in

              "") echo Hit Enter to see menu again!
                  continue
  ;;
      "Show Info") menu_info=true;   break
  ;;   
      "Kill All") menu_killall=true;   break
  ;;   
   "Setup Delay") menu_delay=true;     break
  ;;
   "Setup Nodes") menu_nodes=true;     break
  ;;
      "Continue") echo Return to computations; return
  ;;
               *) echo Return to computations; return
  ;;
  esac
 done

 if $menu_delay
 then
  select CHOICE in "Delay Interval" "Procs to Wait" "Continue"
  do
   case "$CHOICE" in 

                     "") echo Hit Enter to see menu again!
		         continue
   ;;
       "Delay Interval") echo; echo -n "Enter Delay Interval: "; read WAIT_FIRST_PROC; echo Delay Interval adjusted to: $WAIT_FIRST_PROC; echo Return to computations; return;
   ;;   
        "Procs to Wait") echo; echo -n "Enter the Number of Processes to Wait for: "; read NMBR_PROC_WAIT; echo Procs to Wait adjusted to: $NMBR_PROC_WAIT; echo Return to computations; return
   ;;
             "Continue") echo Return to computations; return
   ;;
                      *) echo Return to computations; return
   ;;
   esac
  done
  return
 fi

 if $menu_nodes
 then
  select CHOICE in "optimus" "teradon" "Continue"
  do
   case "$CHOICE" in
                     "") echo Hit Enter to see menu again!
		         continue
   ;;
       "optimus") echo; echo -n "Enter Max Nodes on optimus: "; read tmp; max_nrunning[0]=$tmp; echo Maximal Number of Processess on optimus adjusted to: ${max_nrunning[0]}; echo Return to computations; return
   ;;   
       "teradon") echo; echo -n "Enter Max Nodes on teradon: "; read tmp; max_nrunning[1]=$tmp; echo Maximal Number of Processess on teradon adjusted to: ${max_nrunning[1]}; echo Return to computations; return
   ;;
      "Continue") echo Return to computations; return
   ;;
               *) echo Return to computations; return
   ;;
   esac
  done
  return
 fi

 if $menu_killall
#if true
 then
  echo 'Start killing all launched processess...'
  trap '' SIGINT
  for ((inode = 0; inode < nnodes; inode++))
  do
   if test "${max_nrunning[$inode]}" -gt 0
   then
    for pid in $(tail --lines=1 --silent $SEMAPHORES/${nodes[$inode]}/*.lock 2>/dev/null)
    do
     echo "${nodes[$inode]}: $pid""<-----------------------------------------------------"
     test "${methods[$inode]}" = "ssh" && ssh ${ip[$inode]}  "$ROOTDIR/kill_session.sh $pid true"
    done
   fi
  done
  INTERRUPTED=true
  return
 fi
 
 if $menu_info
 then
  echo 'Displaying all launched processess...'
  for ((inode = 0; inode < nnodes; inode++))
  do
   if test "${max_nrunning[$inode]}" -gt 0
   then
    for pid in $(tail --lines=1 --silent $SEMAPHORES/${nodes[$inode]}/*.lock 2>/dev/null)
    do
     echo "${nodes[$inode]}: $pid""<--------------------"
     test "${methods[$inode]}" = "ssh" && ssh ${ip[$inode]}  "$ROOTDIR/kill_session.sh $pid"
    done
   fi
  done
  echo Return to computations; return
 fi


 test $menu_continue && return
#trap int_trapfunc SIGINT
}

#trap mytrapfunc SIGQUIT
trap int_trapfunc SIGINT

if test -n "$1"
then
 prog_to_execute=$1 
else
 prog_to_execute=$ROOTDIR/some_script.sh
fi
if ! test -x $prog_to_execute
then
 echo Error in $0: $prog_to_execute is not an executable.
 exit 1
fi

if test -n "$2"
then
 param_list=$2 
else
 echo "Using example_params.lst as the default list of parameters"
 param_list=$ROOTDIR/SEMAPHORES/example_params.lst
fi




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

all_done()
{
 local i
 local result=1
 nfinished=0
 for ((i = 0; i < nnodes; i++))
 do
  nfinished_this_node=$(ls $SEMAPHORES/${nodes[$i]}/*.ok 2>/dev/null | wc -l);
  nfinished=$((nfinished + nfinished_this_node))
 done
 if test "$nfinished" -ge "$NITER"
 then
  result=0
 fi
 
 if $debug
 then
  echo "all_done: $result" 1>&2
 fi

 return $result
}

get_nrunning_this_node()
{
 local inode=$1
 local nrunning_this_node
 nrunning_this_node=$(ls $SEMAPHORES/${nodes[$inode]}/*.lock 2>/dev/null | wc -l)
 if $debug
 then
  echo "get_nrunning_this_node inode=$inode: $nrunning_this_node" 1>&2
 fi
 echo $nrunning_this_node
}


iteration_available_this_node()
{
 local inode=$1
 local iter=$2
 local result=1
#if ( ! test -e $SEMAPHORES/${nodes[$inode]}/${iter}.lock && ! test -e $SEMAPHORES/${nodes[$inode]}/${iter}.ok )
 if ( ! test -e $SEMAPHORES/${nodes[$inode]}/${iter}.lock )
 then
  result=0
 fi
 if $debug
 then
  echo "iteration_available_this_node inode=$inode iter=$iter: $result" 1>&2
 fi
 return $result
}

iteration_ready()
{
 local iter=$1
 local result=1
 if $debug
 then
  echo "calling ${FUNCNAME[0]}" 1>&2
 fi
 if ( ! test -e $SEMAPHORES/READY/${iter}.lock )
 then
  result=0
 fi
 if $debug
 then
  echo "iteration_ready iter=$iter: $result" 1>&2
 fi
 return $result
}

iteration_available()
{
 local result=0
 local iter=$1
 local inode
 if $debug
 then
  echo "calling ${FUNCNAME[0]}" 1>&2
 fi

 if iteration_ready $iter
 then
  for ((inode = 0; inode < nnodes; inode++))
  do
   if ( ! iteration_available_this_node $inode $iter ) 
   then
    result=1
    if $debug
    then
     echo "iteration_available iter=$iter: $result" 1>&2
    fi
    return $result
   fi
  done
 else
  result=1
 fi

 if $debug
 then
  echo "iteration_available iter=$iter: $result" 1>&2
 fi
 return $result
}

lock_iter()
{
 local inode=$1
 local iter=$2
 if $debug
 then
  echo "calling lock_iter inode=$inode iter=$iter" 1>&2
 fi
 touch $SEMAPHORES/${nodes[$inode]}/${iter}.lock
 launched_proc=$((launched_proc + 1))
}

get_nrunning()
{
 local i
 local nrunning=0
 if $debug
 then
  echo "calling ${FUNCNAME[0]}" 1>&2
 fi
 for ((i = 0; i < nnodes; i++))
 do
  nrunning_this_node=$(get_nrunning_this_node $i)
  nrunning=$((nrunning + nrunning_this_node))
 done
 if $debug
 then
  echo "get_nrunning: $nrunning" 1>&2
 fi
 echo $nrunning
}


#Initialize semaphore directories for different nodes:
if $debug
then
 echo "nnodes: $nnodes" 1>&2
fi
TMPDIR=$(pwd)
dirs=($ROOTDIR SEMAPHORES READY)
mkdirs
for ((inodes=0; inodes<$nnodes; inodes++))
do
 dirs=($ROOTDIR SEMAPHORES ${nodes[$inodes]})
 mkdirs
done
cd $TMPDIR


NITER=$(cat $param_list | wc -l)
echo Iterations: $NITER

for ((inode = 0; inode < nnodes; inode++))
do
 rm -f $SEMAPHORES/${nodes[$inode]}/*.lock
 rm -f $SEMAPHORES/${nodes[$inode]}/*.ok
 rm -f $SEMAPHORES/${nodes[$inode]}/*.int
done


all_pars_used=false
last_used_iteration=-1

#loop
while ! all_done 
do
 $INTERRUPTED && break 999
 nrunning=$(get_nrunning)

#if $debug
#then
#  echo "before searching for non-used parameters nrunning: $nrunning, nfinished: $nfinished, all_pars_used: $all_pars_used"
#fi

 if ( ! $all_pars_used )
 then
  for ((inode = 0; inode < nnodes; inode++))
  do
   $INTERRUPTED && break 999
   if $debug
   then
    echo "looking for empty slots in node: $inode" 1>&2
   fi
   nrunning_this_node=$(get_nrunning_this_node $inode)
   if test "$nrunning_this_node" -lt "${max_nrunning[$inode]}"
   then
#   for ((iter=$((last_used_iteration + 1)); iter<NITER; iter++))
#   do
    iter=$((last_used_iteration + 1))
     $INTERRUPTED && break 999
     if ( iteration_available $iter )
     then
      if $debug
      then
       echo "Proceeding to params No. $iter" 1>&2
      fi
      nrunning_this_node=$((nrunning_this_node + 1))
      line=$((iter+1))
      param=$(sed -n "${line}p" $param_list)
      $INTERRUPTED && break 999
      lock_iter $inode $iter
      #                                   1                2                3                   4     5              6
      command="$ROOTDIR/script_envelop.sh $prog_to_execute ${nodes[$inode]} ${methods[$inode]}  $iter ${ip[$inode]}  $param"
      echo "${nodes[$inode]} >" $command
      echo
      $INTERRUPTED && break 999
      $command &
      last_used_iteration=$iter
      if test "$launched_proc" -le "$NMBR_PROC_WAIT"
      then
       $INTERRUPTED && break 999
       echo "Waiting $WAIT_FIRST_PROC ($launched_proc/$NMBR_PROC_WAIT)"
       time_before=$SECONDS
       cycle_done=false
       while ! $cycle_done
       do
        sleep $WAIT_FIRST_PROC && cycle_done=true
       done
#      echo time_before: $time_before
#      if $INTERRUPTED_SOFTLY
#      then
#       time_after=$SECONDS
#       echo time_after: $time_after
#       echo Interrupted softly for $(($time_after - $time_before)) seconds.
#       INTERRUPTED_SOFTLY=false
#      fi
      fi
      $INTERRUPTED && break 999
     fi
     if $debug
     then
      echo "${nodes[$inode]}: running simultaneously $nrunning_this_node processes out of ${max_nrunning[$inode]}" 1>&2
     fi
#    test "$nrunning_this_node" -ge "${max_nrunning[$inode]}" && break # currently the maximum number of concurrent processes is running -> stop looking for new parameters for this node
#   done

#   if test "$nrunning_this_node" -lt "${max_nrunning[$inode]}"
    NITER1=$((NITER - 1))
    if test "$last_used_iteration" -eq "$NITER1"
    then
     $INTERRUPTED && break 999
     echo "All parameters have been used... Waiting for the last processes to finish" 1>&2
     all_pars_used=true
     break # We need not to iterate through nodes further - all parameter sets are already used.
    fi
   fi
  done
 fi

 $INTERRUPTED && break 999
 sleep 2s

done

echo "All Done!"
