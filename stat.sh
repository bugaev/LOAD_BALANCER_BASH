progdir=$(dirname $0)
cd $progdir/SEMAPHORES
clear

timestamps()
{
 if test "$1" != "total"
 then
  ls -l --time-style='+%s' $1/*.ok 2>/dev/null | gawk '{print $6}' | sort | gawk 'BEGIN{first=0}; NR==1 {first=$0}; {diff=$0 - first; print diff}'
 else
  ls -l --time-style='+%s' */*.ok | grep -v READY 2>/dev/null | gawk '{print $6}' | sort | gawk 'BEGIN{first=0}; NR==1 {first=$0}; {diff=$0 - first; print diff}'
 fi
}


gnuplot_script()
{
#local node=$1
 term_wid=110
 term_hgt=50

 max_diff=$(timestamps $1 | tail -1)
#echo max_diff: $max_diff 1>&2
 if test "$max_diff" -gt 86400
 then
  scale=86400
  xlabel="days"
 elif test "$max_diff" -gt 3600
 then
  scale=3600
  xlabel="hours"
 elif test "$max_diff" -gt 60
 then
  scale=60
  xlabel="minutes"
 else
  scale=1
  xlabel="seconds"
 fi
 cat << EOF
 term_wid=$term_wid
 term_hgt=$term_hgt
 set title "$1"
 set term dumb term_wid term_hgt
 set autoscale
 set nokey
 set xlabel "$xlabel"
 set ylabel "iterations"
 plot [][0:] "-" using (\$1/$scale):0 with dots
EOF
 timestamps $1
}
 host=$(hostname)
 case "$host" in 
  io*) nodes="io ionode00 ionode01 ionode02 ionode03 ionode04 ionode05 total" ;
       nodes1="io ionode00 ionode01 ionode02 ionode03 ionode04 ionode05" ;;
    *) nodes="teradon optimus galileo jupiter megadon monolith callisto europa io total";
       nodes1="teradon optimus galileo jupiter megadon monolith callisto europa io" ;; 
 esac

 while true
 do
  clear
  for node in $(echo $nodes)
  do
   node_cnt=$(timestamps $node | wc -l)
#  echo node_cnt: "-->"$node_cnt"<--"
   test "$node_cnt" -le 1 && continue
   clear
   tput home
   gnuplot <(gnuplot_script $node)
   sleep 1s
  done
  tput home
  all_ok=0
  printf "%s\n" "+--------------------+"
  for i in $(echo $nodes1)
  do
   ok=$(ls $i/*.ok 2>/dev/null | wc -l)
   printf "%s%10s: %4d%5s\n" "|" $i $ok "|"
   all_ok=$((all_ok + ok))
  done

  printf "%s\n%s%12s%4d%5s\n" "+--------------------+" "|" "total: " $all_ok "|"
  printf "%s\n" "+--------------------+"
   sleep 20s
 done

#while true
#do
# all_ok=0
# for i in galileo jupiter megadon monolith callisto europa
# do
#  ok=$(ls $i/*.ok | wc -l)
#  printf "%10s: %d\n" $i $ok
#  all_ok=$((all_ok + ok))
# done
# printf "%s\n%12s%d\n" "--------------------" "total: " $all_ok
# sleep 5s
# clear
#done
