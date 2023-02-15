# Configuring the GL-AR300M16 as a Routed Client

In some cases, the WAN connection for the router may not be provided via ethernet cable and a WWAN connection will need to be performed so the router can get Internet access via an existing wireless network at the installation site.

## Configure the Network

Login to the router at <https://192.168.1.1/> and proceed to *Network* --> *Wireless*. 

![Go to wireless settings](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-01.jpg)

Here you will see an entry for `radio0,` now press the *Scan* button to get a list of available wireless networks. 

![scan for networks](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-02.jpg)

Find the one you would like to use and press the *Join Network* button next to it.

![select a network](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-03.jpg)

On the *Joining Network* dialog, check the box for *Replace wireless configuration*, ensure the network name is `wwan` and enter the passphrase to access the network. In *Create / Assign firewall-zone*, be sure that the `wan` zone is selected before pressing the *Submit* button. 

![join the network network](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-04.jpg)

On the following dialog the defaults should be enough to establish connection, so press the *Save* button. In some cases you may need to edit the *Wireless Security* section to ensure the proper encryption is set.  

![save the network](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-05.jpg)

NOTE: If you want to have multiple WAN networks, repeat the above steps but then go to *Interfaces* --> *Add new interface* and in the resulting dialog supply a unique network `Name` and choose your newly created interface under `Device` before pressing the *Create Interface* button. Afterwards, press the *Save & Apply* button. NOTE: You may need to disable/enable the OpenVPN connection or restart the WireGuard interface after this step depending on which VPN solution you are using.

After the dialog closes, press the *Save & Apply* button and after a few seconds of waiting the router should connect to the network and display connection status in the *Associated Stations* section of the page.

![apply changes](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-06.jpg)