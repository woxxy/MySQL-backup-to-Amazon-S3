woxxy / MySQL-backup-to-Amazon-S3
=================================

(This is not really an application, just a manual and some lines of code)

Amazon S3 can be an interestingly safe and cheap way to store your important data. Some of the most important data in the world is saved in... MySQL, and surely mine is quite important, so I needed such a script.

If you have a 500mb database (that's 10 times larger than any small site), with the priciest plan, keeping 6 backups (two months, two weeks, two days) costs $0.42 a month ($0.14GB/month). With 99.999999999% durability and 99.99% availability. Uploads are free, downloads would happen only in case you actually need to retrieve the backup (which hopefully won't be needed, but first GB is free, and over that $0.12/GB).

Even better: you get one free year up to 5GB storage and 15GB download. And, if you don't care about all the durability, later you can get the cheaper plan and spend $0.093GB/month.

The cons: you need to give them your credit card number. If you're like me, Amazon already has it anyway.

Another thing that is real nice: HTTPS connection and GPG encryption through s3cmd. Theorically it's safe enough.

Setup
-----
1. Register for Amazon AWS (yes, it asks for credit card)
2. Install s3cmd (following commands are for debian/ubuntu, but you can find how-to for other Linux distributions on [s3tools.org/repositories](http://s3tools.org/repositories))

		wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | sudo apt-key add -
		sudo wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list
		sudo apt-get update && sudo apt-get install s3cmd
	
3. Get your key and secret key at this [link](https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key)
4. Configure s3cmd to work with your account

		s3cmd --configure

5. Make a bucket (must be an original name, s3cmd will tell you if it's already used)

		s3cmd mb s3://my-database-backups
	
6. Put the mysqltos3.sh file somewhere in your server, like `/home/youruser`
7. Give the file 755 permissions `chmod 755 /home/youruser/mysqltos3.sh` or via FTP
8. Edit the variables near the top of the mysqltos3.sh file to match your bucket and MySQL authentication

Now we're set. You can use it manually:

	#set a new daily backup, and store the previous day as "previous_day"
	sh /home/youruser/mysqltos3.sh
	
	#set a new weekly backup, and store previous week as "previous_week"
	/home/youruser/mysqltos3.sh week
	
	#set a new weekly backup, and store previous month as "previous_month"
	/home/youruser/mysqltos3.sh month
	
But, we don't want to think about it until something breaks! So enter `crontab -e` and insert the following after editing the folders

	# daily MySQL backup to S3 (not on first day of month or sundays)
	0 3 2-31 * 1-6 sh /home/youruser/mysqltos3.sh day
	# weekly MySQL backup to S3 (on sundays, but not the first day of the month)
	0 3 2-31 * 0 sh /home/youruser/mysqltos3.sh week
	# monthly MySQL backup to S3
	0 3 1 * * sh /home/youruser/mysqltos3.sh month

And you're set.


Troubleshooting
---------------

None yet.