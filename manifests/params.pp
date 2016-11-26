class nrpe::params {

  $libdir = $::architecture ? {
    'x86_64' => 'lib64',
    'amd64'  => 'lib64',
    'ppc64'  => 'lib64',
    default  => 'lib',
  }

  case $::operatingsystem {
    'RedHat', 'Fedora', 'CentOS', 'Scientific', 'Amazon': {
      $plugins_custom_dir = hiera('nrpe::params::plugins_custom_dir',"/usr/${libdir}/nagios/plugins/custom")
    }
  }
}

