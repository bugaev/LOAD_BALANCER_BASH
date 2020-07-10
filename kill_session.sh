trap '' SIGINT

really_kill=$2
${really_kill:=false}
$really_kill && echo 'It will hurt!'
for pid in `pgrep -s $1`
do
 if [ $pid -ne $1 ]
 then
  if $really_kill
  then
   echo "killing child $pid : `readlink -f /proc/$pid/exe`"
  else
   echo "found child $pid : `readlink -f /proc/$pid/exe`"
  fi
 else
  if $really_kill
  then
   echo "killing parent $pid : `readlink -f /proc/$pid/exe`"
  else
   echo "found parent $pid : `readlink -f /proc/$pid/exe`"
  fi
 fi
 $really_kill && echo 'REALLY KILLING!'
 $really_kill && kill $pid
done
