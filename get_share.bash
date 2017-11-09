#!/bin/bash

#Updated 10/18 - Josh :: Added to -m and added -all
#Updated 10/19 - Josh :: Added 'vmware -v' to check sn
#Updated 10/31 - Josh :: Added 'drac', getcreds, rack (+sort, +individual rows)
#Updated 11/6  - Josh :: Added 'ilo'

#####################################################################################################################################################
# From Comments -HBA EXAMPLE
#	function updatecheckhba { 
#		if [ "$1" = "-l" ] || [ "$1" = "-L" ] ; then echo -e "USING LIST: $2\n";list=$(cat "$2");else echo -e "NO LIST SELECTED\n"
#		for i in $@ ; do list+=$(echo -e "\n$@");done;fi
#		for i in $(echo "$list"); do echo -e "===$i===\n";sshpass -p##### ssh admin@$i 'switchshow' | sed 's/[:.]//g' > $i;done;echo $list;unset list;
#	}
#	function checkhba { 
#		hba="$(sshpass -p###### ssh -q -o StrictHostKeyChecking=false root@$1 'esxcfg-scsidevs -a 2> /dev/null;for i in $(ls /sys/class/fc_host 2> /dev/null); do cat /sys/class/fc_host/$i/port_name | sed 's/0x//g' 2> /dev/null;done;')"
#		;echo -e "\n====$1====\n$hba";
#		out=$(for i in $(echo "$hba"  | awk '{print $1,$3,$4}' | sed -e 's/[.:]/ /g' -e 's/fc//g'); do grep "$i" ~/audit/* 2> /dev/null;done); echo -e "\n>>HBA Connections\n$out"; 
#	}

#just incase
unset list
unset grep
unset csv
unset cdp_script_location
unset list

export cdp_script_location="/usr/local/bin/get_cdp"
echo

checkpkginstall () {

case $1 in
	0) 
		;;
	1)
		echo "$2 - Missing Package"
		;;
	*)
		echo "Unsure how to handle $1 | run dpkg -s $2"
		;;
esac
}

# Check packages
dpkg -s html2text ipcalc sshpass fping parallel > /dev/null 2>&1

if [ $? -eq 1 ]
then
	echo "=====OOPS! YOU DUN GOOFED====="
	echo "-- Please fix the following --"
	echo
	
	for pkg in html2text ipcalc sshpass fping parallel
	do
		dpkg -s $pkg > /dev/null 2>&1
		checkpkginstall $? $pkg
	done
exit
fi

