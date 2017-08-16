# Custom Script for Linux
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
. /etc/lsb-release
# Reconfigure timezone
echo "America/Toronto" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
# Generate SMC Facts
mkdir -p /etc/facter/facts.d/;
cat > /etc/facter/facts.d/smc_facts.json  << EOF
{
  "smc_env": "dev",
  "smc_app": "ad_aggregator",
  "smc_infra": "infra_dev",
  "smc_comp": "lamp"
}
EOF
# Autosign the future puppet certificate for the VM
fqdn=$(hostname --fqdn)
# Install puppet
wget -O /tmp/puppetlabs-release-${DISTRIB_CODENAME}.deb https://apt.puppetlabs.com/puppetlabs-release-pc1-${DISTRIB_CODENAME}.deb
dpkg -i /tmp/puppetlabs-release-${DISTRIB_CODENAME}.deb
# Update APT indexes, upgrade, then install Puppet
apt update
apt full-upgrade -y
apt -y install puppet curl
sed -i 's/templatedir=$confdir\/templates/server=smc-foreman.cloudapp.net/g' /etc/puppet/puppet.conf
curl -X POST "https://jenkins.qmicube.net/job/puppet-sign-certificate/buildWithParameters?delay=0sec&hostname=${fqdn}" \
    --user 'admin:f8fedc24facf50318590e2ee4f75b0f1'
sleep 20;
puppet agent --enable
puppet agent -t
