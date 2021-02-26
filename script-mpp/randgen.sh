yyfile="optimizer_subquery.yy"
db="subquery"
tport="52324"
tip="172.16.5.85"
mport="3306"
mip="172.16.5.59"

for c in  100 
do
	./gen_test.py --host $tip --port $tport --database $db$c --count $c randgen-2.2.0/conf/subquery.zz randgen-2.2.0/conf/${yyfile}
	./gen_test.py --host $mip  --port $mport  --database $db$c --count $c randgen-2.2.0/conf/subquery.zz randgen-2.2.0/conf/${yyfile}
	nohup ./run.sh $db$c $tport tiflash
done