comment () {
clear
: " Need to edit this? Open notepad++ (or w/e you want) and replace '/t' with /t and then reverse when done. Or turn it into actual comments, up to you."
	echo -e "
\t=========== Why did I put this in a function instead of a comment? To make it more accessible ==============
\tRecent Fixes:::
\t- [######]Added if no ###### search by entry then check sn, if fails then check if ip, if ip then get name from nslookup
\t- [MAIN]Changed if not file argument then check if first entry starts with "-" which means first entry is argument then shift
\t- [######]Fixed multiple search results formatting
\t- [######]Removed using ipcalc -c because -c option is not check in debian
\t- [ALL] FORGET FOR LOOPS, ITS ALL ABOUT THAT PARALLEL (replaced lots of ifs)

\tKnown Issues:::
\t- [FIXED]If ###### search contains multiple results (3 number tag returns multiple) formatting is broken
\t- No indication of mismatching hostname
\t\tCan't really check if entry is hostname because of different naming conventions and ability to search by sn,tag, and ip
\t- Mismatch name and no ###### Results
\t\tSearch for 065 but returned 65 (because no 065 result, then search from checksn)
\t\t\tCan do search ###### for entry if nothing then search ###### for search results hostname: field
\t\t\t\t###### is slow and will increase output time

\tIdeas:::
\t- Consolidate searches for ######
\t- For getting neighbor info (cdp,lldp,hba) if returns empty:
\t\t\t#ANOTHER OPTION IS HAVING IT RUN AGAINST ALL END CONNECTIONS FROM ###### PULL OF DEVICE 
\t\t\t#(filenames = end device name, if file older than X then overwrite or add argument to refresh - for multiple pulls)
\t\t(If Host Accessible + Switch accessible) 
\t\t:$ get [ -make-mac| -make-hba ] OutputFilename
\t\t\t-1st part would be a -make-[type] command to run against a switch to pull table and format
\t\t:$ get [-compare-mac | -compare-hba] OutputFilenameFromMakeOption [Run against file or fed devices]
\t\t\t- The get option would specify what to pull from HOST (mac vs wwn)
\t\t\t- Compare(grep) pulled to previously made file (formatted neighbor table)
\t\tFor lldp atleast parse lldpnetmap
\t\t#To see what I used, look at script top comment in source - just needs to be refined a bit
\t- Add option to do ###### search against costcenter, racks, pods,rows, etc
\t- Add csv option for "more info" instead of just "basic info"
\t\teasy just copy over from basic info
\t\t\tproblem is formatting for missing fields (or not? currently at home so can't test https://media3.giphy.com/media/QF0qzNUO8FfX2/giphy.gif )
\t- Add ILO accounts push + verification argument
\t\tWould be nice to export config, modify and make universal so you don't have to send multiple commands but a single "import" from ILO
\t\t\tget vendor + version through curl ilo page?
\t- Addding [-validate] option to verify deployments
\t\tFeed it a list 
\t\t\tverify device ILO entry in DNS
\t\t\t\tVerify ILO pings
\t\t\t\tVerify ILO accounts
\t\t\tVerify device exists in ######, DNS, and ###### (correct hostname, serial, tag, costcenter, tennant, ritm) 
\t- For CheckSN, try different logins if 1 doesn't work 

\t::: IDEAS NOT PART OF THIS SCRIPT :::
\t- Enable SNMP on everything, including the espresso machine.
\t\tCan do so much validation with only snmp 
\t- Consolidate all the HP/Dell RMA accounts
\t- GIT, setup git access for tooling and home all scripts there
\t\tshow people how awesome git is
\t\t\tDon't even need to learn to use git from terminal, use through web and if need then just (curl git.yourscript | bash)
\t- Devices shouldn't be manually added to ######
\t\tAdd job after ###### device creation to add device to ###### (no name mismatch)
\t\t\tmaybe even change ###### names to be [name-sn] so you can search by either
\t\t\t###### Create Host > Host Data > New ###### Device [Name-SN]
\t\t\t\tafter this ofc manually entry of cabling unless you can AUTOMATE ###### cable population
\t\t\t\t\t#lspci get pci slot number
"
}
#####################################################################################################################################################


###### () {
	if [ -z "$1" ]
	then 
	echo "---$1 Input is empty - DONT BREAK THE SYSTEM"
	exit
	fi
	
		: "We can't use $1 becase we need to modify it later incase there are no results, so we turn it into $search"
	search=$1
	curl='curl -s "#######GetByQuery?where=hostname+like+%27%25$search%25%27+or+Serial#+like%27%25$search%25%27+or+Tag+like%27%25$search%25%27"'
	npull=$(eval $curl | sed -e 's/,/\n/g' -e 's/"//g' -e 's/:/: /g' -e 's/Phase . (//g' -e 's/)//g' -e 's/Pod */Pod/g' | eval $grep | sed 's/RackUNumber: .*/& \n/g')
	
	if [ -z "$npull" ]
	then
		: "If what we searched return nothing, then try to pull its SN, if fails then check if it is IP and try looking up by DNS name"
		checksn=$(check -sn $1)
		if [ ! -z "$checksn" ]
		then
			search=$checksn
			npull=$(eval $curl | sed -e 's/,/\n/g' -e 's/"//g' -e 's/:/: /g' -e 's/Phase . (//g' -e 's/)//g' -e 's/Pod */Pod/g' | eval $grep)
			
			if [ -z "$npull" ]
			then
				echo "Pulled SN:"$checksn"- Unable to find in ######"
			fi

		else
			
			if [[ $search =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			  ip=0
			else
			  ip=1
			fi
			
			case $ip in
				0)
					nslookup=$(nslookup $1)
					case $? in
						0)
							name=$(echo "$nslookup" | grep "name =" | awk '{print $4}'| sed 's/\./ /g' | awk '{print $1}')
							search=$name
							npull=$(eval $curl | sed -e 's/,/\n/g' -e 's/"//g' -e 's/:/: /g' -e 's/Phase . (//g' -e 's/)//g' -e 's/Pod */Pod/g' | eval $grep)
							
							if [ -z "$npull" ]
							then
								echo "Unable to find $1 - $name"
							fi
						;;
						1)
							echo "Nslookup failed - $1"
						;;
					esac
					;;
				1)
					echo "Unable to find data - $1"
					;;
				*)
					echo "ipcalc INVALID - $1"
					;;
			esac
		fi
	fi
	echo "$npull"
}

