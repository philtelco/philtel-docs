sudo -i 
apt update && apt install openssh-server -y && systemctl enable ssh && systemctl start ssh

cd /usr/local/src; wget https://docs.phreaknet.org/script/phreaknet.sh; chmod +x phreaknet.sh; ./phreaknet.sh make
phreaknet update
phreaknet install -d -f
phreaknet pulsar
phreaknet sounds --boilerplate
phreaknet config --api-key=JpA4eNQs5cmG12B8rpHlNmIKen98IxnCUcgU7KZs2TCiu1aH --clli=PHLAPASODS0 --disa=2630111
phreaknet keygen --rotate 
phreaknet wanpipe

cat /etc/modules
dahdi
wanpipe
wanec

wancfg_dahdi
// use fxo options