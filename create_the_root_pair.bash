#!/bin/bash
SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${SCRIPT_PATH}" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
  [[ ${SCRIPT_PATH} != /* ]] && SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
done
SCRIPT_PATH="$(readlink -f "${SCRIPT_PATH}")"
SCRIPT_DIR="$(cd -P "$(dirname -- "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
mkdir ${SCRIPT_DIR}/ca
mkdir ${SCRIPT_DIR}/ca/certs ${SCRIPT_DIR}/ca/crl ${SCRIPT_DIR}/ca/newcerts ${SCRIPT_DIR}/ca/private
chmod 700 ${SCRIPT_DIR}/ca/private
touch ${SCRIPT_DIR}/ca/index.txt
echo 1000 > ${SCRIPT_DIR}/ca/serial
cat << EOF > ${SCRIPT_DIR}/ca/openssl.cnf
# OpenSSL root CA configuration file.
# Copy to /root/ca/openssl.cnf.

[ ca ]
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ${SCRIPT_DIR}/ca
certs             = ${SCRIPT_DIR}/ca/certs
crl_dir           = ${SCRIPT_DIR}/ca/crl
new_certs_dir     = ${SCRIPT_DIR}/ca/newcerts
database          = ${SCRIPT_DIR}/ca/index.txt
serial            = ${SCRIPT_DIR}/ca/serial
RANDFILE          = ${SCRIPT_DIR}/ca/private/.rand

# The root key and root certificate.
private_key       = ${SCRIPT_DIR}/ca/private/root.key.pem
certificate       = ${SCRIPT_DIR}/ca/certs/root.cert.pem

# For certificate revocation lists.
crlnumber         = ${SCRIPT_DIR}/ca/crlnumber
crl               = ${SCRIPT_DIR}/ca/crl/root.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = match
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
prompt              = no

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
commonName                      = Dalibo CA
countryName                     = FR
stateOrProvinceName             = France
localityName                    = Paris
organizationalUnitName          = Dalibo CA
organizationName                = Dalibo
emailAddress                    = dalibo@dalibo.com

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ ca_etcd ]
# Extensions for a typical intermediate CA (man x509v3_config).
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

openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout ${SCRIPT_DIR}/ca/private/root.key.pem \
        -days 3650 \
        -config ${SCRIPT_DIR}/ca/openssl.cnf \
        -extensions v3_ca \
        -out ${SCRIPT_DIR}/ca/certs/root.cert.pem
chmod 400 ${SCRIPT_DIR}/ca/certs/root.cert.pem
