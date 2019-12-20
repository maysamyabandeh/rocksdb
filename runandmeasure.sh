conf="$1"
dbdir="./dbbench"
bin="/home/myabandeh/rocksdb/db_bench"
# The name of the disk on which we run the benchmark
dname=vda
#dname=sda
nw=1000000

echo $conf
#conf="--level_type=O,T,T,N,L --rpl=0,4,3,2,1 --rpl_multiplier=0,7,4,3,1 --fanout=0,1,4,4,5"

myargs="
  --stats_dump_period_sec=1 \
  --value_size=20480 \
  --max_background_jobs=16 \
  --max_bytes_for_level_multiplier=2 \
  --max_write_buffer_number=2 \
  --max_bytes_for_level_base=33554432 \
  --dump_malloc_stats=false \
  --level0_slowdown_writes_trigger=30 \
  --num_logical_levels=6 \
  --cache_size=200000000 \
  --wal_bytes_per_sync=1048576 \
  $conf
"
#sfx=j${j}.pri${cpri}.dyn${dyn}
sfx=adaptive

echo filling the db at `date` ...
vmstat 1 >& vw.$sfx &
vpid=$!
iostat -kx 1 >& iw.$sfx &
ipid=$!
$bin --benchmarks="fillrandom,stats" --use_existing_db=0 --db=$dbdir --num=$nw $defargs $myargs >& ow.$sfx
kill $vpid
kill $ipid
du -hs $dbdir > dw.$sfx
fwamp=`cat $dbdir/LOG | grep STAT -A100 | grep Sum | awk '{print $12}' | tail -1`

# Let the ongoing compactions to finish
echo reading the db at `date` ...
vmstat 1 >& vr.$sfx &
vpid=$!
iostat -kx 1 >& ir.$sfx &
ipid=$!
$bin --benchmarks="readrandom,stats" --use_existing_db=1 --db=$dbdir --num=$nw --duration=60 $defargs $myargs >& or.$sfx
kill $vpid
kill $ipid
du -hs $dbdir > dr.$sfx
rwamp=`cat $dbdir/LOG | grep STAT -A100 | grep Sum | awk '{print $12}' | tail -1`

# measuring performance under a realistice read-write workload
echo transacting the db at `date` ...
vmstat 1 >& vt.$sfx &
vpid=$!
iostat -kx 1 >& it.$sfx &
ipid=$!
$bin --benchmarks="seekrandomwhilewriting,stats" --use_existing_db=1 --db=$dbdir --num=$nw --duration=7200 $defargs --rate_limiter_bytes_per_sec=50000000  --threads=16 --benchmark_read_rate_limit=400000 --use_direct_reads=true --statistics --report_bg_io_stats=1 --reshape  $myargs >& ot.$sfx
kill $vpid
kill $ipid
du -hs $dbdir > dt.$sfx
twamp=`cat $dbdir/LOG | grep STAT -A100 | grep Sum | awk '{print $12}' | tail -1`

echo ...done at `date`

# Sample line:
# readrandom   :     104.110 micros/op 9605 ops/sec;  142.3 MB/s (21914 of 288999 found)
nr=`grep readrandom or.$sfx | awk '{print $(NF-1)}'`
nt=`grep whilewriting ot.$sfx | awk '{print $(NF-1)}'`

echo iostat metrics > hw.$sfx
printf "Stage\tNsamp\tr/s\trMB/s\tw/s\twMB/s\trGB\twGB\tr/i\tw/i\trkb/i\twkb/i\tMrows\tw-amp\n" >> hw.$sfx
c=$( grep -a $dname iw.$sfx | wc -l )
grep -a $dname iw.$sfx | tail -$(( $c - 1 )) > tmp.iw

c=$( grep -a $dname ir.$sfx | wc -l )
grep -a $dname ir.$sfx | tail -$(( $c - 1 )) > tmp.ir

c=$( grep -a $dname it.$sfx | wc -l )
grep -a $dname it.$sfx | tail -$(( $c - 1 )) > tmp.it

