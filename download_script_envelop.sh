PROG=$1
ITER=$2

shift 2

$PROG $@

rm $SEMAPHORES/READY/$ITER.lock
