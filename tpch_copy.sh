#!/bin/bash

# default configuration
pg_user=postgres
pg_database=postgres
pg_host=localhost
pg_port=5432
clean=
tpch_dir=tpch-dbgen
data_dir=/data
lines_per_file=50000  # 每个拆分文件包含的行数
max_parallel_jobs=16

usage () {
cat <<EOF

  1) Use default configuration to run tpch_copy
  ./tpch_copy.sh
  2) Use limited configuration to run tpch_copy
  ./tpch_copy.sh --user=postgres --db=postgres --host=localhost --port=5432
  3) Clean the test data. This step will drop the database or tables.
  ./tpch_copy.sh --clean

EOF
  exit 0;
}

for arg do
  val=`echo "$arg" | sed -e 's;^--[^=]*=;;'`

  case "$arg" in
    --user=*)                   pg_user="$val";;
    --db=*)                     pg_database="$val";;
    --host=*)                   pg_host="$val";;
    --port=*)                   pg_port="$val";;
    --clean)                    clean=on ;;
    -h|--help)                  usage ;;
    *)                          echo "wrong options : $arg";
                                exit 1
                                ;;
  esac
done

export PGPORT=$pg_port
export PGHOST=$pg_host
export PGDATABASE=$pg_database
export PGUSER=$pg_user

# clean the tpch test data
if [[ $clean == "on" ]]; then
  make clean
  if [[ $pg_database == "postgres" ]]; then
    echo "drop all the tpch tables"
    psql -c "drop table customer cascade"
    psql -c "drop table lineitem cascade"
    psql -c "drop table nation cascade"
    psql -c "drop table orders cascade"
    psql -c "drop table part cascade"
    psql -c "drop table partsupp cascade"
    psql -c "drop table region cascade"
    psql -c "drop table supplier cascade"
  else
    echo "drop the tpch database: $PGDATABASE"
    psql -c "drop database $PGDATABASE" -d postgres
  fi
  exit;
fi

###################### PHASE 1: create table ######################
if [[ $PGDATABASE != "postgres" ]]; then  
  echo "create the tpch database: $PGDATABASE"  
  psql -c "create database $PGDATABASE" -d postgres  
fi 
# 创建一个临时的 dss.ddl，只包含不包含 LINEITEM 的表，并将其转换为 UNLOGGED TABLE
sed -e 's/CREATE TABLE/CREATE UNLOGGED TABLE/g' \
    -e '/CREATE UNLOGGED TABLE LINEITEM/,/);/d' \
    -e '/CREATE TABLE LINEITEM/,/);/d' \
    $tpch_dir/dss.ddl > /tmp/dss_filtered.ddl


# 执行过滤后的 ddl 文件
psql -f /tmp/dss_filtered.ddl



psql -c "
CREATE TABLE LINEITEM (
    L_ORDERKEY    INTEGER NOT NULL,
    L_PARTKEY     INTEGER NOT NULL,
    L_SUPPKEY     INTEGER NOT NULL,
    L_LINENUMBER  INTEGER NOT NULL,
    L_QUANTITY    DECIMAL(15,2) NOT NULL,
    L_EXTENDEDPRICE DECIMAL(15,2) NOT NULL,
    L_DISCOUNT    DECIMAL(15,2) NOT NULL,
    L_TAX         DECIMAL(15,2) NOT NULL,
    L_RETURNFLAG  CHAR(1) NOT NULL,
    L_LINESTATUS  CHAR(1) NOT NULL,
    L_SHIPDATE    DATE NOT NULL,
    L_COMMITDATE  DATE NOT NULL,
    L_RECEIPTDATE DATE NOT NULL,
    L_SHIPINSTRUCT CHAR(25) NOT NULL,
    L_SHIPMODE     CHAR(10) NOT NULL,
    L_COMMENT      VARCHAR(44) NOT NULL
);"
psql -c "
CREATE UNLOGGED TABLE LINEITEM_p1 (CHECK (L_ORDERKEY >= -1 AND L_ORDERKEY < 20000000)) INHERITS (LINEITEM);
CREATE UNLOGGED TABLE LINEITEM_p2 (CHECK (L_ORDERKEY >= 20000000 AND L_ORDERKEY < 40000000)) INHERITS (LINEITEM);
CREATE UNLOGGED TABLE LINEITEM_p3 (CHECK (L_ORDERKEY >= 40000000 AND L_ORDERKEY < 60000000)) INHERITS (LINEITEM);
CREATE UNLOGGED TABLE LINEITEM_p4 (CHECK (L_ORDERKEY >= 60000000 AND L_ORDERKEY < 80000000)) INHERITS (LINEITEM);
CREATE UNLOGGED TABLE LINEITEM_p5 (CHECK (L_ORDERKEY >= 80000000 AND L_ORDERKEY < 100000000)) INHERITS (LINEITEM);
CREATE UNLOGGED TABLE LINEITEM_p6 (CHECK (L_ORDERKEY >= 100000000 AND L_ORDERKEY < 120000010)) INHERITS (LINEITEM);
"
###################### PHASE 2: load data ######################  
psql -c "update pg_class set relpersistence ='u' where relnamespace='public'::regnamespace;"  

