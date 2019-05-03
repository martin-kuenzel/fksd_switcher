#!/bin/bash
# Brematic GWY433 zum schalten für Funksteckdosen mittels DIP Codierung -> Brennstuhl / Elro / etc" 

## example cmdline execution 
# ./bash_brematic.sh byte_combination (8bits) : default 0100101000 (for 2.5.A)

## alles kombinationen abschalten 
# ( STATE=0; for i in {0..1}{0..1}{0..1}{0..1}{0..1};do for j in {10000,01000,00100,00010,00001}; do ./bash_brematic.sh $i$j $STATE; done; done; )
## alles kombinationen anschalten 
# ( STATE=1; for i in {0..1}{0..1}{0..1}{0..1}{0..1};do for j in {10000,01000,00100,00010,00001}; do ./bash_brematic.sh $i$j $STATE; done; done; )

#substitut für php strlen
strlen(){
    len=0;
    for i in "$@"; do len=$[ $len + $(echo -n $i | wc -m) ]; done
    echo -n $len;
}
#substitut für php substr
substr(){
    echo -n "$1" | sed "s|^.\{$2\}\(.\{$3\}\).*$|\1|"
}

server_ip='192.168.1.6'; # Ip Des Gateway 
server_port=49880; #Port des Gateway 

master="01001"; #Master-DIPs des Gateway (Binary 0-1)
slave="10000"; #Slave-DIPs des Gateway (Char A-E)
status=21889; #Variable 

bitset=$master$slave;
[ "$1" != "" ] && bitset=$1;
master=$( echo -n $bitset | sed 's|^\([01]\{5\}\)\([01]\{5\}\)|\1|' )
slave=$( echo -n $bitset | sed 's|^\([01]\{5\}\)\([01]\{5\}\)|\2|' )

#Aufbau der Message 
sA=0; 
sG=0; 
sRepeat=10; 
sPause=5600; 
sTune=350; 
sBaud=25; 
sSpeed=16; 
uSleep=800000; 
txversionaus=1; 
txversionan=3; 
HEAD="TXP:$sA,$sG,$sRepeat,$sPause,$sTune,$sBaud,"; 
TAILAN=",$txversionaus,1,$sSpeed;";   
TAILAUS=",$txversionaus,1,$sSpeed;"; 
AN="1,3,1,3,3"; 
AUS="3,1,1,3,1";

bitLow=1; 
bitHgh=3; 
seqLow="$bitHgh,$bitHgh,$bitLow,$bitLow,"; 
seqHgh="$bitHgh,$bitLow,$bitHgh,$bitLow,"; 
# bits=$master; 
# msg=""; 
DESCSTR="";

getSeq(){
    ( { [ $1 -eq 0 ] && printf $seqLow; } || printf $seqHgh; );
}

aNums=( A B C D E );
# echo setting numerical bits [1-5]
# echo setting alphanumerical bits [A-E]
for((i=0;i<$(strlen $master);i++)); do
    bit=$(substr "$master" "$i" "1")
    char=$(substr "$slave" "$i" "1")

    msgB=$msgB$(getSeq $bit); # ermittle up/down des bit an position $i in $master
    [ $bit -eq 1 ] && DESCSTR=$DESCSTR$[ $i + 1 ]; # ermittle up/down des bit an position $i in $slave

    msgC=$msgC$(getSeq $char);
    [ $char -eq 1 ] && cDESCSTR=$cDESCSTR${aNums[$i]}
done

DESCSTR=$DESCSTR$cDESCSTR
msg=$msgB$msgC

#Ausführung mit Variablenänderung 
messageAUS="$HEAD$bitLow,$msgB$msgC$bitHgh,$AUS$TAILAUS"; 
messageSAUS=$( strlen "$HEAD$bitLow,$msgB$msgC$bitHgh,$AUS$TAILAUS" ); 
messageAN="$HEAD$bitLow,$msgB$msgC$bitHgh,$AN$TAILAN"; 
messageSAN=$( strlen "$HEAD$bitLow,$msgB$msgC$bitHgh,$AN$TAILAN" );

# echo $messageAN
# echo $messageAUS

#Legende 
# 0 = 3,3,1,1
# 1 = 3,1,3,1
# An = 1,3,1,3,3 
# Aus = 3,1,1,3,1
# echo $messageAUS
# echo $( ( 
#     X=-5; ANUM=( A B C D E ); for i in $(printf 0100101000|sed 's/ */\n/g'); do 
#         [ $i -gt 0 ] && {{ [ $X -gt -1 ] && echo ${ANUM[$X]}; } || { echo $[ $X * -1 ]; }; }; let X++; 
#     done; 
# ) | sort -b ) | sed 's|[[:space:]]\+||g'

#Ausführung Code & Variablenänderung 
CONFIG_FILE="brematic.cfg"

# wenn configfile noch nicht existiert
#[ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE";

# wenn eintrag für dip-kombi noch nicht in config
( [ $( grep "$DESCSTR" "$CONFIG_FILE" | wc -l ) -eq 0 ] && echo "$DESCSTR:0" >> "$CONFIG_FILE"; ) >/dev/null 2>&1;

# erhalte aktuellen status
CURRENT_STATUS=$(grep "$DESCSTR" "$CONFIG_FILE"|cut -d: -f2); 

# ziehe 1 von $2 ab, sodass 1=0 und 0!=0 bei Übersetzung (Usercompliance)
[ "$2" != "" ] && CURRENT_STATUS=$(( $2 - 1)); 

# wenn CURRENT_STATUS auf AN
if [ $CURRENT_STATUS -eq 0 ] && [ "$2" != "0" ]; then 
    sendMsg=$messageAN
    CURRENT_STATUS=1;
# wenn CURRENT_STATUS auf AUS
else 
    sendMsg=$messageAUS
    CURRENT_STATUS=0;
fi

(
    echo $sendMsg | /bin/nc -u $server_ip $server_port &
    pid=$!
    sleep 1
    kill $pid 
) >/dev/null 2>&1

sed -i "s|^\($DESCSTR\):.|\1:$CURRENT_STATUS|" "$CONFIG_FILE"
echo "CURRENT_STATUS von $DESCSTR ($master$slave) auf $CURRENT_STATUS gesetzt."

exit 0;