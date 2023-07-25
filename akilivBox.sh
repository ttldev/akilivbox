#
# vm
# download kvm image

export image_source=https://cloud-images.ubuntu.com/minimal/releases/lunar/release-20230420/ubuntu-23.04-minimal-cloudimg-amd64.img
export image_name=ubuntu-23.04-amd64.img
export image_path=/var/lib/libvirt/images
sudo curl -L -o /var/lib/libvirt/images/$image_name $image_source

# set a root password on the image
sudo virt-customize -a $image_path/$image --root-password password:vyos

# check image disk size
sudo fdisk -l $image 

# Increase image disk size
sudo qemu-img resize -l $image +40G



# Grow VM partition
boot vm  and log as root


# Confirm  the new VM Disk Size
lsblk

# Expand the root Partition  to Maximum  New disk size 
# Redora/Centos sudo yum -y install cloud-utils-growpart gdisk
sudo apt update && sudo apt -y install cloud-guest-utils gdisk
sudo growpart /dev/vda 1

# Confirm the change
lsbk

# Resize / partition 
# For XFS filesystem - use xfs_growfs /
# For ext4 filesystem, use resize2fs /dev/vda1
sudo resize2fs /dev/vda1

# Confirm new root partition size using df -h
df -hT | grep /dev/vda

update-grub && reboot


# Add Admin User
adduser -u 1001 admins
usermod -aG sudo admins
echo "admins ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/admins
mkdir -m 700 /home/admins/.ssh



# generate the key at the client/guest worrkstation, use the program ssh-keygen as follows
ssh-keygen -t rsa

# copy your public key to a remote host with the command ssh-copy-id
ssh-copy-id -i ~/.ssh/id_rsa.pub $remote_user@$remote_host

# verify Key
cat .ssh/authorized_key 

# change key permission to private
chmond 600 .ssh/authorized_key 

# Change ssh  Port 22 to 16022
sudo ss -naptlu  | grep ssh

sudo mkdir -p /etc/systemd/system/ssh.socket.d
sudo cat > /etc/systemd/system/ssh.socket.d/listen.conf << EOF
[Socket]
ListenStream=
ListenStream=16022
EOF

sudo systemctl enable --now sshd
sudo ss -napt | grep 16022
sudo ss -naptlu  | grep ssh
## SSH Port Forwarding
# SSH login from source host to target host
#  set SSH Port Forwarding that requests to port [8081] on [dlp.srv.world (10.0.0.30)] are forwarded to port [80] on [node01.srv.world (10.0.0.51)]. 

 ssh -L 10.0.0.30:8081:10.0.0.51:80 debian@node01.srv.world 

# Scan Network
sudo apt update && sudo apt install arp-scan
sudo arp-scan 192.168.122.0/24


# set Persist network configuration for eth0

cat <EOF>> /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary Trunk network interface
auto eth0
iface eth0 inet dhcp
EOF

# Restart Network Interface
sudo ifdown eth0 && ifup eth0

# Set DNS
unlink systemd-resolved
cat <EOF> /etc/resolv.conf
nameserver 1.1.1.1
search akilistack.lan

# Set Hostname
hostnamectl set-hostname vhost23

# set  hosts
echo "192.168.122.22    vhost23.akilistack.lan" > /etc/hosts

# Restart Network Interface
sudo ifdown eth0 && ifup eth0


# Remove netplan.io & systemd-resolved & cloud-init
apt-get purge netplan.io systemd-resolved cloud-init cloud-guest-utils

============================================================================================================================================================================================

# Check Virtualization Support

sudo lscpu | grep Virtualization

Virtualization:                  VT-x
Virtualization type:             full

# Confirm the kernel includes KVM modules
# The module is only available if set to y or m

sudo zgrep CONFIG_KVM /boot/config-$(uname -r)

