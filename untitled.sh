# NIFI CERTIFICATES

cd tmp

# Gen the root CA private key
openssl genrsa -aes128 -out rootCA.key 4096
openssl req -x509 -new -key ./rootCA.key -days 1095 -out rootCA.pem
openssl x509 -outform der -in ./rootCA.pem -out ./rootCA.der
keytool -import -keystore truststore.jks -file ./rootCA.der -alias rootCA

# Generate nifi key pair
keytool -keystore keystore.jks -genkey -alias nifi-web -keyalg RSA -keysize 2048

# Generate nifi CSR
keytool -keystore keystore.jks -certreq -alias nifi-web -ext san=dns:nifi-1.nifi.local,dns:nifi-1 -file ./nifi-web.csr

# Sign it
openssl x509 -sha256 -req -in nifi-web.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out nifi-web.crt -days 1095

# Trust RootCA
keytool -import -keystore keystore.jks -file rootCA.pem

# Add Trusted Cert
keytool -import -trustcacerts -alias nifi-web -file nifi-web.crt -keystore keystore.jks

keytool -export -keystore keystore.jks -alias nifi-web -file nifi-web-trust.cer
scp nifi-web-trust.cer ranger-1:/etc/security/ranger-certs/

mv *.jks *.key *.cer /etc/security/nifi-certs/
cd ..
rm -r tmp

chown nifi:nifi -R /etc/security/nifi-certs/
chmod 400 -R /etc/security/nifi-certs/


# RANGER CERTIFICATES
mkdir tmp
cd tmp

# Gen root CA key and add it to truststore
openssl genrsa -aes128 -out rootCA.key 4096
openssl req -x509 -new -key ./rootCA.key -days 1095 -out rootCA.pem
openssl x509 -outform der -in ./rootCA.pem -out ./rootCA.der
keytool -import -keystore truststore.jks -file ./rootCA.der -alias rootCA

keytool -keystore keystore.jks -genkey -alias ranger-web -keyalg RSA -keysize 2048
keytool -keystore keystore.jks -certreq -alias ranger-web -ext san=dns:ranger-1.nifi.local,dns:ranger-1 -file ./ranger-web.csr
openssl x509 -sha256 -req -in ranger-web.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ranger-web.crt -days 1095
keytool -import -keystore keystore.jks -file rootCA.pem
keytool -import -trustcacerts -alias ranger-web -file ranger-web.crt -keystore keystore.jks

keytool -export -keystore keystore.jks -alias ranger-web -file ranger-web-trust.cer
scp ranger-web-trust.cer nifi-1:/etc/security/nifi-certs/

mv *.jks *.key *.cer /etc/security/ranger-certs/
cd ..
rm -r tmp

chown ranger:ranger -R /etc/security/ranger-certs
chmod 400 /etc/security/ranger-certs