rack () {
unset grep
unset curl
unset npull
unset room
unset row
unset out
unset devices
unset ask_user_######

yellow=`tput setaf 3`
blue=`tput setaf 6`
green=`tput setaf 2`
reset=`tput sgr0`


function getroom { read -p "${green}Enter Room #: ${reset}" room ; room=$(echo "${room}" | sed 's/*/%25/g' );}
function getrow { read -p "${green}Enter Row [Z*/Z1*/Z07..]: ${reset}" row ; row=$(echo "${row}" | sed 's/*/%25/g' | awk '{print toupper($0)}');}
function check_input {
    while [ $(echo "${room}" | wc -w) != 1 ]; do echo -e "\n${red}Invalid ${red}Output: [${room}] -- ${yellow}Please enter single digit number${reset}";getroom;done
    while [ $(echo "${row}" | wc -w) = 0 ]; do echo -e "\n${red}Invalid ${red}Output: [${row}] -- ${yellow}Please enter a row${reset}";getrow;done
    }

if [[ $# -eq 0 ]]
then
    echo -e "\t${yellow}Use * as a wildcard${reset}"
    getroom
    getrow
elif [[ $# -ne 2 ]]
then
    echo -e "${red}ERROR - Requires 2 arguments.\n${yellow}Use * as a wildcard\n\t${blue}Usage: [Room # (1,2,3)] [Row (C*,C1*,C10)]${reset}"
else
    room=$(echo "${1}" | sed 's/*/%25/g' )
    row=$(echo "${2}" | sed 's/*/%25/g' | awk '{print toupper($0)}')
fi

check_input
echo "${blue}Running ###### Search...${reset}"

grep="grep -E 'tag:|Name|SN|#Room|#Rack|#U' | sed 's/.*://g' | paste -sd, | sed -e's/\(\([^,]*,\)\{5\}[^,]*\),/\1\n/g'"
curl='curl -s "########{room}%25%27+and+RackName+like+%27${row}%27"'

npull=$(for row in $row;do eval ${curl} | sed -e 's/,/\n/g' -e 's/"//g' -e 's/:/: /g' -e 's/Phase . (//g' -e 's/)//g' -e 's/Pod */Pod/g' | eval $grep  ; done)

if [ -z "$npull" ]
then
echo "${yellow}Woops! There were no search results. Don't forget to use * as a wildcard!${reset}"
exit 1
else

for i in $(echo "$npull" |sed 's/ //g' | sed 's/,/, /g' | awk '{print $5}' | sort | uniq);do echo -e "\n==$i" | sed 's/,//g' ;echo "$npull" |sed 's/ //g' | sed 's/,/, /g' | awk -v var="$i" '$5 == var'| sort -rgk6;done | column -t
echo -e "\n${blue}Total Results: $(echo "${npull}" | awk '{print $1}'| wc -w)${reset}\n\t${yellow}---Easy Excel Paste!---${reset}"
fi

function check_###### {
        unset ######
        ######=$(curl -s "######dev_name=$1" | html2text -width 100 )

        if ( echo "$######" | grep "No devices were found" > /dev/null )
        then
        echo "$1 -- NOT_Found"
        else
        echo "$1 -- Found"
        fi
        }

read -p "${green}Would you like to check if devices are in ######? [y/n]:${reset}" ask_user_######

if [ "$ask_user_######" = "y" ]
then
        SECONDS=0
    devices=$(echo "${npull}" | awk '{print $1}' | sed 's/,//g' | sort | uniq)
    export -f check_######
    unset out
    echo -e "\n ${blue}Checking wire map for ${yellow}[$(echo "$devices" | wc -w)] ${blue}devices${reset} \n"
    exec 5>&1
    out=$(parallel  -k --no-notice 'check_######' ::: $devices | tee >(cat - >&5))
    echo -e "\n\n ${blue}============== Clean Output ==============${reset}"
    echo "$out" | column -t
        duration=$SECONDS
        echo -e "\n\t${blue}Completion Time: ${yellow}$(($duration / 60)) minutes and $(($duration % 60)) seconds${reset}"
fi
}

check () {
	: "Here we check to see if we were provided 2 inputs 
	   The only reason why that would be is if we got here from ###### trying to pull SN from host"
	if [[ $# -eq 2 ]]
	then 
		checkarg=$1
		shift
	fi
	
	: "fping once with a timeout of .5 seconds for fast ping checks"
	fping -c1 -t500 $1 > /dev/null 2>&1
	
	: "#If successfully pings"
	if [ $? -eq 0 ]
	then
		: "####Here we check to see what to return, either just the sn (called from ###### function) or hostname,Serial# (normal)"
		case $checkarg in
			-sn)
				sn=$(sshpass -p$password ssh -q -o StrictHostKeyChecking=false $user@$1 "echo \$(esxcfg-info | grep -m1 Serial | sed -e 's/|.*Ser.*er.//g' -e 's/\.\.//g' -e 's/ * \.//g')")
				;;
			*)
				sn=$(sshpass -p$password ssh -q -o StrictHostKeyChecking=false $user@$1 "echo \$(hostname), \$(esxcfg-info | grep -m1 Serial | sed -e 's/|.*Ser.*er.//g' -e 's/\.\.//g' -e 's/ * \.//g'),\$(esxcfg-info -e), \$(vmware -v)")
				;;
		esac
	fi
	
	: "if $sn is NOT empty"
	if [ ! -z "$sn" ]
	then
		echo "$sn" 
	fi
}

###### () {
	: "######Do swearch and look for the character >, and remove [ ]"
	: "##### Get list of end connections, sort them, and then get unique entry for each one"
	switchlist=$(echo "$######" | awk '{print $7}' | sort | uniq)
	: "######Now for each of the unique end connections we're going to search ######"
	######search=$(parallel  -k --no-notice 'get -l' ::: $switchlist)
	: "######if $csv is NOT empty, only reason it wouldn't is from the -l or -compare-cdp and it is set to 1
	   ######This could be if $csv -eq 1 but this was a last minute change and it truly doesn't matter unless you're going to do more with it
	   ######So what this does, is if you want it as a csv then it needs to gather all the data under one variable 
			first and then format it as a whole, else it formats 2 parts differently
			"
	   
	if [ -z "$csv" ]
	then
		######search=$(parallel  -k --no-notice 'get -l' ::: $switchlist)
	else
		######search=$(parallel  -k --no-notice 'get -l' ::: $1 $switchlist)
	fi
	
	: "######If $###### is empty"
	if [ -z "$######" ]
		then
			echo -e "$1 [W]Failed Pull----\n"
		else
			: "Ignore lines that return Unable"
			echo "$######search" | grep -v "Unable" | column -t
			echo
			echo "$######" | column -t
			echo
	fi
}

function drac {
case $1 in
 -all)
 shift
 for host in $@
do
echo "====$host"
sshpass -p$password ssh -o StrictHostKeyChecking=no $user@$host 'racadm racdump'
echo
done
;;
 *)
 
for host in $@
do
echo "====$host"
sshpass -p$password ssh -o StrictHostKeyChecking=no $user@$host 'racadm racdump' | egrep -i '^MAC Address|^NIC. Ethernet|^Service Tag|^Current IP|^DNS RAC Name|^System Model|^Host Name|^Power Status|..:..:..:..:..:..' | grep -E -v '::|root'
echo
done
;;
esac
}

