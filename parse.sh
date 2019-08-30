base=exprtmp
output=output-tmp.txt
echo -e "conf\tfill rMB/s\tfill wMB/s\tfill ops\tfill cpu/q\tread rMB/s\tread wMB/s\tread ops\tread cpu/q\ttran rMB/s\ttran wMB/s\ttran ops\ttran cpu/q" > $output

for d in `ls $base`; do
ls $base/$d/conf.txt 2>/dev/null 1>/dev/null
if [[ $? -ne 0 ]]; then continue; fi

conf=`cat $base/$d/conf.txt`

fillr=`cat $base/$d/hw.adaptive | grep fill | head -1 | awk '{print $4}'`
fillw=`cat $base/$d/hw.adaptive | grep fill | head -1 | awk '{print $6}'`
fillcpu=`cat $base/$d/hw.adaptive | grep fill | tail -1 | awk '{print $6}'`
fillops=`cat $base/$d/ow.adaptive | grep fillrandom | awk {'print $7}'`

readr=`cat $base/$d/hw.adaptive | grep read | head -1 | awk '{print $4}'`
readw=`cat $base/$d/hw.adaptive | grep read | head -1 | awk '{print $6}'`
readcpu=`cat $base/$d/hw.adaptive | grep read | tail -1 | awk '{print $6}'`
readops=`cat $base/$d/or.adaptive | grep readrandom | awk {'print $7}'`

tranr=`cat $base/$d/hw.adaptive | grep tran | head -1 | awk '{print $4}'`
tranw=`cat $base/$d/hw.adaptive | grep tran | head -1 | awk '{print $6}'`
trancpu=`cat $base/$d/hw.adaptive | grep tran | tail -1 | awk '{print $6}'`
tranops=`cat $base/$d/ot.adaptive | grep readwhilewriting | awk {'print $7}'`

echo -e "$conf\t$fillr\t$fillw\t$fillops\t$fillcpu\t$tranr\t$tranw\t$tranops\t$trancpu\t$readr\t$readw\t$readops\t$readcpu" >> $output

done
