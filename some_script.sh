#trap "echo somescript got SIGINT; exit" SIGINT
SLEEP_TIME=${1}s
sleep $SLEEP_TIME
downloaded_file=~/tmp/tmp_$1.tmp
test -e $downloaded_file && rm $downloaded_file
echo some_script done

