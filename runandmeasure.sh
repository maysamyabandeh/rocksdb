dbdir="./dbbench"
dname=vda

#myargs="--max_background_jobs=$j --compaction_pri=$cpri --level_compaction_dynamic_level_bytes=$dyn"
#defargs="--key_size=20 --value_size=$vsz -stats_interval_seconds=10 --stats_per_interval=1"
myargs="
  --stats_dump_period_sec=1 \
  --value_size=204800 \
  --max_background_jobs=16 \
  --duration=30 \
  --num=500000000 \
  --max_bytes_for_level_multiplier=2 \
  --max_write_buffer_number=2 \
  --max_bytes_for_level_base=33554432 \
  --dump_malloc_stats=false \
  --level0_slowdown_writes_trigger=30 \
  --num_logical_levels=6 \
  --level_type=O,T,T,T,N,N,L \
  --rpl=0,4,3,2,2,2,1 \
  --rpl_multiplier=0,7,4,3,1,1,1 \
  --fanout=0,1,4,2,2,2,2 \
"
#sfx=j${j}.pri${cpri}.dyn${dyn}
sfx=adaptive

vmstat 1 >& vw.$sfx &
vpid=$!
iostat -kx 1 >& iw.$sfx &
ipid=$!
./db_bench --benchmarks="fillrandom,stats" --use_existing_db=0 --db=$dbdir $defargs $myargs >& ow.$sfx
kill $vpid
kill $ipid
du -hs $dbdir > dw.$sfx
nr=`grep found ow.$sfx | awk '{print $(NF-1)}'`

: '
vmstat 1 >& vr.$sfx &
vpid=$!
iostat -kx 1 >& ir.$sfx &
ipid=$!
./db_bench --benchmarks="readrandom,stats" --use_existing_db=1 --db=$dbdir $defargs $myargs >& or.$sfx
kill $vpid
kill $ipid
du -hs $dbdir > dr.$sfx
'

echo iostat metrics > hw.$sfx
printf "Nsamp\tr/s\trMB/s\tw/s\twMB/s\trGB\twGB\tr/i\tw/i\trkb/i\twkb/i\tMrows\n" >> hw.$sfx
c=$( grep $dname iw.$sfx | wc -l )
grep $dname iw.$sfx | tail -$(( $c - 1 )) > tmp.iw

: '
c=$( grep $dname ir.$sfx | wc -l )
grep $dname ir.$sfx | tail -$(( $c - 1 )) > tmp.ir
'

cat tmp.iw tmp.ir | awk '{ rs += $4; ws += $5; rkb += $6; wkb += $7; c += 1 } END { printf "%s\t%.0f\t%.1f\t%.0f\t%.1f\t%.1f\t%.1f\t%.5f\t%.5f\t%.5f\t%.5f\t%.1f\n", c, rs/c, rkb/1024.0/c, ws/c, wkb/1024.0/c, rkb/(1024*1024.0), wkb/(1024*1024.0), rs/c/q, rkb/c/q, ws/c/q, wkb/c/q, q/1000000.0 }' q=$nr  >> hw.$sfx

c=$( grep -v swpd vw.$sfx | wc -l )
grep -v swpd vw.$sfx | tail -$(( $c - 1 )) > tmp.vw

: '
c=$( grep -v swpd vr.$sfx | wc -l )
grep -v swpd vr.$sfx | tail -$(( $c - 1 )) > tmp.vr
'

echo >> hw.$sfx
echo vmstat metrics >> hw.$sfx
printf "samp\tcs/s\tcpu/c\tcs/q\tcpu/q\n" >> hw.$sfx
cat tmp.vw tmp.vr | awk '{ cs += $12; cpu += $13 + $14; c += 1 } END { printf "%s\t%.0f\t%.1f\t%.3f\t%.6f\n", c, cs/c, cpu/c, cs/c/q, cpu/c/q }' q=$nr>> hw.$sfx

w1=$( grep "^Cumulative compaction" ow.$sfx | tail -1 | awk '{ print $3 }' )
r1=$( grep "^Cumulative compaction" ow.$sfx | tail -1 | awk '{ print $9 }' )

: '
w2=$( grep "^Cumulative compaction" or.$sfx | tail -1 | awk '{ print $3 }' )
r2=$( grep "^Cumulative compaction" or.$sfx | tail -1 | awk '{ print $9 }' )
'
w2=0
r2=0

wt=$( echo "$w1 + $w2" | bc )
rt=$( echo "$r1 + $r2" | bc )
echo "w1 w2 r1 r2 :: wt rt" >> hw.$sfx
echo $w1 $w2 $r1 $r2 :: $wt $rt >> hw.$sfx
