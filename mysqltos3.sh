#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT=root
MYSQLPASS=password
S3BUCKET=bucketname
FILENAME=filename
DATABASE='--all-databases'
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH=
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=
S3CMDPATH=~/s3cmd/location/
#tmp path.
TMP_PATH=/tmp/

DATESTAMP=$(date +".%m.%d.%Y")
DAY=$(date +"%d")
DAYOFWEEK=$(date +"%A")

# Grandfather-father-son rotation scheme: http://en.wikipedia.org/wiki/Backup_rotation_scheme#Grandfather-father-son
ROTATE_DAY=6
ROTATE_WEEK=4
ROTATE_MONTH=12

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

if [ ${PERIOD} = "month" ]; then
	ROTATE=${ROTATE_MONTH}
elif [ ${PERIOD} = "week" ]; then
	ROTATE=${ROTATE_WEEK}
else
	ROTATE=${ROTATE_DAY}
fi

STARTTIME="$(date +%s%N)"

echo "Rotating ${PERIOD} backups (${ROTATE})."

for num in $(seq $ROTATE -1 1) 
do
	if [ ${ROTATE} = ${num} ]; then
		echo "\tRemoving oldest backup (${ROTATE} ${PERIOD}s ago)..."
		${S3CMDPATH}s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/${num}/
		echo "\tOldest backup removed."
	else
		echo "\tMoving the backup from past ${num} ${PERIOD}s to $((num+1))"
		${S3CMDPATH}s3cmd mv --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/${num}/ s3://${S3BUCKET}/${S3PATH}${PERIOD}/$((num+1))/
		${S3CMDPATH}s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/${num}/ 
		echo "\tPast backup moved."
	fi
done

echo "Starting backing up the database to a file..."
# dump all databases
${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${DATABASE} > ${TMP_PATH}${FILENAME}.sql

echo "Done backing up the database to a file."
echo "Starting compression..."

cd ${TMP_PATH}
tar cvzf ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz ${FILENAME}.sql

echo "Done compressing the backup file."

# upload backup (s3cmd supports pre-upload encryption: -e)
echo "Uploading the new backup..."
${S3CMDPATH}s3cmd put -f ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/1/
echo "New backup uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ${TMP_PATH}${FILENAME}.sql
rm ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz
echo "Files removed."
echo "All done."

ENDTIME="$(($(date +%s%N)-STARTTIME))"
S="$((ENDTIME/1000000000))"
printf "Timing: Days:%02d Hours:%02d Minutes:%02d Seconds:%02d.%03d\n" "$((S/86400))" "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}"
