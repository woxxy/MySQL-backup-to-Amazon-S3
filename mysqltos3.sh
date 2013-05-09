#!/bin/sh

S3BUCKET='bucket'

DATESTAMP=$(date +"%m.%d.%Y")
DAY=$(date +"%-d")
DAY_OF_WEEK=$(date +"%A")
MONTH=$(date +"%-m")

FILE_PATH=/tmp/databases.${DATESTAMP}.sql.gz

# dump databases
${MYSQLDUMPPATH}mysqldump --quick --user=**** --password=****** --all-databases | gzip -c > ${FILE_PATH}

# uploading new backup to period folder
if [ ${DAY} = '1' ]; then
	if [ ${MONTH} = 1 ]; then
		s3cmd put -f ${FILE_PATH} s3://${S3BUCKET}/sql/year/
	else
		s3cmd put -f ${FILE_PATH} s3://${S3BUCKET}/sql/month/
	fi
elif [ ${DAY_OF_WEEK} = 'Sunday' ]; then
	s3cmd put -f ${FILE_PATH} s3://${S3BUCKET}/sql/week/
else
	s3cmd put -f ${FILE_PATH} s3://${S3BUCKET}/sql/day/
fi

# remove databases dump
rm ${FILE_PATH}
