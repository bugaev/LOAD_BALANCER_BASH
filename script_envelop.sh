trap '' SIGINT

debug=false

PROG=$1
node=$2
method=$3
ITER=$4
IP=$5

INTERRUPTED=false


int_trapfunc()
{
 echo script_envelop got $ITER SIGINT
 exit
}


OBSERVERDIR=$(pwd)

if $debug
then
 echo "script_envelop node: $node, method: $method, PROGDIR: $PROGDIR" 1>&2
fi

shift 5
#echo $@

echo $$ >> $SEMAPHORES/$node/$ITER.lock

case "$method" in
 direct) $debug && echo 'direct method' ; $PROG $@; test "$?" -ne 0 && INTERRUPTED=true; echo INTERRUPTED: $INTERRUPTED  ;; 
    ssh) $debug && echo 'ssh method'    ; ssh $IP "source ~bugaev/.bash_profile; cd $OBSERVERDIR; $PROG $@ & echo \$\$ > $SEMAPHORES/$node/$ITER.lock; false; wait; exit 0"; test "$?" -ne 0 && INTERRUPTED=true; echo INTERRUPTED: $INTERRUPTED;;
      *) echo 'Unknown method!'; exit 1 ;;
esac

$INTERRUPTED && touch $SEMAPHORES/$node/$ITER.int # interrupted
$INTERRUPTED || touch $SEMAPHORES/$node/$ITER.ok  # success
echo removing $ITER.lock
rm $SEMAPHORES/$node/$ITER.lock
