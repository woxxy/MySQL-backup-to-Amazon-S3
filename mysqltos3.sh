#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

MYSQLROOT=root
MYSQLPASS=password
S3BUCKET=mybucket

# dump all databases
mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} --single-transaction --all-databases > ~/all-databases.sql

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