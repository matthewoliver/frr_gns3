
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


echo "enable frr"
systemctl enable frr

echo "frr pam - enable wheel group"
sed -i 's/#auth       sufficient   pam_wheel.so trust use_uid/auth       sufficient   pam_wheel.so trust use_uid group=frrvty/g' /etc/pam.d/frr

