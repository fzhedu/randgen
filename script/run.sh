#mysql -h 127.0.0.1 -P 4000 -u root -f -D randgen_test < randgen_test.test > tidb.output 2>&1
#mysql -h 127.0.0.1 -P 5000 -u root -f -D randgen_test < randgen_test.test > mysql.output 2>&1

test_goal="hash_join"
db_name="randgen_"$test_goal
tport="53324"
tip="172.16.5.85"
mport="3306"
mip="127.0.0.1"
unique=$(date +%s)
unique=${unique}"_"$db_name
output=${unique}"_output"
dump=${unique}"_dump"
test_data=${unique}".test"
old_unique=""

function set_replica() {
    res=$(mysql --silent -h $tip -P $tport -u root -f -D $db_name -BNe "use ${db_name};show tables;" 2>&1)
    if [ $? -eq "0" ]; then
        echo -e "set replica for tables: \c"
        for value in ${res[@]}; do
            str="alter table ${db_name}.${value} set tiflash replica 1;"
            echo "$str" | mysql -h $tip -P $tport -u root -f -D $db_name 2>&1
            sleep 10
            echo -e "${db_name}.${value} \c"
        done
        sleep 50
        echo -e " done."
    else
        echo "ERROR: $res"
    fi
}

function load_mysql() {
    echo "source $test_data" | mysql -h $mip -P $mport -u root 2>&1
    echo "load data into mysql done."
}

function set_sql_mode() {
    ## set sql_mode to avoid invalid date
    sql_mode="set @@global.sql_mode ='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';"
    echo "${sql_mode}" | mysql -h $mip -P $mport -u root 2>&1
    echo "${sql_mode}" | mysql -h $tip -P $tport -u root 2>&1
}

function run_a_file() {
    cmd="set @@tidb_isolation_read_engines='tiflash,tidb'; set @@tidb_allow_mpp=1;"
    i=0
    while read -r line; do
        i=$((i + 1))
        if [[ $line == SELECT* ]]; then
            echo "$cmd$line"
            tidb_fname="${output}/${i}_tidb.out"
            echo "$line" >$tidb_fname
            echo "${cmd}$line" | mysql -h $tip -P $tport -u root -f -D $db_name >>$tidb_fname 2>&1
            mysql_fname="${output}/${i}_mysql.out"
            echo "$line" >$mysql_fname
            echo "$line" | mysql -h $mip -P $mport -u root -f -D $db_name >>$mysql_fname 2>&1
            dump_fname=${dump}/${i}"_diff.out"
            # sort the 2 files
            sort $tidb_fname -o $tidb_fname
            sort $mysql_fname -o $mysql_fname
            diff -s $tidb_fname $mysql_fname >/dev/null
            if [ $? -eq 0 ]; then
                mv $tidb_fname ${tidb_fname}"_same"
                mv $mysql_fname ${mysql_fname}"_same"
            else
                echo "tidb vs mysql" >$dump_fname
                diff $tidb_fname $mysql_fname >>$dump_fname
            fi
        fi
    done <$test_data
    echo "$test_data DONE!!!!"
}

## first run yy && zz
## input: first db_name tidb_ip tidb_port
function first_run() {
    unique=$(date +%s)
    unique=${unique}"_"$db_name
    output=${unique}"_output"
    dump=${unique}"_dump"
    test_data=${unique}".test"
    mv ${db_name}".test" $test_data
    mkdir -p $output
    mkdir -p $dump
    load_mysql
    run_a_file
    mv $test_data ${test_data}"-DONE"
}

## NOTE: should set test_data at first
## rerun an existing file
## input: rerun file_name db_name tidb_ip tidb_port
function rerun_a_file() {
    unique=$(date +%s)
    unique=${unique}"_"$db_name
    output=${unique}"_output"
    dump=${unique}"_dump"
    mkdir -p $output
    mkdir -p $dump
    run_a_file
}

## rerun_dump the error tests for previous dump files if upgrade TiDB
## input: rerun_dump old_unique db_name tidb_ip tidb_port
## example: rerun_dump 1617261905 oj_agg10000 127.0.0.1 53324
function rerun_dump() {
    unique=$(date +%s)
    unique=${old_unique}${unique}"_"$db_name
    output=${unique}"_output"
    dump=${unique}"_dump"

    refile=${old_unique}"_"${db_name}

    if [ ! -f "${refile}.test-DONE" ]; then
        echo "ERROR: ${refile}.test-DONE does not exist, so exit!"
        exit
    fi

    if [ ! -d "${refile}_dump" ]; then
        echo "${refile}_dump does not exist, so exit!"
        exit
    fi
    mkdir -p $output
    mkdir -p $dump

    cmd="set @@tidb_isolation_read_engines='tiflash,tidb'; set @@tidb_allow_mpp=1;"
    array=($(grep -LiR "> ERROR" "${refile}_dump"/. | grep 'diff.out' | cut -d '/' -f 3 | cut -d '_' -f 1))
    for i in ${array[@]}; do
        line=$(sed -n "${i}p" "${refile}.test-DONE")
        echo "$cmd$line"
        tidb_fname="${output}/${i}_tidb.out"
        echo "$line" >$tidb_fname
        echo "${cmd}$line" | mysql -h $tip -P $tport -u root -f -D $db_name >>$tidb_fname 2>&1
        mysql_fname="${output}/${i}_mysql.out"
        echo "$line" >$mysql_fname
        echo "$line" | mysql -h $mip -P $mport -u root -f -D $db_name >>$mysql_fname 2>&1
        dump_fname=${dump}/${i}"_diff.out"
        # sort the 2 files
        sort $tidb_fname -o $tidb_fname
        sort $mysql_fname -o $mysql_fname
        diff -s $tidb_fname $mysql_fname >/dev/null
        if [ $? -eq 0 ]; then
            mv $tidb_fname ${tidb_fname}"_same"
            mv $mysql_fname ${mysql_fname}"_same"
        else
            echo "tidb vs mysql" >$dump_fname
            diff $tidb_fname $mysql_fname >>$dump_fname
        fi
    done
    echo "${refile} runs DONE."
}

if [ -z $1 ]; then
    echo "usage: "
    echo "first db_name tidb_ip tidb_port"
    echo "rerun file_name db_name tidb_ip tidb_port"
    echo "rerun_dump old_unique db_name tidb_ip tidb_port"
    exit
else
    if [ $1 == "first" ]; then
        db_name=$2
        tip=$3
        tport=$4
        set_replica
        first_run
    elif [ $1 == "rerun" ]; then
        test_data=$2
        db_name=$3
        tip=$4
        tport=$5
        rerun_a_file
    elif [ $1 == "rerun_dump" ]; then
        old_unique=$2
        db_name=$3
        tip=$4
        tport=$5
        rerun_dump
    fi
fi