# 禁用约束
echo "禁用所有触发器以禁用约束..."
for table in nation region part supplier partsupp customer orders lineitem; do
    psql -c "ALTER TABLE $table DISABLE TRIGGER ALL;"
done

# 拆分数据文件并并行导入
# 对其他表并行导入
for table in nation region part supplier partsupp customer orders; do
    if [[ "$table" == "orders" ]]; then
        sudo mkdir /tmp/ramdisk
        sudo chmod 777 /tmp/ramdisk
        sudo mount -t tmpfs -o size=4G myramdisk /tmp/ramdisk
        mount | tail -n 1
        # 对 orders 表进行拆分和导入
        split -l $lines_per_file "$data_dir/${table}.tbl" "/tmp/ramdisk/${table}_part_"
        
        # 启动拆分 lineitem 表的数据到后台
        split -l $lines_per_file "$data_dir/lineitem.tbl" "$data_dir/lineitem_part_" &  # & 放到后台运行

        # 导入 orders 表的分割文件
        for part_file in "/tmp/ramdisk/${table}_part_"*; do
            (
                retries=3  # 最大重试次数
                count=0
                success=0

                while [[ $count -lt $retries ]]; do
                    # 尝试导入 orders 表的数据
                    if psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY $table FROM '$part_file' WITH (FORMAT csv, DELIMITER '|');"; then
                        echo "Successfully imported $part_file into $table."
                        success=1
                        break
                    else
                        echo "Error importing $part_file into $table. Retry $((count + 1))/$retries..."
                        ((count++))
                        sleep 2  # 等待2秒后重试
                    fi
                done

                if [[ $success -ne 1 ]]; then
                    echo "Failed to import $part_file into $table after $retries attempts."
                    exit 1  # 导入失败，退出
                fi
            ) &  # 导入任务放到后台运行

            # 限制并发进程数
            if [[ $(jobs -r -p | wc -l) -ge $max_parallel_jobs ]]; then
                wait -n
            fi
        done
        sudo umount /tmp/ramdisk
	      sudo rm -r /tmp/ramdisk
        # 等待拆分 lineitem 表任务完成
        wait  # 等待拆分任务完成

        # 同时拆分并导入 lineitem 表
        for part_file in "$data_dir/lineitem_part_"*; do
            (
                retries=3  # 最大重试次数
                count=0
                success=0

                while [[ $count -lt $retries ]]; do
                    first_orderkey=$(head -n 1 "$part_file" | cut -d'|' -f1)
                    last_orderkey=$(tail -n 1 "$part_file" | cut -d'|' -f1)

                    # 根据第一行和最后一行判断应该导入到哪个分区
                    if [ "$first_orderkey" -ge 0 ] && [ "$first_orderkey" -lt 20000000 ] ; then
                        if [ "$last_orderkey" -ge 20000000 ]; then
                          # 找到第一个大于等于 5000000 的行号
                          last_line_num=$(grep -n -m 1 "^20000000" "$part_file" | cut -d':' -f1)
                          if [ -z "$last_line_num" ]; then
                              last_line_num=$(awk -F'|' '$1 >= 20000000 {print NR; exit}' "$part_file")
                          fi
                          if [ -z "$first_line_num" ] || [ -z "$last_line_num" ]; then
                              echo "错误: 无法找到拆分行"
                              exit 1
                          fi
                          last_line_num=$((last_line_num - 1))
                          # 拆分数据
                          head -n "$last_line_num" "$part_file" > "$part_file"_split_p1  # 小于 5000000 的部分
                          tail -n +$((last_line_num + 1)) "$part_file" > "$part_file"_split_p2  # 大于等于 5000000 的部分
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p1 FROM '$part_file_split_p1' WITH (FORMAT csv, DELIMITER '|');"
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p2 FROM '$part_file_split_p2' WITH (FORMAT csv, DELIMITER '|');"

                          success=1
                          break
                        else    
                          partition_table="LINEITEM_p1"
                        fi
                    elif [ "$first_orderkey" -ge 20000000 ] && [ "$first_orderkey" -lt 40000000 ]; then
                         if [ "$last_orderkey" -ge 40000000 ]; then
                          last_line_num=$(grep -n -m 1 "^40000000" "$part_file" | cut -d':' -f1)
                          if [ -z "$last_line_num" ]; then
                              last_line_num=$(awk -F'|' '$1 >= 40000000 {print NR; exit}' "$part_file")
                          fi
                          if [ -z "$first_line_num" ] || [ -z "$last_line_num" ]; then
                              echo "错误: 无法找到拆分行"
                              exit 1
                          fi
                          last_line_num=$((last_line_num - 1))
                          # 拆分数据
                          head -n "$last_line_num" "$part_file" > "$part_file"_split_p3  # 小于 15000000 的部分
                          tail -n +$((last_line_num + 1)) "$part_file" > "$part_file"_split_p4  # 大于等于 15000000 的部分
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p3 FROM '$part_file_split_p3' WITH (FORMAT csv, DELIMITER '|');"
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p4 FROM '$part_file_split_p4' WITH (FORMAT csv, DELIMITER '|');"

                          success=1
                          break
                        else    
                            partition_table="LINEITEM_p2"
                        fi                   
                    elif [ "$first_orderkey" -ge 40000000 ] && [ "$first_orderkey" -lt 60000000 ]; then
                        if [ "$last_orderkey" -ge 60000000 ]; then
                          # 找到第一个大于等于 15000000 的行号
                          last_line_num=$(grep -n -m 1 "^60000000" "$part_file" | cut -d':' -f1)
                          if [ -z "$last_line_num" ]; then
                              last_line_num=$(awk -F'|' '$1 >= 60000000 {print NR; exit}' "$part_file")
                          fi
                          if [ -z "$first_line_num" ] || [ -z "$last_line_num" ]; then
                              echo "错误: 无法找到拆分行"
                              exit 1
                          fi
                          last_line_num=$((last_line_num - 1))
                          # 拆分数据
                          head -n "$last_line_num" "$part_file" > "$part_file"_split_p5  # 小于 15000000 的部分
                          tail -n +$((last_line_num + 1)) "$part_file" > "$part_file"_split_p6  # 大于等于 15000000 的部分
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p5 FROM '$part_file_split_p3' WITH (FORMAT csv, DELIMITER '|');"
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p6 FROM '$part_file_split_p4' WITH (FORMAT csv, DELIMITER '|');"

                          success=1
                          break
                        else    
                            partition_table="LINEITEM_p3"
                        fi
                    elif [ "$first_orderkey" -ge 60000000 ] && [ "$first_orderkey" -lt 80000000 ]; then
                        if [ "$last_orderkey" -ge 80000000 ]; then
                          # 找到第一个大于等于 15000000 的行号
                          last_line_num=$(grep -n -m 1 "^80000000" "$part_file" | cut -d':' -f1)
                          if [ -z "$last_line_num" ]; then
                              last_line_num=$(awk -F'|' '$1 >= 80000000 {print NR; exit}' "$part_file")
                          fi
                          if [ -z "$first_line_num" ] || [ -z "$last_line_num" ]; then
                              echo "错误: 无法找到拆分行"
                              exit 1
                          fi
                          last_line_num=$((last_line_num - 1))
                          # 拆分数据
                          head -n "$last_line_num" "$part_file" > "$part_file"_split_p7  # 小于 15000000 的部分
                          tail -n +$((last_line_num + 1)) "$part_file" > "$part_file"_split_p8  # 大于等于 15000000 的部分
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p7 FROM '$part_file_split_p3' WITH (FORMAT csv, DELIMITER '|');"
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p8 FROM '$part_file_split_p4' WITH (FORMAT csv, DELIMITER '|');"

                          success=1
                          break
                        else    
                            partition_table="LINEITEM_p4"
                        fi
                    elif [ "$first_orderkey" -ge 80000000 ] && [ "$first_orderkey" -lt 100000000 ]; then
                        if [ "$last_orderkey" -ge 100000000 ]; then
                          last_line_num=$(grep -n -m 1 "^100000000" "$part_file" | cut -d':' -f1)
                          if [ -z "$last_line_num" ]; then
                              last_line_num=$(awk -F'|' '$1 >= 100000000 {print NR; exit}' "$part_file")
                          fi
                          if [ -z "$first_line_num" ] || [ -z "$last_line_num" ]; then
                              echo "错误: 无法找到拆分行"
                              exit 1
                          fi
                          last_line_num=$((last_line_num - 1))
                          # 拆分数据
                          head -n "$last_line_num" "$part_file" > "$part_file"_split_p9  # 小于 15000000 的部分
                          tail -n +$((last_line_num + 1)) "$part_file" > "$part_file"_split_p10  # 大于等于 15000000 的部分
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p7 FROM '$part_file_split_p3' WITH (FORMAT csv, DELIMITER '|');"
                          psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY LINEITEM_p10 FROM '$part_file_split_p4' WITH (FORMAT csv, DELIMITER '|');"

                          success=1
                          break
                        else    
                            partition_table="LINEITEM_p5"
                        fi
                    elif [ "$first_orderkey" -ge 100000000 ] && [ "$first_orderkey" -lt 120000010 ]; then
                        partition_table="LINEITEM_p6"
                    else
                        echo "错误: 无法为 L_ORDERKEY 范围 ($first_orderkey - $last_orderkey) 确定分区"
                        exit 1
                    fi


                    # 尝试导入数据到分区
                    if psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY $partition_table FROM '$part_file' WITH (FORMAT csv, DELIMITER '|');"; then
                        echo "成功导入 $part_file 到 $partition_table."
                        success=1
                        break
                    else
                        echo "导入 $part_file 到 $partition_table 失败. 重试 $((count + 1))/$retries..."
                        ((count++))
                        sleep 2  # 等待2秒后重试
                    fi
                done

                if [[ $success -ne 1 ]]; then
                    echo "$part_file 导入到 $partition_table 失败，经过 $retries 次重试后仍然失败."
                    exit 1  # 导入失败，退出
                fi
            ) &  # 导入任务放到后台

            # 限制并发进程数
            if [[ $(jobs -r -p | wc -l) -ge $max_parallel_jobs ]]; then
                wait -n
            fi
        done

        # 等待所有并行任务完成
        wait
    else
        # 对其他表进行拆分和导入
        split -l $lines_per_file "$data_dir/${table}.tbl" "$data_dir/${table}_part_"
        
        for part_file in "$data_dir/${table}_part_"*; do
            (
                retries=3  # 最大重试次数
                count=0
                success=0

                while [[ $count -lt $retries ]]; do
                    # 尝试导入
                    if psql -h "$pg_host" -d "$pg_database" -U "$pg_user" -c "COPY $table FROM '$part_file' WITH (FORMAT csv, DELIMITER '|');"; then
                        echo "Successfully imported $part_file into $table."
                        success=1
                        break
                    else
                        echo "Error importing $part_file into $table. Retry $((count + 1))/$retries..."
                        ((count++))
                        sleep 2  # 等待2秒后重试
                    fi
                done

                if [[ $success -ne 1 ]]; then
                    echo "Failed to import $part_file into $table after $retries attempts."
                    exit 1  # 导入失败，退出
                fi
            ) &  # 导入任务放到后台

            # 限制并发进程数
            if [[ $(jobs -r -p | wc -l) -ge $max_parallel_jobs ]]; then
                wait -n
            fi
        done
    fi
