#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT=root
MYSQLPASS=password
S3BUCKET=bucketname
FILENAME=filename
DATABASE='--all-databases'
REMOVE_BACKUPS=true
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH=mysql_backup/
S3CMDPATH=
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=
#tmp path.
TMP_PATH=./

# File to capture the output.
OUTPUT_FILE=${TMP_PATH}output.log
ECHO_OUTPUT=true

# Email options.
MAILPATH=
ENABLE_EMAIL=false
TO_ADDRESS=''
FROM_ADDRESS=''
SUBJECT=''

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

# Take the output and redirect it to a file.
{
	echo "Backup output from ${DATESTAMP}."

	echo "Selected period: ${PERIOD}."

	echo "Starting backing up the database to a file..."

	# dump all databases
	${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${DATABASE} > ${TMP_PATH}${FILENAME}.sql 

	echo "Done backing up the database to a file."
	echo "Starting compression..."

	tar czf ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz ${TMP_PATH}${FILENAME}.sql
	echo "Done compressing the backup file."

	if [ ${REMOVE_BACKUPS} = true ]; then
		# we want at least two backups, two months, two weeks, and two days
		echo "Removing old backup (2 ${PERIOD}s ago)..."
		${S3CMDPATH}s3cmd del --recursive s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
		echo "Old backup removed."
	fi

	echo "Moving the backup from past $PERIOD to another folder..."
	${S3CMDPATH}s3cmd mv --recursive s3://${S3BUCKET}/${S3PATH}${PERIOD}/ s3://${S3BUCKET}/${S3PATH}previous_${PERIOD}/
	echo "Past backup moved."

	# upload all databases
	echo "Uploading the new backup..."
	${S3CMDPATH}s3cmd put -f ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}${PERIOD}/
	echo "New backup uploaded."

	echo "Removing the cache files..."
	# remove databases dump
	rm ${TMP_PATH}${FILENAME}.sql
	rm ${TMP_PATH}${FILENAME}${DATESTAMP}.tar.gz
	echo "Files removed."
	echo "All done."

	if [ ${ENABLE_EMAIL} = true ]; then
		${MAILPATH}mail -s "${SUBJECT}" -r "${FROM_ADDRESS}" "${TO_ADDRESS}" < ${OUTPUT_FILE}
		echo "Sent mail."
	fi
} > ${OUTPUT_FILE} 2>&1

if [ ${ECHO_OUTPUT} = true ]; then
	cat ${OUTPUT_FILE}
	rm ${OUTPUT_FILE}
fi
