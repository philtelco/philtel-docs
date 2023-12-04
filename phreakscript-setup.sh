#!/bin/bash
# A wrapper for phreakscript (which is itself a wrapper

# This assumes you have your reservations in the online portal and have your server info set up, but no software installed on said server
# Use this guide for reference, https://portal.phreaknet.org/quickstart

# Your Interlinked.us API Key
# Get it here, https://interlinked.us/account/integration
API_KEY=YOURKEYHERE
# Bell System-style acronym for Common Language Location Identifier. The official ID of your PBX
# It should match what is here, https://portal.phreaknet.org/switches
CLLI=HSTNTXMOCG0
# Direct Inward System Access, the direct number into your switch typically your thousands-block followed by 111, like 5552111
DISA=5552111
#IAX Password, we assume you left the username as the default "phreaknet"
# It should match what is here, https://portal.phreaknet.org/users
IAX2PASSWORD=YOURPASSWORDHERE

NPA=${DISA:0:3}
NPAX=${DISA:0:4}
X=${DISA:3:1}

cd /usr/local/src; wget https://docs.phreaknet.org/script/phreaknet.sh; chmod +x phreaknet.sh; ./phreaknet.sh make
phreaknet update; phreaknet install; phreaknet pulsar; phreaknet sounds --boilerplate
phreaknet config --api-key=$API_KEY --clli=$CLLI --disa=$DISA
phreaknet keygen --rotate 
sed -i "s/5550/$NPAX/g" /etc/asterisk/dialplan/phreaknet.conf
sed -i "s/5551/$NPAX/g" /etc/asterisk/dialplan/phreaknet.conf
sed -i "s/5552/$NPAX/g" /etc/asterisk/dialplan/phreaknet.conf
sed -i "s/5559/$NPAX/g" /etc/asterisk/dialplan/phreaknet.conf
sed -i "s/\[19]/$X/g" /etc/asterisk/dialplan/phreaknet.conf
sed -i "s/555/$NPA/g" /etc/asterisk/dialplan/phreaknet.conf
sed -i "s/5551111/$DISA/g" /etc/asterisk/verify.conf
sed -i "s/;bindport/bindport/g" /etc/asterisk/iax.conf
sed -i "s/somethingyoushouldchange/$IAX2PASSWORD/g" /etc/asterisk/iax.conf
sed -i "s/5551111/$DISA/g" /etc/asterisk/verify.conf
systemctl restart asterisk
