#!/usr/bin/expect
#Losjava ###### Script - Bastion
log_user 0
set timeout 10
set host [lindex $argv 0]
set port [lindex $argv 1]
set interact [lindex $argv 2]
set prompt ":|#|\\\$"

#Make sure there are 2 arguments Bastion/Host/Port | the [y] is optional at the end
if {[llength $argv] < 2} {
    puts "Usage: ScriptName \[######\] \[Port# without jrp\] "
    puts "If you know you want to stay IN the device after running the command, after the port you can put \"y\""
	puts "Example: .\\netgo ###-##-##-##-##-##-r1 45 y"
    exit 1
}

#stty echo removes the user input from displaying, so in this case for PW
stty -echo
send_user -- "Sudo Password for $host:"
expect_user -re "(.*)\n"
send_user "\n"
#re-enable echo
stty echo
#set the last output to $pass
set pass $expect_out(1,string)
#clears screen
puts \033\[2J
send_user -- "Connecting to $host and running commands on jrp$port\n\n"
eval spawn ssh -oStrictHostKeyChecking=no $host
expect -re $prompt
#spaces for funs, makes it look interesting :)
puts "\r                                 Connecting to $host"
expect {
	"not known" {
	 puts "Connection Failed, Please check host name: $host"
	 exit
	 }
	"Invalid argument" {
	 puts "Connection Failed, Please check host name: $host"
	 exit
	 }
}
expect -re $prompt
#more spaces for funs
puts "\r                                                                     Successfully connected to Host, Running commands on jrp$port"
send "sudo -s\r"
#If "password" is found, go back so it can escape out from finding "root"
expect {
    "password" {
     send "$pass\r"
         exp_continue
    }
    "root" {
     send "dcoport=$port;clear\r"
     send "clear;echo -e \"\\n\\n`hostname` Port=\$dcoport\\nScript By Josh Avalos@\\n\";decode-syseeprom | tr \'\[\\000-\\011\\013-\\037\\177-\\377\]\' \'\.\' | grep -e name -e model -e part_num -e serial_num;echo -e \"\\n =====> RX Errors (####) \";##### | grep -we Iface -e  jrp\$dcoport;echo -e \"\\n =====> Light Levels (#####)\";##### --port \$dcoport --dom | grep -e  VendorSN;##### --port \$dcoport --dom | grep  MonitorData -A 4 ;##### --port \$dcoport --dom|grep -e 10GEthernetComplianceCode;echo -e \"\\n =====> Interface Status (vtysh)\";vtysh -c \"show int jrp\$dcoport\" | grep -Ev \"index|flags\";echo -e \"\\n\\n =====> Neighbors (#####)\";##### | grep \"Interface:    jrp\$dcoport, via: LLDP\" -A 11| sed \'\/\^\-\/,$ d\';echo -e \"\\n\\n\"\r"
     }
    timeout {
     puts "Running..."
     exp_continue
    }
}

expect "$host Port=$port"
log_user 1
puts "\n\r$host Port=$port\n\rScript by Losjava@\r"
expect "root"
sleep 1

if { $interact == "y"} {
      send "\n"
	  puts "\n\nStaying Connected\n\n"
      interact
	  exit
}
send_user "\n\n\n\rStay Logged In?:y/n:"
expect_user -re "(.*)\n" {set interact $expect_out(1,string)}
if { $interact == "y"} {
      send "\n"
      interact
	  exit
}
exit		

