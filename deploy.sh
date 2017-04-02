
# Stop processing on error
set -e

echo Configuring container
mkdir -p etc var/run

cp /etc/ssh/sshd_config etc
sed -i'' 's|^Port 22|Port 2022|' etc/sshd_config
sed -i'' "s|^HostKey .*|HostKey $HOME/etc/ssh_host_rsa_key|" etc/sshd_config
sed -i'' 's|^UsePrivilegeSeparation yes|UsePrivilegeSeparation no|' etc/sshd_config
sed -i'' "s|^HostKey .*|HostKey $HOME/etc/ssh_host_rsa_key|" etc/sshd_config
# From man page: If UsePAM is enabled, you will not be able to run sshd(8) as a non-root user. The default is ''no''.
sed -i"" "s|^UsePAM .*|UsePAM no|" etc/sshd_config

if [ -f ssh_host_rsa_key ]; then
	cp ssh_host_rsa_key $HOME/etc/ssh_host_rsa_key
	chmod 0600 $HOME/etc/ssh_host_rsa_key
else
	ssh-keygen -t rsa -f $HOME/etc/ssh_host_rsa_key -N ''
fi

mkdir -p ../.ssh
cat id_rsa.pub >> ../.ssh/authorized_keys

chmod -R 0600 ../.ssh/*

# Build our own SSHD
git clone https://github.com/openssh/openssh-portable.git
pushd openssh-portable
autoreconf
./configure
# Patch sshd to not change gid of the allocated pty. Otherwise the chown() call
# fails, and sshd refuses to start.
sed -i 's|\(\s*\)\(gid =.*\)|\1gid = -1;//\2|' sshpty.c
make -j 4 sshd
popd

# Launch sshd in daemon mode
#fakeroot /usr/sbin/chroot "$(pwd)" /usr/sbin/sshd -f etc/sshd_config -dD &
#/usr/sbin/sshd -f etc/sshd_config -dD &
$(pwd)/openssh-portable/sshd -f etc/sshd_config

# PASS=$(cat /dev/urandom | head -c 100 | sha256sum | base64 | head -c 32)
# echo "$PASS" | passwd 

# Start the webserver immediately; this prevents Cloud Foundry from killing this container
./bin/chisel server --proxy http://example.com --port $PORT