CONFIG_KVM_GUEST=y
CONFIG_KVM_MMIO=y
CONFIG_KVM_ASYNC_PF=y
CONFIG_KVM_VFIO=y
CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT=y
CONFIG_KVM_COMPAT=y
CONFIG_KVM_XFER_TO_GUEST_WORK=y
CONFIG_KVM=m
CONFIG_KVM_WERROR=y
CONFIG_KVM_INTEL=m
CONFIG_KVM_AMD=m
CONFIG_KVM_AMD_SEV=y
CONFIG_KVM_SMM=y
CONFIG_KVM_XEN=y
CONFIG_KVM_EXTERNAL_WRITE_TRACKING=y


# Install vbox packages
qemu-kvm: 
- A user-level KVM emulator that facilitates communication between hosts and VMs.

libvirt/libvirt-daemon-system: 
- A daemon that manages virtual machines and the hypervisor as well as handles library calls.

virt-install/virtinst: 
- A command-line tool for creating guest virtual machines.

virt-manager: 
- A graphical tool for creating and managing guest virtual machines.

virt-viewer: 
- A graphical console for connecting to a running virtual machine.

qemu-img/qemu-utils: 
- Provides tools to create, convert, modify, and snapshot offline disk images.

guestfs-tools/libguestfs-tools: 
- Provides a set of extended command-line tools for managing virtual machines.

libosinfo/libosinfo-bin:  
- A library for managing OS information for virtualization.

# When you create a Windows VM, you need to attach this ISO image to a CD-ROM. 
# It includes all the VirtIO drivers necessary for Windows OS installation.
 wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso
tuned: A system tuning service for Linux.

sudo apt install qemu-kvm libvirt-daemon-system virtinst 
sudo apt install  qemu-utils libguestfs-tools libosinfo-bin tuned
sudo apt-get -y install wget git curl nano mc vim  gnupg 
sudo apt-get -y install nmap net-tools uuid-runtime tcpdump jq lsof iputils-ping -y
sudo apt-get -y install python3-venv jq openssl psmisc pciutils nftables libvshadow-utils uidmap


# Enable the Modular libvirt Daemon
# Modular libvirt provides a specific daemon for each virtualization driver.
# Debian and Ubuntu continue to offer only a monolithic daemon.

#Fedora / Rocky Linux

# for drv in qemu interface network nodedev nwfilter secret storage; do \
#    sudo systemctl enable virt${drv}d.service; \
#    sudo systemctl enable virt${drv}d{,-ro,-admin}.socket; \
#    done

sudo systemctl enable libvirtd.service
sudo apt install qemu-kvm libvirt-daemon-system virtinst 
sudo apt install  qemu-utils libguestfs-tools libosinfo-bin tuned

