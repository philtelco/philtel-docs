# Franklin T9 Firmware Downgrade

Earlier versions of the Franklin T9 firmware had some developer/engineer menus that allowed you to change the channels the device used as well as look at and poke some interesting things. I probably don't need these features, but I wanted to enable them anyway in order to have the most capable device available to me.

My Franklin T9 was originally running firmware 2602 when I received it, but firmware 1311 is recommended. Here we will document the downgrade process and provide information for accessing the hidden/secret configuration screens.

Again, the below content is sourced heavily from the following two web pages:
* [Rooting and Unlocking the T-Mobile T9 (Franklin Wireless R717)](https://snt.sh/2020/09/rooting-the-t-mobile-t9-franklin-wireless-r717/) 
* [Rooting the T-Mobile T9 (Franklin Wireless R717) – Again!](https://snt.sh/2021/09/rooting-the-t-mobile-t9-franklin-wireless-r717-again/)

## Performing the Downgrade

Before we downgrade, the Franklin T9 must have a working SIM (with data), a fully charged battery, and be on firmware 2602 for this to work.

Now, download the following config file: https://snt.sh/uploads/t9/configs/downgrade_2602_to_1311_config.bin

Go to the *Backup and Restore* page on the Franklin unit at http://192.168.0.1/settings/device-backup_and_restore.html. Once here, select the config file you just downloaded and click *Restore Now*. 

The file will begin to upload and eventually the device will reboot on its own. At this point, leave the device alone for about 15 minutes so the device can pull the proper (older) firmware. You will know the device is updating because the LCD screen will show "Updating." 

After updating, the device should reboot to factory defaults with the desired firmware. You can try logging in with either the password `admin` or `password`. Note that OTAs should be disabled now as well, meaning the modem will no longer try to update itself to the latest firmware version.

## Enable SSH Access

Now we can enable SSH access on the device by modifying the config file.

Go to the *Backup and Restore* page on the Franklin unit at http://192.168.0.1/settings/device-backup_and_restore.html and backup the config.

Now, on a Linux machine running Python 3 and OpenSSL 1.1.0 or newer, run [this script](https://gist.github.com/riptidewave93/ad135229b0f0939da7bd223d7f723528) which I'm also pasting below for safe keeping:

```
#!/usr/bin/env python3

# Created by Chris Blake (chrisrblake93@gmail.com)
# Please do not redistribute!

import argparse
import hashlib
import os
import re
import shutil
import sys
import tarfile
import tempfile

cryptkey = 'frkenc##KEY@R717'

def main(file):
    # Can we access it?
    if not os.path.isfile(file):
        print(f"Unable to process {file}, please verify the file path.")
        sys.exit(1)
    elif not os.access(file, os.R_OK):
        print(f"Unable to read from {file}, please check file permissions.")
        sys.exit(1)

    # Make sure we know where to save our new generated config
    cfgpath, _ = os.path.split(os.path.abspath(file))

    # Create a temp directory to work in
    tmpdir = tempfile.TemporaryDirectory()

    # Copy the config file
    shutil.copyfile(file, f"{tmpdir.name}/hotspot_cfg.bin")

    # Decrypt
    os.system(f"openssl enc -aes-128-cbc -d -md md5 -in {tmpdir.name}/hotspot_cfg.bin -out {tmpdir.name}/hotspot_cfg_extract.tar -k {cryptkey} 2> /dev/null")
    os.remove(f"{tmpdir.name}/hotspot_cfg.bin")

    # Extract Layer 1
    os.mkdir(f"{tmpdir.name}/hotspot_cfg")
    hscfg1 = tarfile.open(f"{tmpdir.name}/hotspot_cfg_extract.tar")
    hscfg1.extractall(f"{tmpdir.name}/hotspot_cfg/")
    hscfg1.close()
    os.remove(f"{tmpdir.name}/hotspot_cfg_extract.tar")

    # Extract Layer 2
    os.mkdir(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg")
    hscfg2 = tarfile.open(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg.tar")
    hscfg2.extractall(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg/")
    hscfg2.close()
    os.remove(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg.tar")

    # Enable SSH
    with open(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg/data/configs/mobileap_cfg.xml", "r") as sources:
        lines = sources.readlines()
    with open(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg/data/configs/mobileap_cfg.xml", "w") as sources:
        for line in lines:
            sources.write(re.sub('<Ssh>0</Ssh>', '<Ssh>1</Ssh>', line))

    # Package layer 2
    hscfg2 = tarfile.open(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg.tar", "w:gz")
    hscfg2.add(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg/data",arcname="data")
    hscfg2.close()
    shutil.rmtree(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg/")

    # Update MD5sum
    newhash = hashlib.md5(open(f"{tmpdir.name}/hotspot_cfg/hotspot_cfg.tar", "rb").read()).hexdigest()
    with open(f"{tmpdir.name}/hotspot_cfg/hashfile", 'w') as f:
        f.write(f"hotspot_cfg.tar={newhash}")

    # Package layer 1
    hscfg1 = tarfile.open(f"{tmpdir.name}/hotspot_cfg.tar", "w:gz")
    for file in ["hashfile", "model", "hotspot_cfg.tar"]:
        hscfg1.add(f"{tmpdir.name}/hotspot_cfg/{file}",arcname=f"{file}")
    hscfg1.close()
    shutil.rmtree(f"{tmpdir.name}/hotspot_cfg/")

    # Encrypt
    os.system(f"openssl enc -aes-128-cbc -md md5 -in {tmpdir.name}/hotspot_cfg.tar -out {tmpdir.name}/hotspot_cfg.bin -k {cryptkey} 2> /dev/null")
    os.remove(f"{tmpdir.name}/hotspot_cfg.tar")

    # Copy it back to our main dir
    shutil.copyfile(f"{tmpdir.name}/hotspot_cfg.bin", f"{cfgpath}/hotspot_cfg_ssh_enabled.bin")

    tmpdir.cleanup() # removes the temp dir

    print("Complete, upload hotspot_cfg_ssh_enabled.bin to enable SSH access. Enjoy!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Modify a T-Mobile T9 config backup to enable SSH.')
    parser.add_argument('file', help='The T9 config file to enable SSH on')
    args = parser.parse_args()

    main(args.file)
```

If the above script is saved as `enablessh.py` you could run it via:

```
$ python3 enablessh.py myconfig.bin
```

This will output a modified file `hotspot_cfg_ssh_enabled.bin` that can then be restored on the Franklin T9 via the same *Backup and Restore* page, http://192.168.0.1/settings/device-backup_and_restore.html

The root password is `frk9x07`.

## Hidden Web Pages

Now that we are on the correct firmware, we can access hidden web pages. The below is taken directly from the [Rooting and Unlocking the T-Mobile T9 (Franklin Wireless R717)](https://snt.sh/2020/09/rooting-the-t-mobile-t9-franklin-wireless-r717/) source.

Hidden Web Pages

During my digging around the device I found a handful of hidden pages, which were secured by plain text passwords that were statically built into binaries. Below you can find the pages I found, as well as where I found the passwords for said pages.

* Hidden Configuration Pages
  - http://192.168.0.1/hidden/
  - http://192.168.0.1/webpst/
    * Password: frk@r717
	* Password was extracted from /var/volatile/www/htdocs/cgi-bin/login.cgi
* IT Admin Page
  - http://192.168.0.1/itadmin/
    * Password: t9_it_@dmin
    *Password was extracted from /var/volatile/www/htdocs/cgi-bin/logi
* Hidden Engineering Page
  - http://192.168.0.1/engineering/franklin/
    * Username: r717
    * Password: frkengr717
    * User and Password were extracted from /etc/pwlighttpd
    * Note: On firmwares newer than 891, you need to first run the following as root before you can access the engineering pages, `/usr/bin/copy_htdocs.sh eng`