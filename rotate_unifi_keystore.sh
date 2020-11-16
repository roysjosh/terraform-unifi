#!/bin/sh

CERT=$RENEWED_LINEAGE/fullchain.pem
PRIV=$RENEWED_LINEAGE/privkey.pem
PASS=aircontrolenterprise
P12F=`mktemp`

cd /var/lib/unifi/data
# create p12 from cert/key
openssl pkcs12 -export -in $CERT -inkey $PRIV -out $P12F -passout pass:$PASS -name unifi
# backup existing
cp -a keystore /root/keystore.`date +%s`
# out with the old
keytool -delete -alias unifi -keystore keystore -deststorepass $PASS
# in with the new
keytool -importkeystore -srcstoretype pkcs12 -srckeystore $P12F -srcstorepass $PASS -destkeystore keystore -deststorepass $PASS -destkeypass $PASS -alias unifi -trustcacerts

rm -f $P12F

# deploy changes
systemctl restart unifi
