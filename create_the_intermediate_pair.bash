#!/bin/bash
SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${SCRIPT_PATH}" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
  [[ ${SCRIPT_PATH} != /* ]] && SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
done
SCRIPT_PATH="$(readlink -f "${SCRIPT_PATH}")"
SCRIPT_DIR="$(cd -P "$(dirname -- "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
INTERMEDIATE_DIR="${SCRIPT_DIR}/ca/ca-etcd"
mkdir ${INTERMEDIATE_DIR}
mkdir ${INTERMEDIATE_DIR}/certs ${INTERMEDIATE_DIR}/crl ${INTERMEDIATE_DIR}/csr ${INTERMEDIATE_DIR}/newcerts ${INTERMEDIATE_DIR}/private
chmod 700 ${INTERMEDIATE_DIR}/private
touch ${INTERMEDIATE_DIR}/index.txt
echo 1000 > ${INTERMEDIATE_DIR}/serial
echo 1000 > ${INTERMEDIATE_DIR}/crlnumber
cat << EOF > ${INTERMEDIATE_DIR}/openssl.cnf
# OpenSSL ca-etcd CA configuration file.
# Copy to ${INTERMEDIATE_DIR}/openssl.cnf.

[ ca ]
# man ca
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ${INTERMEDIATE_DIR}
certs             = ${INTERMEDIATE_DIR}/certs
crl_dir           = ${INTERMEDIATE_DIR}/crl
new_certs_dir     = ${INTERMEDIATE_DIR}/newcerts
database          = ${INTERMEDIATE_DIR}/index.txt
serial            = ${INTERMEDIATE_DIR}/serial
RANDFILE          = ${INTERMEDIATE_DIR}/private/.rand

# The root key and root certificate.
private_key       = ${INTERMEDIATE_DIR}/private/ca-etcd-key.pem
certificate       = ${INTERMEDIATE_DIR}/certs/ca-etcd-cert.pem

# For certificate revocation lists.
crlnumber         = ${INTERMEDIATE_DIR}/crlnumber
crl               = ${INTERMEDIATE_DIR}/crl/ca-etcd.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

copy_extensions   = copy

[ policy_strict ]
# The root CA should only sign ca-etcd certificates that match.
# See the POLICY FORMAT section of man ca.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the ca-etcd CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the ca man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the req tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
prompt              = no

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# Optionally, specify some defaults.
commonName              = Dalibo CA
countryName              = FR
stateOrProvinceName     = France
localityName            = Paris
0.organizationName      = Dalibo
organizationalUnitName  = Dalibo CA
emailAddress            = dalibo@dalibo.com

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ ca_etcd ]
# Extensions for a typical ca-etcd CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
authorityInfoAccess = OCSP;URI:http://ocsp2.example.com
#subjectAltName = @alt_names

#[ alt_names ]
#DNS.1 = example.com
#DNS.2 = www.example.com
#DNS.3 = m.example.com

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (man ocsp).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
openssl req -newkey rsa:2048 -nodes \
        -keyout  ${INTERMEDIATE_DIR}/private/ca-etcd-key.pem \
        -config ${INTERMEDIATE_DIR}/openssl.cnf \
        -out ${INTERMEDIATE_DIR}/csr/ca-etcd-cert.csr
openssl x509 -req \
        -extfile ${INTERMEDIATE_DIR}/openssl.cnf \
        -extensions ca_etcd \
        -in ${INTERMEDIATE_DIR}/csr/ca-etcd-cert.csr \
        -CA ${SCRIPT_DIR}/ca/certs/root.cert.pem \
        -CAkey ${SCRIPT_DIR}/ca/private/root.key.pem \
        -CAcreateserial \
        -out ${INTERMEDIATE_DIR}/certs/ca-etcd-cert.pem \
        -days 3650 -sha256
cat ${INTERMEDIATE_DIR}/certs/ca-etcd-cert.pem ${INTERMEDIATE_DIR}/../certs/root.cert.pem > ${INTERMEDIATE_DIR}/certs/ca-etcd-chain-cert.pem
openssl verify -CAfile ${INTERMEDIATE_DIR}/../certs/root.cert.pem ${INTERMEDIATE_DIR}/certs/ca-etcd-cert.pem
