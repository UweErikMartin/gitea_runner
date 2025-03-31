###############################################################################
# Perform a multistage build to create a systemd image and then install 
# the act_runner on top of it.
# The systemd image is based on the latest Ubuntu image and has systemd
# installed and configured to run in a container.
###############################################################################
FROM ubuntu:latest AS systemd

ENV \
	DEBIAN_FRONTEND=noninteractive \
	LANG=C.UTF-8 \
	container=docker \
	init=/lib/systemd/systemd

# install systemd packages
RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends systemd

# configure systemd
RUN \
# remove systemd 'wants' triggers
	find \
		/etc/systemd/system/*.wants/* \
		/lib/systemd/system/multi-user.target.wants/* \
		/lib/systemd/system/sockets.target.wants/*initctl* \
		! -type d \
		-delete && \
# remove everything except tmpfiles setup in sysinit target
	find \
		/lib/systemd/system/sysinit.target.wants \
		! -type d \
		! -name '*systemd-tmpfiles-setup*' \
		-delete && \
# remove UTMP updater service
	find \
		/lib/systemd \
		-name systemd-update-utmp-runlevel.service \
		-delete && \
# disable /tmp mount
	rm -vf /usr/share/systemd/tmp.mount && \
# fix missing BPF firewall support warning
	sed -ri '/^IPAddressDeny/d' /lib/systemd/system/systemd-journald.service && \
# just for cosmetics, fix "not-found" entries while using "systemctl --all"
	for MATCH in \
		plymouth-start.service \
		plymouth-quit-wait.service \
		syslog.socket \
		syslog.service \
		display-manager.service \
		systemd-sysusers.service \
		tmp.mount \
		systemd-udevd.service \
		; do \
			grep -rn --binary-files=without-match  ${MATCH} /lib/systemd/ | cut -d: -f1 | xargs sed -ri 's/(.*=.*)'${MATCH}'(.*)/\1\2/'; \
	done && \
	systemctl set-default multi-user.target

VOLUME ["/run", "/run/lock"]

STOPSIGNAL SIGRTMIN+3

ENTRYPOINT ["/lib/systemd/systemd"]

###############################################################################
# This is a multi-stage build, so we can use the systemd image as a base
# and then install the act_runner on top of it.
###############################################################################
FROM systemd AS act_runner
ARG TARGETARCH

ENV \
	DEBIAN_FRONTEND=noninteractive \
	LANG=C.UTF-8 \
	container=docker \
	init=/lib/systemd/systemd

# The act_runner requires docker to be installed, so we need to install it
# and enable it to start on boot. 
RUN \
	apt-get update && apt-get install -y docker.io \
	&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists \
	&& \
	systemctl enable docker

# install the act_runner as systemd service
COPY ./runner_${TARGETARCH} /usr/local/bin/act_runner
COPY ./act_runner.service /etc/systemd/system/act_runner.service
COPY ./config.yaml /etc/act_runner/config.yaml
RUN \
	chmod +x /usr/local/bin/act_runner && \
	systemctl enable act_runner.service
	
