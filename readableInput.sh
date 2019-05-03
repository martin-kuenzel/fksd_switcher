#!/bin/bash
# Symbolische Bezeichnung zum Schalten verwenden
# example: ./readableInput.sh 1A
# example: ./readableInput.sh 24C 1

IFS=$'\n'; 

if read -t 0
then  
	for line in $( cat /dev/stdin|grep -vE '^#' ); do 
		dips=`echo $line|cut -d\  -f1`;
		state=`echo $line|cut -d\  -f2`; 
		./readableInput.sh $dips $state; 
	done
fi

[ "$2" != "" ] && STATE=$2;

ARG="15B"; 
[ "$1" != "" ] && ARG=$1;

CHAR=( A B C D E );
BITS=( 0 0 0 0 0 );

for i in $(printf $ARG|sed 's|\s*|\n|g'); do { 
	[ "$( printf $i|sed 's/[0-9]//g' )" != "" ] && { 
		for c in {0..4}; do 
			{ 
				[ "${CHAR[$c]}" == "$i" ] && CBITS[$c]=1; 
			} || CBITS[$c]=0; 
		done; 
	} || BITS[$[ $i-1 ]]=1; 
}; done; 

BITS=$(echo ${BITS[@]}|sed 's|[[:space:]]||g');
CBITS=$(echo ${CBITS[@]}|sed 's|[[:space:]]||g');

./bash_brematic.sh $BITS$CBITS $STATE;
exit 0;