# https://reactpaths.com/how-to-get-https-working-in-localhost-development-environment-f17de34af046
echo "creating a private key" 
openssl genrsa -des3 -out rootSSL.key 2048
echo "Create certificate rootSSL.pem file using private key roorSSL.key"
openssl req -x509 -new -nodes -key rootSSL.key -sha256 -days 1024 -out rootSSL.pem
echo "Trusting the Root Certificate by putting it in the machine or server "
sudo mkdir /usr/local/share/ca-certificates/extra
sudo cp rootSSL.pem /usr/local/share/ca-certificates/extra/rootSSL.crt
sudo update-ca-certificates
echo "issuing a certificate for a local domain "
echo "generating a private  key for the local domain "
openssl req \
 -new -sha256 -nodes \
 -out demo.local.csr \
 -newkey rsa:2048 -keyout demo.local.key \
 -subj "/C=IN/ST=State/L=City/O=Organization/OU=OrganizationUnit/CN=demo/emailAddress=mazemb_eddy@yahoo.fr"
echo "generating the certificate for the local domain with reference to the root SSL"
 openssl x509 \
 -req \
 -in demo.local.csr \
 -CA rootSSL.pem -CAkey rootSSL.key -CAcreateserial \
 -out demo.local.crt \
 -days 500 \
 -sha256 \
 -extfile <(echo " \
    authorityKeyIdentifier=keyid,issuer\n \
    basicConstraints=CA:FALSE\n \
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\n \
    subjectAltName=DNS:demo.local \
   ")
