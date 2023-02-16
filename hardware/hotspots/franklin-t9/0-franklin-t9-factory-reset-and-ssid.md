# Franklin T9 Reset & SSID

Earlier versions of the Franklin T9 firmware had some developer/engineer menus that allowed you to change the channels the device used as well as look at and poke some interesting things. I probably don't need these features, but I wanted to enable them anyway in order to have the most capable device available to me.

## Factory Reset

When we get a Franklin T9, the first thing we should do is factory reset it to default settings. 

While you don't need a battery to run the T9, it does seem like you need it to perform a reset. I recommend  having a battery in the T9, and having the T9 connected to USB power before performing the following steps.

First, turn on the unit by holding the power button for a few seconds until the screen displays "Welcome". Allow it to fully boot up for a minute or two.

Remove the back cover from the T9 and press and hold the reset button near the battery for three seconds. The screen will read "Factory Reset Restarting Now" and the T9 will reboot again.

After it reboots, single-press the power button to get information for the hotspot's SSID and password and connect to the hotspot's WiFi network using this information.

After you connect to the network, open a web browser n your computer and visit `http://192.168.0.1`. Ignore any popups that tell you to "Import SIM".

Press the *Login* button and in the resulting dialog enter `admin` in the *Password* field and then press the *Login* button. NOTE: If this fails, try using `password` as the *Password* as this was an older default password. If neither of these works, try performing the factory reset again.

![login](0-franklin-t9-factory-reset-and-ssid\0-franklin-t9-factory-reset-and-ssid-01.jpg)

You will now be prompted to change the password, so press the *OK* button.

![warning](0-franklin-t9-factory-reset-and-ssid\0-franklin-t9-factory-reset-and-ssid-02.jpg)

You will automatically be routed to the *Web Interface* page. Here, enter the current admin password (likely `admin` or `password` depending on what you just used) into the *Enter Current Password* field and enter a new password into the *Enter New Password* and *Confirm New Password* fields. Finally, press the *Save Changes* button.

![change password](0-franklin-t9-factory-reset-and-ssid\0-franklin-t9-factory-reset-and-ssid-03.jpg)

You will now see a success dialog, press the *OK* button.

![success](0-franklin-t9-factory-reset-and-ssid\0-franklin-t9-factory-reset-and-ssid-04.jpg)

## Change WiFi SSID & Password*

At the Home screen, press the button for *Settings* in the top navigation.

![settings](0-franklin-t9-factory-reset-and-ssid\0-franklin-t9-factory-reset-and-ssid-05.jpg)

You will be taken to the *Wi-Fi Basic Settings* page. Here, fill in a new *Wi-Fi Name* and *Wi-Fi Password*. These values will be used when you connect to the hotspot from your router. When done, press the *Save Changes* button.

![wi-fi basic settings](0-franklin-t9-factory-reset-and-ssid\0-franklin-t9-factory-reset-and-ssid-06.jpg)

The T9 will now apply the changes. After a minute or two the new SSID and password will be usable.