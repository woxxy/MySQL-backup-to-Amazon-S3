#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT=root
MYSQLPASS=password
S3BUCKET=my-db-backup-bucket
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=

# dump all databases
${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} --single-transaction --all-databases > ~/all-databases.sql

if [ $1 != month ]
then
	if [ $1 != week ]
	then
		PERIOD=day
	else
		PERIOD=week
		
	fi
else
	PERIOD=month
fi

# we want at least two backups, two months, two weeks, and two days
s3cmd del --recursive s3://${S3BUCKET}/previous_${PERIOD}/
s3cmd mv --recursive s3://${S3BUCKET}/${PERIOD}/ s3://${S3BUCKET}/previous_${PERIOD}/

# upload all databases
s3cmd put -f ~/all-databases.sql s3://${S3BUCKET}/${PERIOD}/

# remove databases dump
rm ~/all-databases.sql