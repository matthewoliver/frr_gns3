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
suseActivateDefaultServices
baseInsertService frr
baseService frr on

baseInsertService mps_label_setup
baseService mps_label_setup on

#======================================
# Exit successfully
#--------------------------------------
exit 0
