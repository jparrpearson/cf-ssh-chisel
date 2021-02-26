# Stop processing on error
set -e
set -x

# The expectation is that the HOME is set to /home/vcap/app, and that the directory
# these commands are executed in is at $HOME.

echo Current environment
env

echo Configuring container
mkdir -p $HOME/etc $HOME/var/run

cp /etc/ssh/sshd_config $HOME/etc
sed -i'' 's|^Port 22|Port 2022|' $HOME/etc/sshd_config
sed -i'' "s|^HostKey .*|HostKey $HOME/etc/ssh_host_rsa_key|" $HOME/etc/sshd_config
sed -i'' 's|^UsePrivilegeSeparation yes|UsePrivilegeSeparation no|' $HOME/etc/sshd_config
# From man page: If UsePAM is enabled, you will not be able to run sshd(8) as a non-root user. The default is ''no''.
sed -i"" "s|^UsePAM .*|UsePAM no|" $HOME/etc/sshd_config

if [ -f ssh_host_rsa_key ]; then
	cp ssh_host_rsa_key $HOME/etc/ssh_host_rsa_key
	chmod 0600 $HOME/etc/ssh_host_rsa_key
else
	ssh-keygen -t rsa -f $HOME/etc/ssh_host_rsa_key -N ''
fi

# The authorized_keys is expected under /home/vcap, not /home/vcap/app
USER_HOME=/home/vcap
mkdir -p $USER_HOME/.ssh
chmod 0700 $USER_HOME/.ssh
cat id_rsa.pub >> $USER_HOME/.ssh/authorized_keys
chmod -R 0600 $USER_HOME/.ssh/authorized_keys

# Install OpenSSH
pushd $HOME
for f in $HOME/*.deb; do rm -f data.tar.*;  ar x "$f";  tar xf data.tar.*;  done
popd

# Launch sshd in background
$HOME/usr/sbin/sshd -f $HOME/etc/sshd_config

# Start the webserver immediately; this prevents Cloud Foundry from killing this container
./bin/chisel server --proxy http://example.com --port ${PORT:-8080}

