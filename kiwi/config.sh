
#======================================
# Include functions & variables
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Call configuration code/functions
#--------------------------------------
echo "enabling forwarding"
tee /etc/sysctl.d/90_ip_forwarding.conf << EOF
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.all.forwarding = 1
EOF

tee /etc/modules-load.d/mpls_modules.conf << EOF
# Load MPLS Kernel Modules
mpls_router
mpls_iptunnel
EOF

tee /etc/systemd/system/mps_label_setup.service << EOF
# /etc/systemd/system/mps_label_setup.service
#

[Unit]
Description=Run my boot script

[Service]
Type=oneshot
ExecStart=/bin/sh -c "/etc/frr/mps_label_setup_sysctl.sh"

[Install]
WantedBy=multi-user.target
EOF

tee /etc/frr/mps_label_setup_sysctl.sh << EOF
# Enable MPLS Label processing on all interfaces
sysctl net.mpls.platform_labels=100000
for i in \$(ls /proc/sys/net/mpls/conf/ |grep -v lo); do
    sysctl net.mpls.conf.\$i.input=1
done
EOF
chmod +x /etc/frr/mps_label_setup_sysctl.sh
systemctl enable mps_label_setup

echo "enabling all frr daemons"
sed -i 's/=no$/=yes/g' /etc/frr/daemons
chgrp frrvty /etc/frr/

echo "enable qemu-guest-agent"
systemctl enable qemu-guest-agent

echo "Setting up dodgy hostname setter"
tee /etc/systemd/system/dodgy_hostname_hack.service << EOF
# /etc/systemd/system/dodgy_hostname_hack.service
#

[Unit]
Description=Set hostname at boot from a virt dev name

[Service]
Type=oneshot
ExecStart=/bin/sh -c "/etc/frr/dodgy_hostname_hack.sh"

[Install]
WantedBy=multi-user.target
EOF

tee /etc/frr/dodgy_hostname_hack.sh << EOF
# Set hostname from a null device that happens to container the name
#!/bin/bash
PREFIX="frr.router.hostname."
if [ -d /dev/virtio-ports/ ]; then
  cd /dev/virtio-ports/
  if [ \$(ls \$PREFIX* |wc -l) -gt 0 ];then
    hostname=\$(ls \$PREFIX* |sed "s/\$PREFIX//")
    hostnamectl set-hostname \$hostname
  fi
fi
EOF
chmod +x /etc/frr/dodgy_hostname_hack.sh
systemctl enable dodgy_hostname_hack

echo "enable frr"
systemctl enable frr

echo "frr pam - enable wheel group"
sed -i 's/#auth       sufficient   pam_wheel.so trust use_uid/auth       sufficient   pam_wheel.so trust use_uid group=frrvty/g' /etc/pam.d/frr

