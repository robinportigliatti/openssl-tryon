#!/bin/bash
SCRIPT_PATH="${BASH_SOURCE}"
while [ -L "${SCRIPT_PATH}" ]; do
  SCRIPT_DIR="$(cd -P "$(dirname "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
  SCRIPT_PATH="$(readlink "${SCRIPT_PATH}")"
  [[ ${SCRIPT_PATH} != /* ]] && SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_PATH}"
done
SCRIPT_PATH="$(readlink -f "${SCRIPT_PATH}")"
SCRIPT_DIR="$(cd -P "$(dirname -- "${SCRIPT_PATH}")" >/dev/null 2>&1 && pwd)"
NODE="${1}"
IP1="${2}"
IP2="${3}"
SAN="DNS:${NODE},DNS:${NODE}.local,IP:127.0.0.1,IP:${IP1},IP:${IP2}"
cat<< EOF > ${SCRIPT_DIR}/ca/ca-etcd/${NODE}.conf
[ req ] 
default_bits            = 2048
default_md              = sha256
prompt = no 
distinguished_name = req_distinguished_name
[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
C                       = FR
ST                      = FR
L                       = Paris
O                       = Dalibo
OU                      = Dalibo CA
CN                      = ${NODE}
[ peer ]
subjectKeyIdentifier    = hash
basicConstraints        = critical,CA:FALSE
extendedKeyUsage        = serverAuth,clientAuth
keyUsage                = critical,keyEncipherment,dataEncipherment
authorityKeyIdentifier  = keyid,issuer:always
subjectAltName = DNS:localhost,IP:127.0.0.1,DNS:${NODE},DNS:${NODE}.local,IP:${IP1},IP:${IP2}
EOF
openssl req -newkey rsa:2048 -nodes \
             -keyout ${SCRIPT_DIR}/ca/ca-etcd/private/${NODE}-key.pem \
             -config ${SCRIPT_DIR}/ca/ca-etcd/${NODE}.conf \
             -out ${SCRIPT_DIR}/ca/ca-etcd/csr/${NODE}.csr
openssl x509 -req \
             -extfile ${SCRIPT_DIR}/ca/ca-etcd/${NODE}.conf \
             -extensions peer \
             -in ${SCRIPT_DIR}/ca/ca-etcd/csr/${NODE}.csr \
             -CA ${SCRIPT_DIR}/ca/ca-etcd/certs/ca-etcd-cert.pem \
             -CAkey ${SCRIPT_DIR}/ca/ca-etcd/private/ca-etcd-key.pem \
             -CAcreateserial \
             -out ${SCRIPT_DIR}/ca/ca-etcd/certs/${NODE}.pem \
             -days 3650 -sha256