done

# 等待所有并行任务完成
wait


# 重新启用约束
echo "启用所有触发器以重新启用约束..."
for table in nation region part supplier partsupp customer orders lineitem; do
    psql -c "ALTER TABLE $table ENABLE TRIGGER ALL;"
done

###################### PHASE 3: add primary and foreign key ######################
psql -c "ALTER SYSTEM SET maintenance_work_mem='1GB';"
psql -c "SELECT pg_reload_conf();"  
{
  max_parallel_jobs=17

  while IFS= read -r line; do
    # 去掉行末的分号
    line=$(echo "$line" | sed 's/;*$//')  
    if [[ -n $line && ! $line =~ ^-- ]]; then
      # 检查如果是ALTER TABLE命令
      if [[ $line == ALTER\ TABLE* ]]; then
        # 读取下一行以组合
        read -r next_line
        # 组合ALTER TABLE和下一行
        line="$line $next_line"
      fi

      (
        retries=3
        count=0
        success=0
        
        while [[ $count -lt $retries ]]; do
          # 执行命令
          if psql -c "$line"; then
            echo "成功执行: $line"
            success=1
            break
          else
            echo "执行出错: $line. 重试 $((count + 1))/$retries..."
            ((count++))
            sleep 2
          fi
        done
        
        if [[ $success -ne 1 ]]; then
          echo "执行失败: $line，经过 $retries 次尝试后仍然失败."
          exit 1
        fi
      ) &

      while [[ $(jobs -r -p | wc -l) -ge $max_parallel_jobs ]]; do
        wait -n
      done
    fi
  done < "$tpch_dir/dss.ri"

  wait
} || {
  echo "添加主键和外键时发生错误."
  exit 1
}

psql -c "ALTER SYSTEM SET maintenance_work_mem='512MB';"
psql -c "SELECT pg_reload_conf();"  