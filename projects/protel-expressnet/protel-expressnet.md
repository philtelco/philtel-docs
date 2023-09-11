# Protel ExpressNet

## Sangoma Wanpipe DAHDI

To bridge between asterisk and the TDM, we need to rely on a T1 card and DAHDI software. Having a Sangoma card means relying on Wanpipe, which is closed source. At the time of writing it isn't easy to get working on Debian 11 and may not work at all on Debian 12 right now.

With a Debian 11 system we can follow osmocom's guide to install DAHDI and Wanpipe, https://osmocom.org/projects/retronetworking/wiki/Sangoma_Wanpipe_DAHDI

For reference the Wanpipe driver is found here, https://wiki.freepbx.org/display/DAS/Telephony+Card+Driver+Download

## TDM

We want to test a channel bank since ATAs don't seem to offer reliable connection between the modem and phone. Luckily I have an Adit 600 with an FXS card that supports eight lines.

Config information is available in the setup doc, https://static.philtel.org/adit-600/Adit 600 setup.pdf

## PCI Cards

In the future we might need to use old Digium PCI cards instead of Sangoma. 

There is an external board to use PCI cards on a PCIE system:

* External PCI Riser Enclosure - https://www.thingiverse.com/thing:4528014