#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT=
MYSQLPASS=
S3BUCKET=
FILENAME=
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH=mysql_backup/
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=
#tmp path.
TMP_PATH=~/dumpTmp

DATESTAMP=$(date +".%m.%d.%Y")
DAY=$(date +"%d")
DAYOFWEEK=$(date +"%A")

PERIOD=${1-day}
if [ ${PERIOD} = "auto" ]; then
	if [ ${DAY} = "01" ]; then
        	PERIOD=month
	elif [ ${DAYOFWEEK} = "Sunday" ]; then
        	PERIOD=week
	else
       		PERIOD=day
	fi	
fi

echo "Selected period: $PERIOD."

if [ ! -d "${TMP_PATH}" ]; then
        mkdir ${TMP_PATH}
fi

echo "Querying database list."
QUERY_RESULTS=$( mysql --user=${MYSQLROOT} --password=${MYSQLPASS} -e "SHOW DATABASES" );

for i in `echo $QUERY_RESULTS | tr ' ' '\n' |sed  '1d' | tr '\n' ' '`
do
		echo "Dump of :${i} ..."
		${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${i} > ${TMP_PATH}/${i}.sql
done
echo "Done backing up the databases to files."

echo "Starting compression..."

tar czf ${TMP_PATH}/${FILENAME}${DATESTAMP}.tar.gz ${TMP_PATH}/*

echo "Done compressing the backup file."

# we want at least two backups, two months, two weeks, and two days
echo "Removing old backup (2 ${PERIOD}s ago)..."
s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
echo "Old backup removed."

echo "Moving the backup from past $PERIOD to another folder..."
s3cmd mv --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/ s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
echo "Past backup moved."

# upload all databases
echo "Uploading the new backup..."
s3cmd put -f ${TMP_PATH}/${FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
echo "New backup uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ${TMP_PATH}/${FILENAME}${DATESTAMP}.tar.gz
rm ${TMP_PATH}/*.sql 
echo "Files removed."
echo "All done."
