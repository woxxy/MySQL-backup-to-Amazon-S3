#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# dump all databases
mysqldump --quick --user=youruser --password=yourpassword --all-databases > ~/all-databases.sql

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
s3cmd del --recursive s3://my-database-backups/previous_${PERIOD}/
s3cmd mv --recursive s3://my-database-backups/${PERIOD}/ s3://FoOlDB/previous_${PERIOD}/

# upload all databases
s3cmd put -f ~/all-databases.sql s3://my-database-backups/${PERIOD}/

# remove databases dump
rm ~/all-databases.sql