# freenas-alerta
Use FreeNAS middleware client to push alerts from Freenas to Alerta


TrueNAS/FreeNAS does not have a plugin for Alerta, nor does it have a facility to use shell scripts or http/json for alerts.

This simple script takes the alerts from the FreeNAS database using the included middleware client midclt and pushes them to the Alerta endpoint using curl, making some assumptions along the way.