ilo () {
for host in $@
do
echo -e "\n=======$host"
sshpass -p$password ssh -o StrictHostKeyChecking=no $user@$host 'show system1' | grep '=' | grep -v status
sshpass -p$password ssh -o StrictHostKeyChecking=no $user@$host 'show system1/network1/integrated_nics' |grep '=' | grep -v status
done
}

checkcdp () {
	echo -e "\n  =[ $1 ]=" 
	: "######I wasn't able to put this into a single line so I'm just feeding the remote host a "script""
	sshpass -p$password ssh -q -o StrictHostKeyChecking=false $user@$1 'sh -s' < $cdp_script_location
}


: "######Check if we want to use a file, cant do it in argument case or else youd have to do a for loop and exit it and I dont want to"
case $1 in
	-f|--f|F|-F|--F)
		echo -e "==== USING FILE: $2 ====\n"
		list=$(cat "$2")
		: "#####Use Case: get -f thatoneaudit
		   #####If the 3rd argument is empty, we know it's just a basic pull, if it's not then it has to be argument."
		if [ "$3" = "" ]
		then
			arg="-b"
		else
			arg=$3
		fi
		;;
	*)
		: "######Just making sure the first argument is an option (starts with -) if it doesn't we know its part of the search"
		if [ "$(echo "$1" | cut -c1)" = "-" ]
		then
			arg=$1
			shift
		elif [ "$1" = "" ]
		then
		arg=""
		else
			arg="-b"
		fi
		
		: "#####We've shifted everything that is not meant to be searched (options) so make a list out of the rest"
		for i in $@
			do list+=$(echo -e "$i ")
		done
		;;
