#!/bin/bash
# Santiago Bassett <santiago.bassett@gmail.com>


line='AV - Alert - "1545416096" --> RID: "18130"; RL: "5"; RG: "windows,win_authentication_failed,"; RC: "Logon Failure - Unknown user or bad password."; USER: "(no user)"; SRCIP: "192.168.6.8"; HOSTNAME: "(ECorpExchange1) 10.10.0.154->WinEvtLog"; LOCATION: "(ECorpExchange1) 10.101.0.154->WinEvtLog"; EVENT: "[INIT]2018 Dec 21 13:14:54 WinEvtLog: Security: AUDIT_FAILURE(4625): Microsoft-Windows-Security-Auditing: (no user): no domain: ECorpExchange1.ECorp.local: An account failed to log on. Subject:  Security ID:  S-1-0-0  Account Name:  -  Account Domain:  -  Logon ID:  0x0  Logon Type:   3  Account For Which Logon Failed:  Security ID:  S-1-0-0  Account Name:  ADMINISTRATOR  Account Domain:  ECorp  Failure Information:  Failure Reason:  %%2313  Status:   0xc000006d  Sub Status:  0xc000006a  Process Information:  Caller Process ID: 0x0  Caller Process Name: -  Network Information:  Workstation Name: EcorpDesk9  Source Network Address: 192.168.6.8  Source Port:  64260  Detailed Authentication Information:  Logon Process:  NtLmSsp   Authentication Package: NTLM  Transited Services: -  Package Name (NTLM only): -  Key Length:  0  This event is generated when a logon request fails. It is generated on the computer where access was attempted.  [END]";'

successline='AV - Alert - "1556769602" --> RID: "700003"; RL: "5"; RG: "windows,"; RC: "Windows Network Logon"; USER: "Tyrell"; SRCIP: "192.168.6.8"; HOSTNAME: "(ECorpExchange1) 10.10.0.154->WinEvtLog"; LOCATION: "(ECorpExchange1) 10.10.0.154->WinEvtLog"; EVENT: "[INIT]2019 May 02 00:00:01 WinEvtLog: Security: AUDIT_SUCCESS(4624): Microsoft-Windows-Security-Auditing: Tyrell: Ecorp: ECorpExchange1.Ecorp.local: An account was successfully logged on. Subject:  Security ID:  S-1-0-0  Account Name:  -  Account Domain:  -  Logon ID:  0x0  Logon Type:   3  New Logon:  Security ID:  S-1-5-21-3730905282-1712850778-2088352679-22296  Account Name:  Tyrell  Account Domain:  Ecorp  Logon ID:  0x5f1ee0135  Logon GUID:  {00000000-0000-0000-0000-000000000000}  Process Information:  Process ID:  0x0  Process Name:  -  Network Information:  Workstation Name: -  Source Network Address: 192.168.6.8  Source Port:  49529  Detailed Authentication Information:  Logon Process:  NtLmSsp   Authentication Package: NTLM  Transited Services: -  Package Name (NTLM only): NTLM V2  Key Length:  128  This event is generated when a logon session is created. It is generated on the computer that was accessed. [END]";'


function randomname {
r=$(($RANDOM%4))
if [ $r -eq 0 ]
then
    username='MrRobot'
elif [ $r -eq 1 ]
then
    username='Elliot'
elif [ $r -eq 2 ]
then
    username='Angela'
else
    username='Tyrell'
fi
echo "$username"
}






  for ((i = 0; i <= 79 ; i++ ))
    do
      username=$(randomname)
      date=`date "+%s"`
      newline=`echo $line | sed -r "s/[0-9]{10}/$date/"`
      newline=`echo $newline | sed -r "s/Account Name: ADMINISTRATOR/Account Name: $username/"`
      echo $newline >> /var/ossec/logs/alerts/alerts.log
      let "sleeptime = $RANDOM % 3"
      sleep $sleeptime
    done
authline=`echo $successline | sed -r "s/[0-9]{10}/$date/"` 
echo $authline >> /var/ossec/logs/alerts/alerts.log

