begin test_name "puppet module install with necessary dependency upgrade"

step 'Setup'
require 'resolv'; ip = Resolv.getaddress('forge-dev.puppetlabs.com')
apply_manifest_on master, "host { 'forge.puppetlabs.com': ip => '#{ip}' }"
apply_manifest_on master, "file { ['/etc/puppet/modules', '/usr/share/puppet/modules']: recurse => true, purge => true, force => true }"

step "Install an older module version"
on master, "puppet module install pmtacceptance-java --version 1.6.0" do
  assert_equal '', stderr
end

on master, 'puppet module list' do
  assert_equal <<-STDOUT, stdout
/etc/puppet/modules
pmtacceptance-java (1.6.0)
pmtacceptance-stdlib (1.0.0)
/usr/share/puppet/modules (No modules installed)
STDOUT
end


step "Install a module that requires the older module dependency be upgraded"
on master, "puppet module install pmtacceptance-apollo" do
  assert_equal <<-STDERR,  stderr
\e[1;31mWarning: Deleting /etc/puppet/modules/java\e[0m
STDERR
end

on master, 'puppet module list' do
  assert_equal <<-STDOUT, stdout
/etc/puppet/modules
pmtacceptance-apollo (0.0.1)
pmtacceptance-java (1.7.1)
pmtacceptance-stdlib (1.0.0)
/usr/share/puppet/modules (No modules installed)
STDOUT
end

ensure step "Teardown"
apply_manifest_on master, "host { 'forge.puppetlabs.com': ensure => absent }"
apply_manifest_on master, "file { ['/etc/puppet/modules', '/usr/share/puppet/modules']: recurse => true, purge => true, force => true }"
end