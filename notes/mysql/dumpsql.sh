#!/bin/bash
db="dtvs iacs iclnd icore iis ilog imsgs invs ipmux ipwed isas itimers iuds iusm iwds tsg"
dump_path="/homed/wangdong"
for dbname in $db
do
	mysqldump -uroot -p123456 -d homed_$dbname >$dump_path/$dbname.sql
done
