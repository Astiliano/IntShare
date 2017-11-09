#!/bin/bash
while :
do
date=$(date +"%Y-%m-%d")
time=$(date +"%H:%M:%S")
	
list=$(mysql --skip-column-names -u ##### -p##### -e "Select ip from pdu_monit.pdu_list where monitor like 'YES'";)
for i in $(echo "$list")
do
#echo $i
echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceStatusLoadState.1 | sed 's/INTEGER: //';snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoadState.1  | sed 's/INTEGER: //';snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoadState.2  | sed 's/INTEGER: //';snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoadState.3  | sed 's/INTEGER: //')" | grep -q "Overload" && alarm=yes || alarm=no

if [ "$(echo "$alarm")" == "yes" ]
then
	ttpull=$(mysql --skip-column-names -u ##### -p##### -e "Select ip,tt from pdu_monit.ticket_list where ip like '$i' AND status like 'open'";)
	if [ "$(echo "$ttpull")" = "" ]
	then 
	#echo "$i No Ticket - Alarm=Yes"
	sendalarm=yes
	else 
	#echo "$i Yes Ticket - Checking"
		for tt in $(echo "$ttpull" | grep "$i" | awk '{print $2}')
		do
		#IF NOT OPEN
		if [ "$(echo "$(curl -ksu ###-oncall-assign:###### "######/tickets/$tt" | grep "status" | grep -ie "resolved" -ie "closed")")" != "" ]
		then
		#UPDATE TT TO CLOSED
		#echo "$i TT open in DB, updating to close - Alarm=Yes"
		mysql --skip-column-names -u ##### -p##### -e "UPDATE pdu_monit.ticket_list SET status='closed' WHERE tt='$tt'";
		sendalarm=yes
		fi
		done
		
	fi
fi

if [ "$(echo "$sendalarm")" = "yes" ]
then
#echo "$i send alarm for is yes"
	hostname=$(echo "Hostname: "$(snmpwalk  -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceStatusName.1 | sed 's/STRING: // ; s/"//g'))
	serial=$(echo "Serial: $(snmpwalk  -Ov -v 2c -c public $i PowerNet-MIB::sPDUIdentSerialNumber.0| sed 's/STRING: // ; s/"//g')")

	#Voltage ###
	voltage=$(echo "Voltage: $(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2PhaseStatusVoltage.1  | sed 's/INTEGER: //')")
	#Phase Power Kw #.##
	phaseloadkw=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2PhaseStatusPower.1 | sed 's/INTEGER: //'); while [ $(echo -n "$pull" | wc -c) -lt 3 ]; do pull=$(echo -n "0""$pull");done; phaseloadkw=$(echo "kW: "$(echo $pull  | sed 's/^\(.\{1\}\)/\1./'));echo $phaseloadkw)

	#Phase Apparent Power KvA #.##
	kva=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2PhaseStatusEntry.8.1 | sed 's/INTEGER: //'); while [ $(echo -n "$pull" | wc -c) -lt 3 ]; do pull=$(echo -n "0""$pull");done; kva=$(echo "kVA: "$(echo $pull  | sed 's/^\(.\{1\}\)/\1./'));echo $kva)
	#KW #.##
	deviceloadstate=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceStatusLoadState.1 | sed 's/INTEGER: //')
	deviceload=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceStatusPower.1 | sed 's/INTEGER: //'); while [ $(echo -n "$pull" | wc -c) -lt 3 ]; do pull=$(echo -n "0""$pull");done; deviceload=$(echo $(echo $pull  | sed 's/^\(.\{1\}\)/\1./')"kW");echo $deviceload)
	devicenearoverload=$(echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceConfigNearOverloadPowerThreshold.1 | sed 's/INTEGER: //' |sed 's/^\(.\{1\}\)/\1./')""kW")
	deviceoverload=$(echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceConfigOverloadPowerThreshold.1 | sed 's/INTEGER: //' |sed 's/^\(.\{1\}\)/\1./')""kW")
	deviceloadpeak=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceStatusPeakPower.1 | sed 's/INTEGER: //'); while [ $(echo -n "$pull" | wc -c) -lt 3 ]; do pull=$(echo -n "0""$pull");done; deviceloadpeak=$(echo $(echo $pull  | sed 's/^\(.\{1\}\)/\1./')"kW");echo $deviceloadpeak)
	deviceloadpeaktime=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2DeviceStatusPeakPowerTimestamp.1 | sed 's/STRING: //; s/"//g')

	#Phase Load AMPS ##.#
	phaseloadstate=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoadState.1  | sed 's/INTEGER: //')
	phaseload=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoad.1  | sed 's/Gauge32: //');if [ $(echo -n $pull| wc -c) -gt 2 ]; then phaseload=$(echo $pull | sed 's/^\(.\{2\}\)/\1./'); else phaseload=$(echo $pull | sed 's/^\(.\{1\}\)/\1./' );fi;unset pull;echo "$phaseload""Amps")
	phasenearoverload=$(echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadPhaseConfigNearOverloadThreshold.phase1  | sed 's/INTEGER: //')""Amps")
	phaseoverload=$(echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadPhaseConfigOverloadThreshold.phase1  | sed 's/INTEGER: //')""Amps")
	phaseloadpeak=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2PhaseStatusEntry.10.1  | sed 's/INTEGER: //');if [ $(echo -n $pull| wc -c) -gt 2 ]; then phaseloadpeak=$(echo $pull | sed 's/^\(.\{2\}\)/\1./'); else phaseloadpeak=$(echo $pull | sed 's/^\(.\{1\}\)/\1./' );fi;unset pull;echo "$phaseloadpeak""Amps")
	phaseloadpeaktime=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2PhaseStatusEntry.11.1 | sed 's/STRING: //; s/"//g')

	# Bank overload AMP ##.#
	banknearoverload=$(echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2BankConfigNearOverloadCurrentThreshold.1  | sed 's/INTEGER: //')""Amps")
	bankoverload=$(echo "$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2BankConfigOverloadCurrentThreshold.1  | sed 's/INTEGER: //')""Amps")

	#Bank 1 Amps
	bank1loadstate=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoadState.2  | sed 's/INTEGER: //')
	bank1load=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoad.2  | sed 's/Gauge32: //');if [ $(echo -n $pull| wc -c) -gt 2 ]; then bank1load=$(echo $pull | sed 's/^\(.\{2\}\)/\1./'); else bank1load=$(echo $pull | sed 's/^\(.\{1\}\)/\1./' );fi;unset pull;echo "$bank1load""Amps")
	bank1peak=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2BankStatusEntry.6.1  | sed 's/INTEGER: //');if [ $(echo -n $pull| wc -c) -gt 2 ]; then bank1peak=$(echo $pull | sed 's/^\(.\{2\}\)/\1./'); else bank1peak=$(echo $pull | sed 's/^\(.\{1\}\)/\1./' );fi;unset pull;echo "$bank1peak""Amps")
	bank1peaktime=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2BankStatusEntry.7.1 | sed 's/STRING: //; s/"//g')


	#Bank 2 Amps ##.#
	bank2loadstate=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoadState.3  | sed 's/INTEGER: //')
	bank2load=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDULoadStatusLoad.3  | sed 's/Gauge32: //');if [ $(echo -n $pull| wc -c) -gt 2 ]; then bank2load=$(echo $pull | sed 's/^\(.\{2\}\)/\1./'); else bank2load=$(echo $pull | sed 's/^\(.\{1\}\)/\1./' );fi;unset pull;echo "$bank2load""Amps")
	bank2peak=$(pull=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2BankStatusEntry.6.2  | sed 's/INTEGER: //');if [ $(echo -n $pull| wc -c) -gt 2 ]; then bank2peak=$(echo $pull | sed 's/^\(.\{2\}\)/\1./'); else bank2peak=$(echo $pull | sed 's/^\(.\{1\}\)/\1./' );fi;unset pull;echo "$bank2peak""Amps")
	bank2peaktime=$(snmpwalk -Ov -v 2c -c public $i PowerNet-MIB::rPDU2BankStatusEntry.7.2 | sed 's/STRING: //; s/"//g')