cat tmp.iw | awk '{ rs += $4; ws += $5; rkb += $6; wkb += $7; c += 1 } END { printf "fill\t%s\t%.0f\t%.1f\t%.0f\t%.1f\t%.1f\t%.1f\t%.5f\t%.5f\t%.5f\t%.5f\t%.1f\t%.1f\n", c, rs/c, rkb/1024.0/c, ws/c, wkb/1024.0/c, rkb/(1024*1024.0), wkb/(1024*1024.0), rs/c/q, rkb/c/q, ws/c/q, wkb/c/q, q/1000000.0, wamp }' q=$nw wamp=$fwamp >> hw.$sfx
cat tmp.ir | awk '{ rs += $4; ws += $5; rkb += $6; wkb += $7; c += 1 } END { printf "read\t%s\t%.0f\t%.1f\t%.0f\t%.1f\t%.1f\t%.1f\t%.5f\t%.5f\t%.5f\t%.5f\t%.1f\t%.1f\n", c, rs/c, rkb/1024.0/c, ws/c, wkb/1024.0/c, rkb/(1024*1024.0), wkb/(1024*1024.0), rs/c/q, rkb/c/q, ws/c/q, wkb/c/q, q/1000000.0, wamp }' q=$nr wamp=$rwamp >> hw.$sfx
cat tmp.it | awk '{ rs += $4; ws += $5; rkb += $6; wkb += $7; c += 1 } END { printf "tran\t%s\t%.0f\t%.1f\t%.0f\t%.1f\t%.1f\t%.1f\t%.5f\t%.5f\t%.5f\t%.5f\t%.1f\t%.1f\n", c, rs/c, rkb/1024.0/c, ws/c, wkb/1024.0/c, rkb/(1024*1024.0), wkb/(1024*1024.0), rs/c/q, rkb/c/q, ws/c/q, wkb/c/q, q/1000000.0, wamp }' q=$nt wamp=$twamp >> hw.$sfx
cat tmp.iw tmp.ir tmp.it | awk '{ rs += $4; ws += $5; rkb += $6; wkb += $7; c += 1 } END { printf "totl\t%s\t%.0f\t%.1f\t%.0f\t%.1f\t%.1f\t%.1f\t%.5f\t%.5f\t%.5f\t%.5f\t%.1f\n", c, rs/c, rkb/1024.0/c, ws/c, wkb/1024.0/c, rkb/(1024*1024.0), wkb/(1024*1024.0), rs/c/q, rkb/c/q, ws/c/q, wkb/c/q, q/1000000.0 }' q=$((nw+nr+nt))  >> hw.$sfx

c=$( grep -av swpd vw.$sfx | wc -l )
grep -av swpd vw.$sfx | tail -$(( $c - 1 )) > tmp.vw

c=$( grep -av swpd vr.$sfx | wc -l )
grep -av swpd vr.$sfx | tail -$(( $c - 1 )) > tmp.vr

c=$( grep -av swpd vt.$sfx | wc -l )
grep -av swpd vt.$sfx | tail -$(( $c - 1 )) > tmp.vt

echo >> hw.$sfx
echo vmstat metrics >> hw.$sfx
printf "Stage\tsamp\tcs/s\tcpu/c\tcs/q\tcpu/q\n" >> hw.$sfx
cat tmp.vw        | awk '{ cs += $12; cpu += $13 + $14; c += 1 } END { printf "fill\t%s\t%.0f\t%.1f\t%.3f\t%.6f\n", c, cs/c, cpu/c, cs/c/q, cpu/c/q }' q=$nw>> hw.$sfx
cat        tmp.vr | awk '{ cs += $12; cpu += $13 + $14; c += 1 } END { printf "read\t%s\t%.0f\t%.1f\t%.3f\t%.6f\n", c, cs/c, cpu/c, cs/c/q, cpu/c/q }' q=$nr>> hw.$sfx
cat        tmp.vt | awk '{ cs += $12; cpu += $13 + $14; c += 1 } END { printf "tran\t%s\t%.0f\t%.1f\t%.3f\t%.6f\n", c, cs/c, cpu/c, cs/c/q, cpu/c/q }' q=$nt>> hw.$sfx
cat tmp.vw tmp.vr tmp.vt | awk '{ cs += $12; cpu += $13 + $14; c += 1 } END { printf "totl\t%s\t%.0f\t%.1f\t%.3f\t%.6f\n", c, cs/c, cpu/c, cs/c/q, cpu/c/q }' q=$((nw+nr+nt))>> hw.$sfx

w1=$( grep -a "^Cumulative compaction" ow.$sfx | tail -1 | awk '{ print $3 }' )
r1=$( grep -a "^Cumulative compaction" ow.$sfx | tail -1 | awk '{ print $9 }' )

w2=$( grep "^Cumulative compaction" or.$sfx | tail -1 | awk '{ print $3 }' )
r2=$( grep "^Cumulative compaction" or.$sfx | tail -1 | awk '{ print $9 }' )

w3=$( grep "^Cumulative compaction" ot.$sfx | tail -1 | awk '{ print $3 }' )
r3=$( grep "^Cumulative compaction" ot.$sfx | tail -1 | awk '{ print $9 }' )

wt=$( echo "$w1 + $w2 + $w3" | bc )
rt=$( echo "$r1 + $r2 + $r3" | bc )
echo "w1 w2 w3 r1 r2 r3 :: wt rt" >> hw.$sfx
echo $w1 $w2 $w3 $r1 $r2 $r3 :: $wt $rt >> hw.$sfx
