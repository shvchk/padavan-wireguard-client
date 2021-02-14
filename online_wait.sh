#!/bin/sh

ONLINE_ERR=1

while [ $ONLINE_ERR -ne 0 ]
do
  ping -c 1 -W 1 $1 &> /dev/null
  ONLINE_ERR=$?

  if [ $ONLINE_ERR -ne 0 ]
    then
      echo "No internet connection, waiting..."
      sleep 5
  fi
done

echo "Internet connection established"
