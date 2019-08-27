level=6
max_rpl=4
max_fanout=5

function inc {
local -n num=$1
local -n digits=$2
local bound=$3
local cnt=$4
# next configuration
num=$((num+1))
local int=$num
# parse it
for l in `seq $cnt -1 1`; do
  digit=$((int%bound))
  int=$((int/bound))
  digits[$l]=$digit
done
# overflow if int is not 0
return ${int}
}

rpl_int=0
while [[ 1 ]]; do
  inc rpl_int rpl $max_rpl $level
  if [[ $? -ne 0 ]]; then break; fi
  # skip invalid configurations
  for i in ${rpl[*]}; do
    if [[ $i -eq 0 ]]; then continue 2; fi
  done
  ltype_int=0
  while [[ 1 ]]; do
    inc ltype_int ltype 3 $level
    if [[ $? -ne 0 ]]; then break; fi
    # skip invalid configurations
    if [[ ${ltype[1]} -ne 0 ]]; then continue; fi # 1st must be T
    if [[ ${ltype[$level]} -ne 2 ]]; then continue; fi # Last must be L
    last_type=0;
    for t in ${ltype[*]}; do
      if [[ $t -lt $last_type ]]; then continue 2; fi # TTT NNN LLL
      last_type=$t
    done
    for l in `seq 1 $level`; do
      if [[ ${ltype[$l]} -eq 0 && ${rpl[$l]} -lt 2 ]]; then continue 2; fi
      if [[ ${ltype[$l]} -eq 1 && ${rpl[$l]} -lt 2 ]]; then continue 2; fi
      if [[ ${ltype[$l]} -eq 2 && ${rpl[$l]} -gt 1 ]]; then continue 2; fi
    done
    fanout_int=0
    while [[ 1 ]]; do
      inc fanout_int fanout $max_fanout $level
      if [[ $? -ne 0 ]]; then break; fi
      # skip invalid configurations
      for i in ${fanout[*]}; do
        if [[ $i -eq 0 ]]; then continue 2; fi
      done
      if [[ ${fanout[1]} -ne 1 ]]; then continue; fi
      for l in `seq 2 $level`; do
        if [[ ${ltype[$l]} -eq 0 && ${fanout[$l]} -ne ${rpl[l-1]} ]]; then continue 2; fi
        if [[ ${ltype[$l]} -ne 0 && ${fanout[$l]} -lt $((2*${rpl[l-1]})) ]]; then continue 2; fi
      done

      printf '%s' '--level_type=O'
      for c in ${ltype[*]}; do
        case $c in 
          0) printf ',T';;
          1) printf ',N';;
          2) printf ',L';;
          *) printf "unknown type";;
         esac
      done
      printf ' %s' '--rpl=0'
      printf ',%s' "${rpl[@]}"
      printf ' %s' '--rpl_multiplier=0'
      for l in `seq 1 $level`; do
        case $l in 
          1) printf ',7';;
          *) if [[ ${ltype[$l]} -ne 0 ]]; then printf ',1'; else printf ',3'; fi
            ;;
         esac
      done
      printf ' %s' '--fanout=0'
      printf ',%s' "${fanout[@]}"
      echo
    done
  done
done
