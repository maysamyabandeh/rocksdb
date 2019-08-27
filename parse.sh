base=expr
output=output.txt
echo -e "conf\tfill rMB/s\tfill wMB/s\tfill cpu/q\tread rMB/s\tread wMB/s\tread cpu/q" > output.txt

for d in `ls $base`; do
ls $base/$d/conf.txt 2>/dev/null 1>/dev/null
if [[ $? -ne 0 ]]; then continue; fi

conf=`cat $base/$d/conf.txt`

fillr=`cat $base/$d/hw.adaptive | grep fill | head -1 | awk '{print $4}'`
fillw=`cat $base/$d/hw.adaptive | grep fill | head -1 | awk '{print $6}'`
fillcpu=`cat $base/$d/hw.adaptive | grep fill | tail -1 | awk '{print $6}'`

readr=`cat $base/$d/hw.adaptive | grep read | head -1 | awk '{print $4}'`
readw=`cat $base/$d/hw.adaptive | grep read | head -1 | awk '{print $6}'`
readcpu=`cat $base/$d/hw.adaptive | grep read | tail -1 | awk '{print $6}'`

echo -e "$conf\t$fillr\t$fillw\t$fillcpu\t$readr\t$readw\t$readcpu" >> output.txt

done
