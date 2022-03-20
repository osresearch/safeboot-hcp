# Security note: there are some subtleties about environment values that aren't
# visible here but are worth knowing about. See common.sh for the gritty
# details.

RUN useradd -m -s /bin/bash db_user
RUN useradd -m -s /bin/bash flask_user

RUN mkdir -p /hcp/enrollsvc
COPY enrollsvc/*.sh enrollsvc/*.py /hcp/enrollsvc/
RUN chmod 755 /hcp/enrollsvc/*.sh /hcp/enrollsvc/*.py

# The following puts a sudo configuration into place for flask_user to be able
# to invoke (only) the 4 /hcp/op_<verb>.sh scripts as db_user.

RUN echo "# sudo rules for enrollsvc-mgmt" > /etc/sudoers.d/hcp
RUN echo "Cmnd_Alias HCP = /hcp/enrollsvc/op_add.sh,/hcp/enrollsvc/op_delete.sh,/hcp/enrollsvc/op_find.sh,/hcp/enrollsvc/op_query.sh" >> /etc/sudoers.d/hcp
RUN echo "Defaults !lecture" >> /etc/sudoers.d/hcp
RUN echo "Defaults !authenticate" >> /etc/sudoers.d/hcp
RUN echo "flask_user ALL = (db_user) HCP" >> /etc/sudoers.d/hcp

# We have constraints to support older Debian versions whose 'git' packages
# assume "master" as a default branch name and don't honor attempts to override
# that via the "defaultBranch" configuration setting. If more recent distro
# versions change their defaults (e.g. to "main"), we know that such versions
# will also honor this configuration setting to override such defaults. So in
# the interests of maximum interoperability we go with "master", whilst
# acknowledging that this goes against coding guidelines in many environments.
# If you have no such legacy distro constraints and wish to (or must) adhere to
# revised naming conventions, please alter this setting accordingly.

RUN git config --system init.defaultBranch master

# Updates to the enrollment database take the form of git commits, which must
# have a user name and email address. The following suffices in general, but
# modify it to your heart's content; it is of no immediate consequence to
# anything else in the HCP architecture. (That said, you may have or want
# higher-layer interpretations, from an operational perspective. E.g. if the
# distinct repos from multiple regions/sites are being mirrored and inspected
# for more than backup/restore purposes, perhaps the identity in the commits is
# used to disambiguate them?)

RUN su -c "git config --global user.email 'do-not-reply@nowhere.special'" - db_user
RUN su -c "git config --global user.name 'Host Cryptographic Provisioning (HCP)'" - db_user
