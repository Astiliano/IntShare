mainsite="Site2"
loc=$(echo $mainsite | sed "s/Site//g" )

while :
do
if [ "$pdwho" = "###SITE"$loc"+Data+Tech" ]
then
pdwho="###SITE"$loc"+Data+Tech"
site="###SITE"$loc
else
pdwho="###SITE"$loc"+Data+Tech"
site="###SITE"$loc
fi
range=$(expr `date +%s` - 259200)


curl -ksu REMOVEDLOL-Losjava "######&modified_date=$range&resultCount=100" | egrep '<title>00' | sed "s/<title>//g" | sed 's/<\/title>//g' > $mainsite.txt
date=$(date +"%Y-%m-%d")
time=$(date +"%H:%M:%S")

while read i; do
ii=$(echo $i | sed 's/\r//g')
query=$(mysql --skip-column-names -u NOPE -pNOPE -e "Select TT from Paging.Tickets Where TT = $ii ")
if [[ $ii == $query ]]
then
#If Found in DB
echo "$ii was sent" > /dev/null 2>&1
else

#If Not Found In DB
mysql -u root -pNOPEAGAIN -e "insert into Paging.Tickets Values ('$ii','$site','$date','$time')";

#This is for main site 2 and 51
curl -sF "token=NOPE" -F "user=NOPE" -F "message= $ii @ $mainsite -- $time" -F "priority=0" -F "sound=updown" "https://api.pushover.net/1/messages.json" > /dev/null 2>&1

#This is for site 1 and 50
curl -sF "token=NOPE" -F "user=NOPE" -F "message= $ii @ $mainsite -- $time" -F "priority=0" -F "sound=gamelan" "https://api.pushover.net/1/messages.json" > /dev/null 2>&1

#This will be for site 4 and 52
curl -sF "token=NOPE" -F "user=NOPE" -F "message= $ii @ $mainsite -- $time" -F "priority=0" -F "sound=gamelan" "https://api.pushover.net/1/messages.json" > /dev/null 2>&1

sleep 1
echo "This is a notification for tt: #######/$ii" | mail -s "Ticket $ii [[$mainsite-Sev2]] -- $time" ###SITE-alert@#### -- -f Sev2Alert@#####
sleep 1

fi
done <$mainsite.txt

#echo "Done with $pdwho"
sleep 1
done


