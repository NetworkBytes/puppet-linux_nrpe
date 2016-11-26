# Define: nagios::client::nrpe_file
#
# Install check-specific client nrpe configuration snippet files.
#
define nrpe::client::nrpe_file (
  $ensure    = undef,
  $plugin    = $name,
  $template  = 'check_custom',
  $command   = $name,
  $sudo      = false,
  $sudo_user = undef,
  $args      = false,
  $script,
) {

  file { "${nagios::params::nrpe_cfg_dir}/nrpe-${title}.cfg":
    ensure  => $ensure,
    owner   => 'root',
    group   => $nagios::client::nrpe_group,
    mode    => '0640',
    content => template("nrpe/nrpe-${template}.cfg.erb"),
    notify  => Service[$nagios::params::nrpe_service],
  }
}
