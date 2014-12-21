#!/bin/bash
#
# Raspberry Pi Backup Script
#
#
# Configuration Section:

# Backup Directory
DIR=/media/backups/

# Services to pause
SERVICES="php5-fpm bitlbee mysql nginx unbound cron samba vsftpd ssh vncserver"

echo "Starting RaspberryPI backup process!"

# Check if backup directory exists
if [ ! -d "$DIR" ];
   then
      echo "Backup directory $DIR doesn't exist, creating it now!"
      mkdir $DIR
fi

# Create a filename with datestamp for our current backup (without .img suffix)
OFILE="$DIR/backup_$(date +%Y%m%d_%H%M%S)"

# Create final filename, with suffix
OFILEFINAL=$OFILE.img

#stop running processes
for svc in $SERVICES
do
  /etc/init.d/$svc stop
done

# First sync disks
sync; sync

# Begin the backup process, should take about 1 hour from 8Gb SD card to HDD
echo "Backing up SD card to USB HDD."
echo "This will take some time depending on your SD card size and read performance. Please wait..."
SDSIZE=`blockdev --getsize64 /dev/mmcblk0`;
pv -tpreb /dev/mmcblk0 -s $SDSIZE | dd of=$OFILE bs=1M conv=sync,noerror iflag=fullblock

# Wait for DD to finish and catch result
RESULT=$?

# Start services again that where shutdown before backup process
echo "Start the stopped services again."

for svc in $SERVICES
do
  /etc/init.d/$svc start
done


# If command has completed successfully, delete previous backups and exit
if [ $RESULT = 0 ];
   then
      echo "Successful backup, previous backup files will be deleted."
      rm -f $DIR/backup_*.tar.gz
      mv $OFILE $OFILEFINAL
      echo "Backup is being tarred. Please wait..."
      tar zcf $OFILEFINAL.tar.gz $OFILEFINAL
      rm -rf $OFILEFINAL
      echo "RaspberryPI backup process completed! FILE: $OFILEFINAL.tar.gz"
      exit 0
# Else remove attempted backup file
   else
      echo "Backup failed! Previous backup files untouched."
      echo "Please check there is sufficient space on the HDD."
      rm -f $OFILE
      echo "RaspberryPI backup process failed!"
      exit 1
fi
