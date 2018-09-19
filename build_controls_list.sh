#!/bin/bash
rm controls_signalduino.txt
while IFS= read -r -d '' FILE
do
    TIME=$(git log --pretty=format:%cd -n 1 --date=iso -- "$FILE")
    TIME=$(TZ=Europe/Berlin date -d "$TIME" +%Y-%m-%d_%H:%M:%S)
    FILESIZE=$(stat -c%s "$FILE")
	FILE=$(echo "$FILE"  | cut -c 3-)
	printf "UPD %s %-7d %s\n" "$TIME" "$FILESIZE" "$FILE"  >> controls_signalduino.txt
done <   <(find ./FHEM -maxdepth 2 \( -name "*.pm" -or -name "*.hash" \) -print0)

while IFS= read -r -d '' FILE
do
	FILE=$(echo "$FILE"  | cut -c 3-)
	printf "MOV %s unused\n" "$FILE"  >> controls_signalduino.txt
done <   <(find ./FHEM/firmware -maxdepth 1 -name "*.hex" -print0)


#Some old files not used anymore
{
printf "MOV FHEM/14_Cresta.pm unused\n" 
printf "MOV FHEM/14_SIGNALduino_AS.pm unused\n" 
printf "MOV FHEM/14_SIGNALduino_un.pm unused\n"
printf "MOV FHEM/14_SIGNALduino_ID7.pm unused\n"
printf "MOV FHEM/14_SIGNALduino_RSL.pm unused\n" 
}  >> controls_signalduino.txt

