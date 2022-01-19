ENV HCP_SERVICES="enroll attest swtpm"
ENV HCP_ENROLLSVC_STATE_PREFIX=/state/enrollsvc
ENV HCP_ENROLLSVC_SIGNER=/creds/asset-signer
ENV HCP_ENROLLSVC_GENCERT=/creds/gencert-CA
ENV HCP_ENROLLSVC_REALM=REALM.EXAMPLE.XYZ
ENV HCP_ATTESTSVC_STATE_PREFIX=/state/attestsvc
ENV HCP_ATTESTSVC_REMOTE_REPO=git://localhost/enrolldb
ENV HCP_ATTESTSVC_UPDATE_TIMER=10
ENV HCP_SWTPMSVC_STATE_PREFIX=/state/swtpmsvc
ENV HCP_SWTPMSVC_ENROLL_HOSTNAME=host.realm.example.xyz
ENV HCP_SWTPMSVC_ENROLL_API=http://localhost:5000
ENV HCP_CLIENT_VERIFIER=/creds/asset-verifier
ENV HCP_CLIENT_ATTEST_URL=http://localhost:8080
ENV HCP_CLIENT_TPM2TOOLS_TCTI=swtpm:path=/tpmsocket
ENV HCP_SOCKET=/tpmsocket

RUN mkdir -p $HCP_ENROLLSVC_STATE_PREFIX
RUN mkdir -p $HCP_ATTESTSVC_STATE_PREFIX
RUN mkdir -p $HCP_SWTPMSVC_STATE_PREFIX

RUN mkdir -p $HCP_ENROLLSVC_SIGNER
RUN mkdir -p $HCP_ENROLLSVC_GENCERT
RUN mkdir -p $HCP_CLIENT_VERIFIER

RUN mkdir -p /hcp/caboodle
COPY caboodle/*.sh /hcp/caboodle/
RUN chmod 755 /hcp/caboodle/*.sh

RUN /hcp/caboodle/regen-creds.sh
