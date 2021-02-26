#mysql -h 127.0.0.1 -P 4000 -u root -f -D randgen_test < randgen_test.test > tidb.output 2>&1
#mysql -h 127.0.0.1 -P 5000 -u root -f -D randgen_test < randgen_test.test > mysql.output 2>&1

test_goal="hash_join"
db_name="randgen_"$test_goal
tidb_port=4002
tport="52324"
tip="172.16.5.85"
mport="3306"
mip="172.16.5.59"

if [ $# -lt 1 ]; then
    echo "default database: $db_name  $tidb_port"
elif [ $# -eq 1 ]; then
    db_name=$1
    echo "specific database: $db_name  $tidb_port"
elif [ $# -eq 2 ]; then
    db_name=$1
    tidb_port=$2
    echo "specific database: $db_name  $tidb_port"
else
    db_name=$1
    tidb_port=$2
    echo "speciic database: $db_name  $tidb_port"
    arr=('A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z' 'AA' 'BB' 'CC' 'DD' 'EE' 'FF' 'GG' 'HH' 'II' 'JJ' 'KK' 'LL' 'MM' 'NN' 'OO' 'PP' 'QQ' 'RR' 'SS' 'TT')
	for value in ${arr[@]}
	do
		str="alter table ${db_name}.${value} set tiflash replica 1;"
		echo "$str" | mysql -h $tip -P $tidb_port -u root -f -D $db_name 2>&1
	done
	sleep 10
	echo "set replica done!"
fi

#echo "is database correct?"

#read -p "Is the database right? (yes or no)" choose
#if [ $choose = "yes" ]
#then
#    echo "start to run"
#else
#    echo "exit!!!"
#    exit 1
#fi


unique=`date +%s`
unique=${unique}"_"$db_name
output=${unique}"_output"
dump=${unique}"_dump"
test_data=${unique}".test"

mv ${db_name}".test" $test_data
mkdir -p $output
mkdir -p $dump
cmd="set @@tidb_isolation_read_engines='tiflash,tidb'; set @@tidb_allow_mpp=1;"

i=0
while read -r line
do
	i=$((i+1))
	if [[ $line == SELECT* ]]; 
	then
		echo "$cmd$line"
		tidb_fname="${output}/${i}_tidb.out"
		echo "$line" > $tidb_fname
		echo "${cmd}$line" | mysql -h $tip -P $tidb_port -u root -f -D $db_name >> $tidb_fname 2>&1
		mysql_fname="${output}/${i}_mysql.out"
		echo "$line" > $mysql_fname
		echo "$line" | mysql -h $mip -P $mport -u root -f -D $db_name >> $mysql_fname 2>&1
		dump_fname=${dump}/${i}"_diff.out"
		# sort the 2 files
		sort $tidb_fname  -o $tidb_fname
		sort $mysql_fname -o $mysql_fname
		diff -s $tidb_fname $mysql_fname > /dev/null
		if [ $? -eq 0 ]; 
		then
    			mv $tidb_fname  ${tidb_fname}"_same"
			mv $mysql_fname ${mysql_fname}"_same"
		else
			echo "tidb vs mysql" > $dump_fname
			diff $tidb_fname $mysql_fname >> $dump_fname
		fi
	fi
done < $test_data

echo "$test_data DONE!!!!"
mv $test_data ${test_data}"-DONE"
