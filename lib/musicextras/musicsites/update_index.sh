#!/bin/sh

FILE=INDEX

echo -n "" > $FILE
for F in $(ls *.rb); do
        echo `md5 -q $F` $F >> $FILE
done