grep 'Wants=libvirtd' /etc/systemd/system/*/*
systemctl list-dependencies --reverse libvirtd

# Optimize the Host with TuneD

# Enable and start the TuneD service.
sudo systemctl enable --now tuned

# Find out which TuneD profile is currently active

tuned-adm active

## List all TuneD profiles that are available on your system 
tuned-adm list

# set the profile to virtual-host
sudo tuned-adm profile virtual-host

# Check that the TuneD profile has been updated and that virtual-host is now active.
tuned-adm active

# Make sure there are no errors.
sudo tuned-adm verify

Add the regular user to the libvirt group.

$ sudo usermod -aG libvirt,kvm $USER

Define the environment variable LIBVIRT_DEFAULT_URI in the local .bashrc file of the user.

echo "export LIBVIRT_DEFAULT_URI='qemu:///system'" >> ~/.bashrc
source ~/.bashrc

Check again as a regular user to see which instance you are connected to.

$ virsh uri
qemu:///system




# Set ACL on the Images Directory
# Set ACL on the Images Directory

# By default, virtual machine disk images are stored in the /var/lib/libvirt/images directory. Only the root user has access to this directory.

ls /var/lib/libvirt/images/

ls: cannot open directory '/var/lib/libvirt/images/': Permission denied

# As a regular user, you might want access to this directory without having to type sudo every time. So, setting the ACL for this directory is the best way to access it without changing the default permissions.

# First, recursively remove any existing ACL permissions on the directory.

 sudo setfacl -R -b /var/lib/libvirt/images

# Grant regular user permission to the directory recursively.

sudo setfacl -R -m u:$USER:rwX /var/lib/libvirt/images

# The capital 'X' above indicates that 'execute' should only be applied to child folders and not child files.

# All existing directories and files (if any) in /var/lib/libvirt/images/ now have permissions. 
# any new directories and files created within this directory will not have any special permissions. 
# To get around this, we need to enable 'default' special permissions. 
# The 'default acls' can only be applied to directories and not to files.

sudo setfacl -m d:u:$USER:rwx /var/lib/libvirt/images

# Now review your new ACL permissions on the directory.
 getfacl /var/lib/libvirt/images


# Try accessing the /var/lib/libvirt/images directory again as a regular user.

touch /var/lib/libvirt/images/test_file

ls -l /var/lib/libvirt/images/
total 0
-rw-rw----+ 1 madhu madhu 0 Feb 12 21:34 test_file

You now have full access to the /var/lib/libvirt/images directory.

#T######################
STORAGE
##################################################################################################################################

# Configure libvirt

# When libvirt is first installed it doesn’t have any configured storage pools. Let’s create one in the default location, /var/lib/libvirt/images:

virsh pool-define-as default --type dir --target /var/lib/libvirt/images


# We need to mark the pool active, and we might as well configure it to activate automatically next time the system boots:

virsh pool-start default
virsh pool-autostart default


###################################################################
NETWORKING
#######################################################

virsh net-destroy default
virsh net-autostart default --disable
virsh net-undefine default

# Create Libvirt Network using linux bridge
cat <EOF>> vbox-network.xml
<network>
  <name>vbox-network</name>
  <uuid>49603eb9-4375-49e8-a4ed-9fa37f519b0f</uuid>
  <forward mode='bridge'/>
  <bridge name='vbr0'/>
</network>

virsh net-define vbox-network.xml
virsh net-start vbox-network
virsh net-autostart vbox-network
virsh net-list  


# Download Download a base image and  refresh the pool  for libvirt
sudo curl -L -o /var/lib/libvirt/images/centos-8-stream.qcow2 \
  https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210210.0.x86_64.qcow2

virsh pool-refresh default

# set a root password on the image
virt-customize -a /var/lib/libvirt/images/centos-8-stream.qcow2 \
  --root-password password:vyos  


virt-install \
  -r 12000 \
  --network network=default \
  --os-variant centos8 \
  --disk pool=default,size=42,backing_store=centos-8-stream.qcow2,backing_format=qcow2 \
  --import \
  --noautoconsole \
  -n vm0  

##########################################
TROUBLESHOOT

# LOGS
journalctl
journalctl -u networking
journalctl -f  Follow messages as they appear
Journalctl -u -f -k   kernel messages

 systemctl cat sshd.service

##########################################################################################################################################################################################

VAGRANT-LIBVIRT

==============================================================================================
# Vagrand-Libvirt Ubuntu Packages
sudo apt update 
sudo apt install libvirt-dev  linux-image-$(uname -r) curl freerdp2-x11 git jq libc6-dev libvirt-dev python3-winrm qemu-kvm qemu-utils sshpass xorriso unzip 

curl -O https://releases.hashicorp.com/vagrant/$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant  | jq -r -M '.current_version')/vagrant_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant  | jq -r -M '.current_version')_x86_64.deb && \
dpkg -i vagrant_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant  | jq -r -M '.current_version')_x86_64.deb && \


wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update

# https://github.com/hashicorp/vagrant/releases/tag/2.3.8.dev%2B000068-8004b9e0
sudo wget https://github.com/hashicorp/vagrant/releases/download/2.3.8.dev%2B000032-f72cda8b/vagrant_2.3.8.dev-1_amd64.deb

sudo dpkg -i vagrant_2.3.8.dev-1_amd64.deb

vagrant plugin install vagrant-libvirt 

vagrant box add --provider libvirt peru/windows-server-2016-standard-x64-eval && \
vagrant init peru/windows-server-2016-standard-x64-eval


Containerfile

FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm-256color

RUN apt-get update -y && \
    apt-get install -y \
    qemu-kvm \
    build-essential \
    libvirt-daemon-system \
    libvirt-dev \
    linux-image-$(uname -r) \
    curl \
    net-tools \
    jq && \
    apt-get autoremove -y && \
    apt-get clean

RUN curl -O https://releases.hashicorp.com/vagrant/$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant  | jq -r -M '.current_version')/vagrant_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant  | jq -r -M '.current_version')_x86_64.deb && \
	dpkg -i vagrant_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/vagrant  | jq -r -M '.current_version')_x86_64.deb && \
	vagrant plugin install vagrant-libvirt && \
	vagrant box add --provider libvirt peru/windows-server-2016-standard-x64-eval && \
	vagrant init peru/windows-server-2016-standard-x64-eval

COPY Vagrantfile /
COPY startup.sh /

ENTRYPOINT ["/startup.sh"]

CMD ["/bin/bash"]
EOF


vagrantfile
Vagrant.configure("2") do |config|

  config.vm.box = "peru/windows-server-2016-standard-x64-eval"
  config.vm.network "vbox-network", ip: "192.168.122.5"
  config.vm.network "forwarded_port", guest: 445, host: 445
  config.vm.provision "shell", inline: "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"
  #config.vm.network "forwarded_port", guest: 139, host: 139
  #config.vm.network "forwarded_port", guest: 137, host: 137
  #config.vm.network "forwarded_port", guest: 135, host: 135
  #config.vm.boot_timeout = 600
  #config.vm.base_address = "192.168.121.10"
  #config.winrm.host = "192.168.121.10"
  #config.winrm.timeout = 3600

end

EOF

startup.sh
#!/bin/bash
set -eou pipefail

chown root:kvm /dev/kvm

/usr/sbin/libvirtd --daemon
/usr/sbin/virtlogd --daemon

VAGRANT_DEFAULT_PROVIDER=libvirt vagrant up

iptables-save > /root/firewall.txt
iptables -A LIBVIRT_FWI -i eth0 -o virbr1 -p tcp --syn --dport 3389 -m conntrack --ctstate NEW -j ACCEPT
iptables -A LIBVIRT_FWI -i eth0 -o virbr1 -p tcp --syn --dport 445 -m conntrack --ctstate NEW -j ACCEPT
iptables -A LIBVIRT_FWI -i eth0 -o virbr1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A LIBVIRT_FWI -i virbr0 -o eth0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 3389 -j DNAT --to-destination 192.168.121.5
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 445 -j DNAT --to-destination 192.168.121.5
iptables -t nat -A LIBVIRT_PRT -o virbr1 -p tcp --dport 3389 -d 192.168.121.5 -j SNAT --to-source 192.168.121.1
iptables -t nat -A LIBVIRT_PRT -o virbr1 -p tcp --dport 445 -d 192.168.121.5 -j SNAT --to-source 192.168.121.1

iptables -D LIBVIRT_FWI -o virbr1 -j REJECT --reject-with icmp-port-unreachable
iptables -D LIBVIRT_FWI -o virbr0 -j REJECT --reject-with icmp-port-unreachable
iptables -D LIBVIRT_FWO -i virbr1 -j REJECT --reject-with icmp-port-unreachable
iptables -D LIBVIRT_FWO -i virbr0 -j REJECT --reject-with icmp-port-unreachable

exec "$@"