description=$(echo -e "\n>>>>>>Device Information |:| $(date)\n------------------\n\n$hostname\nIP: $i\n$serial\n$voltage\n$phaseloadkw\n$kva\n\n";printf '\n%-10s %-24s %-10s %-10s %-10s %-10s %-10s %-5s\n' Label State Current Alarm Warning Peak PeakDate PeakTime;echo -e "\n----------------------------------------------------------------------------------------------------------------\n";printf '\n%-10s %-24s %-10s %-10s %-10s %-10s %-10s %-10s\n' Device $deviceloadstate $deviceload $devicenearoverload $deviceoverload $deviceloadpeak $deviceloadpeaktime;printf '\n%-10s %-24s %-10s %-10s %-10s %-10s %-10s %-10s\n' Phase $phaseloadstate $phaseload $phasenearoverload $phaseoverload $phaseloadpeak $phaseloadpeaktime;printf '\n%-10s %-24s %-10s %-10s %-10s %-10s %-10s %-10s\n' Bank-1 $bank1loadstate $bank1load $banknearoverload $bankoverload $bank1peak $bank1peaktime;printf '\n%-10s %-24s %-10s %-10s %-10s %-10s %-10s %-10s\n' Bank-2 $bank2loadstate $bank2load $banknearoverload $bankoverload $bank2peak $bank2peaktime) 
title=$(echo "[### rPDU ALARM] ###-Lab $(mysql --skip-column-names -u ##### -p##### -e "select name,ip from pdu_monit.pdu_list where ip like '$i'";)")

newtt=$(echo "$(curl -i -su "###-oncall-assign:ME" -d "short_description=$title&details=$description&category=#####s&type=Networking+-+QA&item=#####+-+######&impact=5&requester_login=######" ######/tickets)" | grep "Location" | cut -c49-58)
mysql -u ##### -p##### -e "insert into pdu_monit.ticket_list Values ('$newtt','$i','$date','$time','open')";
#echo "$i tt:$newtt"
fi
unset alarm
unset sendalarm
sleep 10
date
echo $i
done

done






