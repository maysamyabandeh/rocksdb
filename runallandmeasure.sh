dbdir="./dbbench"
dname=vda
nw=100000

conf="--level_type=O,T,T,N,L --rpl=0,4,3,2,1 --rpl_multiplier=0,7,4,3,1 --fanout=0,1,4,4,5"

i=0
IFS=$'\n'
for conf in `cat /home/myabandeh/rocksdb/combination.txt`; do
  mkdir $i
  cd $i
  echo "$conf" > conf.txt
  /home/myabandeh/rocksdb/runandmeasure.sh "$conf"
  cd ..
  i=$((i+1))
done