esac

checkarg () {
	if [ -z "$list" ]
	then echo "No Arguments selected"
	exit
	fi
}

getcreds () {
		echo "=== Enter the credentials you'd like to use ==="
		read -p "User: " user
		export user
		echo -n "Password: "
		read -s password
		export password
		echo -e "\nRunning...."
}

#For parallel, function isn't called from parallel? Who cares man just do it
#"you need jobs that take longer to run than the overhead introduced by parallelizing them"
export -f ######
export -f check
export -f checkcdp
export -f ######
export -f checkpkginstall
export -f comment
export -f drac
export -f ilo
: "#####We've previously set $arg now we check to see what we're running against the list in a for loop"
: "#####For all those repetitive grep= it can be set at the top of the script and only specify when there's a change but this makes it easier to track"
case $arg in
	-wm|--wm|-######|--######)
		checkarg
		export grep="grep -E 'tag:|hostname|Serial#|room|RackName|RackUNumber'"
		parallel  -x -k -j 8 --no-notice 'echo -e "\n  ====[{}]====";###### {}' ::: $list
		;;

	-lwm|--lwm|-l######|--l######)
		checkarg
		export grep="grep -E 'tag:|hostname|Serial#|room|RackName|RackUNumber' | sed 's/.*://g' | paste -sd, | sed -e's/\(\([^,]*,\)\{5\}[^,]*\),/\1\n/g'"
		export csv=1
		parallel  -x -k -j 8 --no-notice '######' ::: $list
		;;
	-mwm|--mwm|-m######|--m######)
		checkarg
		export grep="grep -E 'tag|hostname||Serial#|assetOperationalStatus|subStatus|room|RackName|RackUNumber|costCenter|owner|tenant|devicetype|poNumber|prNumber'"
		parallel  -x -k -j 8 --no-notice 'echo -e "\n  ====[{}]====";###### {};echo;###### {}' ::: $list
		;;
	-l|--l|-L|--L|-less|--less)
		checkarg
		: "#####This grep is different because it's the CSV format"
		export grep="grep -E 'tag:|hostname|Serial#|room|RackName|RackUNumber' | sed 's/.*://g' | paste -sd, | sed -e's/\(\([^,]*,\)\{5\}[^,]*\),/\1\n/g'"
		parallel  -x -k -j 8 --no-notice '######' ::: $list
		;;
	-m|--m|-M|--M|-more|--more)
		checkarg
		export grep="grep -E 'tag|hostname|devicetype|Serial#|assetOperationalStatus|subStatus|room|RackName|RackUNumber|costCenter|owner|tenant|devicetype|poNumber|prNumber'"
		parallel  -x -k -j 8 --no-notice 'echo -e "\n  ====[{}]====";###### {}' ::: $list
		;;
	-b)
		checkarg
		export grep="grep -E 'tag:|hostname|Serial#|room|RackName|RackUNumber'"
		parallel  -x -k -j 8 --no-notice 'echo -e "\n  ====[{}]====";###### {}' ::: $list
		;;	
	-r|-raw|--r|--raw)
		checkarg
		: "#####Mainly for debugging"
		echo -e "Input=$@\nList=$list\nRaw Output::::"
		for i in $(echo "$list")
		do
			curl "#######%27%25$i%25%27+or+Serial#+like%27%25$i%25%27+or+Tag+like%27%25$i%25%27"
		done
		;;
	-cdp|--cdp)
		checkarg
		getcreds
		echo
		parallel  -x -k -j 8 --no-notice "checkcdp" ::: $list
		;;
		
	-compare-cdp)
		checkarg
		getcreds
		echo
		grep="grep -E 'tag:|hostname|Serial#|room|RackName|RackUNumber'"
		parallel  -x -k -j 8 --no-notice "###### {};checkcdp {}" ::: $list
		;;
	-sn|--sn)
		checkarg
		getcreds
		echo
		parallel  -x -k -j 8 --no-notice "check" ::: $list
		;;
	-comment|-comments)
		comment
		;;
	-drac|--drac)
		checkarg
		getcreds
		parallel  -x -k -j 8 --no-notice "drac" ::: $list
		
		;;
	-ilo|--ilo)
		checkarg
		getcreds
		parallel  -x -k -j 8 --no-notice "ilo" ::: $list
		;;
	-rack|--rack)
		rack $@
	;;
	-full-test)
		echo "I'm calling myself for all the possible arguments"
		echo '" " -comment -l -m -wm -lwm -mwm -sn -cdp -compare-cdp'
		read -p "Press enter to continue"
		for i in " " -comment -l -m -wm -lwm -mwm -sn -cdp -compare-cdp
		do
		echo "=================== {{ $i -Start }} ==================="
		get $i $1 $2
		echo
		echo "=================== {{ $i - Finish}} ==================="
		read -p "Press enter to continue"
		done
		;;
	-all|--all|-All|--All|-ALL|--ALL)
		search=$1
		curl='curl -s "#######%27%25$search%25%27+or+Serial#+like%27%25$search%25%27+or+Tag+like%27%25$search%25%27"'
		eval $curl | sed -e 's/,/\n/g' -e 's/"//g' -e 's/:/: /g' -e 's/Phase . (//g' -e 's/)//g' -e 's/Pod */Pod/g' 
		;;
		
	*|' '|" ")
		: "#####This could be part of a function as well to make it cleaner"
		echo "

		'''''''''''''''''''''''''''
		'   _____ ______ _______  '
		'  / ____|  ____|__   __| '
		' | |  __| |__     | |    '
		' | | |_ |  __|    | |    '
		' | |__| | |____   | |    '
		'  \_____|______|  |_|    '
		'                         ' 
		'''''''''''''''''''''''''''
		'Best thing since the internet' - Jeff Bezos
		'10/10' - IGN
		'Cool name' - me

		By Josh Avalos () // http://Avalos.info | May 2017

		Basic Info=hostname,serial,tag,room,rack,u-height
				
		Usage: 
		>>>Can be ran against hostname(s) or serial(s) or tag(s) or ip(s)
		
		get [-f|--f|F|-F|--F] YourFile [Option]      - get data list from file and run [empty/selected option] against it
		get [::Empty Option::]                         - get basic info 
		get [-wm|--wm|-######|--######]              - get basic info + ######
		get [-l|--l|-L|--L|-less|--less]               - get basic info in csv format
		get [-lwm|--lwm|-l######|--l######]          - get basic info in csv format + ######
		get [-m|--m|-M|--M|-more|--more]               - get basic info + more info 
		get [-mwm|--mwm|-m######|--m######]          - get basic info + more info + ######
		get [-rack|--rack]                             - Pull ###### per rack/row
		get -raw                                       - get raw ###### curl
		
		(If host is online and accessible)
		
		get [-sn|--sn]                                 - get local hostname + SN
		get [-cdp|--cdp]                               - get cdp (Cisco Discovery Protocol)
		get [-compare-cdp]                             - get basic info in csv format + ###### + cdp
		
		{idrac}
		
		get [-drac|--drac]							   - Pull Drac Info (Mac/Dns/Ip/Model/Tag/PowerStat/Macs)
		get [-comment|-comments]                       - Look at script comments
		
		
		get [-full-test] device1 device2               - Run every argument :: FOR TESTING best with 2 devices
		>>>>>>>>> How It Works <<<<<<<<<<<
		It just does
		"
		exit
		;;
esac


#Because we exported
unset list
unset grep
unset csv
unset cdp_script_location
unset user
unset password



