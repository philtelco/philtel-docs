# Grandstream HT801 Firmware Downgrade

The latest version of the HT801 firmware contains bugs that make the ATAs unreliable. We will be downgrading the firmare to a stable version.

## Firmware Downgrade

In your web browser, you will  want to visit the IP address of the ATA. If you have already configured your router, you have assigned the ATA an IP address of `192.168.1.2` so you can visit <http://192.168.1.2> through your browser.

You will be presented with a login screen. Enter `admin` into the *Username* field and your password into the *Password* field and then press the *Login* button.

![login](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-01.jpg)

On the *STATUS* page, use the top navigation to navigate to *ADVANCED SETTINGS*.

![advanced settings](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-02.jpg)

Scroll to the bottom of the *ADVANCED SETTINGS* page and press the button for *Upload from local directory* next to *Upload Firmware*.

![upload from local directory](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-03.jpg)

Download the following file to your computer and unzip it, <https://firmware.grandstream.com/Release_HT802_1.0.41.5.zip>.

Press the *Browse* button.

![Browse](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-04.jpg)

Select the file `ht801fw.bin` in the `Release_HT801_1.0.41.5` directory you previously extracted and press the *Open* button.

![open](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-05.jpg)

Press the *Upload Firmware* button. It may not seem like anything is happening for about a minute, but DO NOT turn off or unplug the ATA.


![upload](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-06.jpg)

After around a minute you will be presented with a page notifying you that the firmware flashing is in progress. While the firmware is being flashed, you will see two blue lights blinking on the top of the ATA.

![upload](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-07.jpg)

After a few minutes you should be able to log back into the ATA at <http://192.168.1.2>  and see the proper firmware version on the *STATUS* page.

![status](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-12.jpg)

## Troubleshooting

If the firmware on the device is too old, you may have to update automatically upgrade before downgrading.

After logging in to the ATA, , use the top navigation to navigate to *ADVANCED SETTINGS*.

![advanced settings](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-02.jpg)

Scroll down the the *Firmware Upgrade and Provisioning* section and select `HTTP` and enter `firmware.grandstream.com` in both the * Firmware Server Path* and *Config Server Path* fields.

![firmware](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-08.jpg)

Then scroll down to the bottom of the page and press the *Apply* button.

![apply](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-09.jpg)

On the next page, use the top navigation to navigate to *ADVANCED SETTINGS*.

![advanced settings](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-10.jpg)

Scroll down and press the *Reboot* button. 

![reboot](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-11.jpg)

The device will now reboot and update the firmware. While the device is updating, you will see two blinking blue lights on the top of the ATA. DO NOT unplug or power off the device at this time. After the lights stop blinking.

Login again at <http://192.1681.2.> and use the top navigation to navigate to *ADVANCED SETTINGS*.

![advanced settings](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-02.jpg)

Scroll down to *Always Skip the Firmware Check* and select the option for this.

![skip firmware](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-13.jpg)

Then scroll down to the bottom of the page and press the *Apply* button.

![apply](1-ht801-firmware-downgrade\1-ht801-firmware-downgrade-09.jpg)

Now you can perform the manual firmware downgrade outlined above.