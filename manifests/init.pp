class nrpe {

  file {"$::nagios::params::plugin_dir/custom":
    ensure  => directory,
    mode    => "0755",
  }

}
