#!/bin/bash

openssl genrsa -out $HCP_RUN_ENROLL_SIGNER/key.priv
openssl rsa -pubout -in $HCP_RUN_ENROLL_SIGNER/key.priv -out $HCP_RUN_ENROLL_SIGNER/key.pem
cp $HCP_RUN_ENROLL_SIGNER/key.pem $HCP_RUN_CLIENT_VERIFIER/
chown db_user:db_user /creds/asset-signer/key.*

openssl genrsa -out $HCP_RUN_ENROLL_GENCERT/CA.priv
openssl req -new -key $HCP_RUN_ENROLL_GENCERT/CA.priv -subj /CN=localhost -x509 -out $HCP_RUN_ENROLL_GENCERT/CA.cert
chown db_user:db_user /creds/gencert-CA/CA.*
