#!/bin/bash
echo 'Please make sure you either run this as "bash snake-setup32.sh" or chmod +x "./snake-setup32.sh"'
echo "If you didn't, please stop and restart properly"

while [ "$speed" = "" ]
do
echo -n "Please enter desired port speed [100/40]:"
read speed
case "$speed" in

100)  speed=100 
	  echo  "Setting speed to "$speed"G"
	;;
40)  speed=40
	 echo  "Setting speed to "$speed"G"
	;;
*) echo "Please enter 100 or 40"
	unset speed
   ;;
esac
done

stxt=$speed"G"


echo "Restarting ##### in order to check port configuration"
service ##### restart

echo "checking port config"
if [ "$(echo "$(#####)" | awk '{print $3}' | sed '1d' | grep -v $stxt)" = "" ]
	then
	echo "Ports configred to $stxt --Restarting ##### to clear ##### l3 egress"
	else
	while [ "$(echo "$(#####)" | awk '{print $3}' | sed '1d' | grep -v $stxt)" != "" ]
	do
	echo "Ports not configured for $stxt, attempting to configure"
		if [ "$(echo "$(#####)" | awk '{print $3}' | sed '1d' | grep -v $speed"G")" = "" ]
			then
			echo "Ports seem to be configured Correctly ($stxt) --Something may be wrong;exiting"
			echo 'echo "$(#####)" | awk '{print $3}' | sed '1d' | grep -v $stxt )'
			exit 1
			else
			echo "Checking to see if you have our super special file already"
			if [ -f /etc/#####.d/101-$stxt.conf ]
                then
                echo "101-$stxt.conf found in /etc/#####.d"
                echo "restarting ##### service"
                service ##### restart
                else
                echo "101-$stxt.conf not found in /etc/#####.d --creating"
                echo "port_config_path: /etc/cumulus.d/porttab.yaml.32x$speed" > /etc/#####.d/101-$stxt.conf
					if [ -f /etc/#####.d/101-$stxt.conf ]
                        then
                        echo "Successfully created -- Restarting #####"
                        service ##### restart
						if [ "$(echo "$(#####)" | awk '{print $3}' | sed '1d' | grep -v $stxt )" = "" ]
							then
                            echo "Successfully configured to $stxt"
                            else
                            echo "Port configuration unsuccessful, exiting"
							echo 'echo "$(#####)" | awk '{print $3}' | sed '1d' | grep -v $stxt)'
                            exit 1
                        fi
                        else
						echo "Something went wrong running the following:"
                        echo 'echo "port_config_path: /etc/cumulus.d/porttab.yaml.32x$speed" > /etc/#####.d/101-$stxt.conf'
                        echo "exiting"
                        exit 1
					fi
				fi
			fi
		done
		echo "Port configuration check complated"
fi

echo "Removing previously configured IP's"
for i in {1..32}
do ip addr flush dev jrp$i
done

echo "Configuring IP's and MTU"
for i in {1..32}
do
ip addr add 70.0.$i.2/24 dev jrp$i
ip link set dev jrp$i mtu 9100
done

echo "Shutting down ports"
for i in {1..32}
do
ip link set jrp$i down
done

echo "Ports configured, restarting ##### in order to clear ##### l3 egress"
service ##### restart
        if [ $(##### l3 egress show | sed '1d' | wc -l) = 1 ]
			then
			echo "Successfully cleared - [$(##### l3 egress show | sed '1d' | wc -l)] current entries"
			else
			echo "There's more than 1 entry in ##### l3 egress show, please investigate. Current[$(##### l3 egress show | sed '1d' | wc -l)]"
			echo '##### l3 egress show | sed '1d' | wc -l'
			exit 1
		fi

echo "Copying random files into random directories in order to confuse you"
cp -r #####/acl /usr/share/pyshared/
cp -r #####/bcmsdk /usr/share/pyshared/
cp #####/*.so /lib
cp #####/##### /usr/sbin/
echo "completed?"

echo "all ports down, now only upping Ixia ports (jrp1/32)"

# UP the ports connected to Ixia


# ARP Ixia port to ensure that we setup the nexthop entries
# NOTE: ordering matters!!!
#       ##### l3 egress show should have 100003 and 100004 pointing to Ixia

echo "Upping jrp1"
ip link set jrp1 up
sleep 2
echo "arping 70.0.1.1"
wait=0
while [ "$(arping 70.0.1.1 -c 1 | grep "1 packets received")" = "" ]
do
if [ $wait -gt 5 ]
        then
        echo "waited too long, please troubleshoot;exiting"
        unset wait
        exit 1
        else
        echo "70.0.1.1 isn't arping, retrying:[Tries $wait]"
        wait=$(expr $wait + 1)
        sleep 5
fi
done
unset wait
echo "arping 70.0.1.1 -successful"
echo "verifying entry was added to ##### l3 egress"
wait=0
while [ $(##### l3 egress show | sed '1d' | wc -l) -ne 2 ]
do
if [ $wait -gt 5 ]
        then
        echo "waited too long, please troubleshoot;exiting"
        unset wait
        exit 1
		else
        echo "2 entries not found, waiting 3 seconds to populate:[Tries $wait] -- Found:[$(##### l3 egress show | sed '1d' | wc -l)]"
        wait=$(expr $wait + 1)
        sleep 5
fi
done
echo "Successfully added - [$(##### l3 egress show | sed '1d' | wc -l)] current entries"

echo "Upping jrp32"
ip link set jrp32 up
sleep 2
echo "arping 70.0.32.1"
wait=0
while [ "$(arping 70.0.32.1 -c 1 | grep "1 packets received")" = "" ]
do
if [ $wait -gt 5 ]
        then
        echo "waited too long, please troubleshoot;exiting"
        unset wait
        exit 1
        else
        echo "70.0.32.1 isn't arping, retrying:[Tries $wait]"
        wait=$(expr $wait + 1)
        sleep 3
fi
done
unset wait
echo "arping 70.0.32.1 -successful"

echo "verifying entry was added to ##### l3 egress"
wait=0
while [ $(##### l3 egress show | sed '1d' | wc -l) -ne 3 ]
do
if [ $wait -gt 5 ]
        then
        echo "waited too long, please troubleshoot;exiting"
        unset wait
        exit 1
else
        echo "3 entries not found, waiting 3 seconds to populate:[Tries $wait] -- Found:[$(##### l3 egress show | sed '1d' | wc -l)]"
        wait=$(expr $wait + 1)
        sleep 3
fi
done
echo "Successfully added - [$(##### l3 egress show | sed '1d' | wc -l)] current entries"

# Enable the rest of of the interfaces
echo "upping all ports"
for i in {2..31}; do
  ip link set jrp$i up
done

unset wait
wait=0
while [ $(vtysh -c "show int" | grep "jrp" | grep -v "disable" | grep "col is up" | wc -l) -ne 32 ]
do
	if [ $wait -gt 5 ]
		then 
			echo "Waited too long, didn't find 32 ports up, please investigate"
			echo 'vtysh -c "show int" | grep "jrp" | grep -v "disable" | grep "col is up" | wc -l'
			exit 1
		else
			echo "Didn't find, 32 ports up"
			echo "Ports found up:[$(vtysh -c "show int" | grep "jrp" | grep -v "disable" | grep "col is up" | wc -l)]"
			echo "waiting 2 seconds"
			wait=$(expr $wait + 1)
			sleep 2
	fi
done
unset wait
echo "All ports upped, adding neighbors"
for i in {2..31}; do
  ip neigh add 70.0.$i.1 lladdr 00:11:22:33:44:$i dev jrp$i
  
  #sleep 1
  while [ $(##### l3 egress show | sed '1d' | wc -l) != $(expr $i + 2) ]
	do 
	echo "jrp$i 70.0.$i.1 00:11:22:33:44:$i isn't populated yet, waiting 1 second"
	echo "Current:[$(##### l3 egress show | sed '1d' | wc -l)] -- Expecting:[$(expr $i + 2)]"
	sleep 1
  done
  echo "jrp$i 70.0.$i.1 00:11:22:33:44:$i - Successfully added"
done

echo "All neighbors should be added, checking"
if [ $(##### l3 egress show | sed '1d' | wc -l) != 33 ]
	then
	echo "Missing Neighbors. Current [$(##### l3 egress show | sed '1d' | wc -l)]"
	exit 1
	else
	echo "All Neighbors found, proceeding"
fi

echo "Disabling #####"
monit unmonitor #####

echo "Unconfiguring and moving existing ACLs to /tmp"
mv /etc/#####.d/00-group/* /tmp/
echo "Installing per-port ACLs"
cp 100-port32-redirect.rules /etc/#####.d/00-group/

##### install -f

for i in {1..7}; do
    acl_output=$(##### dump chg ifp_tcam_wide 0 1)
        if [ -z "$acl_output" ]; then
            ##### install -f
        else
            break
        fi
done

# disable egress vlan filtering
##### "modify egr_port 0 132 EN_EFILTER=0"
