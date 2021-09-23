# freenas-alerta
Use FreeNAS middleware client to push alerts from Freenas to Alerta


TrueNAS/FreeNAS does not have a plugin for Alerta, nor does it have a facility to use shell scripts or http/json for alerts.

This simple script takes the alerts from the FreeNAS database using the included middleware client midclt and pushes them to the Alerta endpoint using curl, making some assumptions along the way.

Currently the script just invokes midclt to get the info about ALL alerts without keeping track of their status and pushes them into Alerta. Alerta can take care of duplicates so this is not a big issue. 

Uses midclt, jq and wget which are all included on a TrueNAS install.


Put freenas-alerta.sh and .secrets in <PATH TO SOME LOCATION>
Add FreeNAS/TrueNAS Cron task as:

```cd  /\<PATH TO SOME LOCATION\>/bin/cron && /bin/bash ./freenas-alerta.sh```

 
When executed the script will always push alerts (no state tracking). It will pass the severity level translated from the TrueNAS values to Alerta values. You can change these in the script to fit your environment. When an alert is dismissed on the TrueNAS side it will be set to closed on Alerta and cleared (i.e turn GREEN). The dismissed alerts will keep being pushed to alerta due to not keeping track of state but it's not a huge problem on the Alerta side since the row will stay green. (By default Alerta only displays Open and Ack status alerts)
