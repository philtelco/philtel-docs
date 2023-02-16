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

After the dialog closes, press the *Save & Apply* button and after a few seconds of waiting the router should connect to the network and display connection status in the *Associated Stations* section of the page.

![apply changes](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-06.jpg)

## Add a Second Network

If you want to have multiple WWAN networks defined, proceed to *Network* --> *Wireless*. 

![Go to wireless settings](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-01.jpg)

Scroll down to any currently enabled WWAN network and press the *Disable* button next to it.

![Disable](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-07.jpg)

Now press the *Scan* button next to the entry for `radio0`.

![Scan](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-07.5.jpg)

Find the new wireless network you want to connect to and press the *Join Network* button to the right of it.

![Join Network](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-08.jpg)

In the resulting dialog, enter a name in the `Name of the new network` field and enter the network password in the `WPA passphrase` field before pressing the *Submit* button.

![New Network](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-09.jpg)

In the next dialog, press the *Save* button.

![New Network](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-10.jpg)

Back on the *Wireless Overview* page, press the *Save & Apply* button.

![Save and Apply](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-11.jpg)

The new network should connect!

If you already have OpenVPN running during this step, you will want to either power cycle the router, or by stopping and starting the OpenVPN connection. To do the latter, navigate to *VPN* --> *OpenVPN*.

![OpenVPN](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-12.jpg)

On the OpenVPN page, press the *stop* button in the row for our OpenVPN instance. After it has stopped, press the *start* button that will replace it in the same row.

![stop and start](1-gl-ar300m16-routed-client/1-gl-ar300m16-routed-client-12.jpg)