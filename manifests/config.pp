Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/'] }

package { [
    'build-essential',
    'curl',
    'git-core'
  ]:
  ensure  => 'installed'
}

class base {
  exec { 'apt-get update':
    command => '/usr/bin/apt-get update'
  }
}

class http{

    define apache::loadmodule () {
        exec { "/usr/sbin/a2enmod $name" :
            unless => "/bin/readlink -e /etc/apache2/mods-enabled/${name}.load",
            notify => Service[apache2]
        }
    }

    apache::loadmodule{"rewrite":}

    package { "apache2":
        ensure => present,
    }

    service { "apache2":
        ensure => running,
        require => Package["apache2"],
    }
}

class php{

  package { "php5":
    ensure => present,
  }

  package { "php5-cli":
    ensure => present,
  }

  package { "php5-mysql":
    ensure => present,
  }

  package { "php5-gd":
    ensure => present,
  }

  package { "php5-mcrypt":
    ensure => present,
  }

  package { "php5-curl":
    ensure => present,
  }

  package { "php5-xdebug":
    ensure => present,
  }

  package { "php5-dev":
    ensure => present,
  }

  package { "php-pear":
    ensure => present,
  }

  package { "libapache2-mod-php5":
    ensure => present,
  }

}

class mysql{

  package { "mysql-server":
    ensure => present,
  }

  service { "mysql":
    ensure => running,
    require => Package["mysql-server"],
  }
}

class phpmyadmin(){
   package { 'phpmyadmin':
    ensure => present,
    require => Package['php5']
  }
  ->
  file { '/etc/phpmyadmin/config.inc.php':
    ensure   => file,
    replace  => true,
    content  => template('phpmyadmin/config.inc.php'),
  }
  ->
  file { '/usr/share/phpmyadmin/config.inc.php':
    ensure => link,
    target => '/etc/phpmyadmin/config.inc.php',
  }
  ->
  file { '/etc/phpmyadmin/config-db.php':
    ensure   => file,
    replace  => true,
    content  => template('phpmyadmin/config-db.php'),
  }
  ->
  file { '/etc/apache2/sites-available/phpmyadmin.conf':
  ensure => link,
  target => '/etc/phpmyadmin/apache.conf',
  require => Package['phpmyadmin'],
  }

  exec { 'enable-phpmyadmin':
    command => 'sudo a2ensite phpmyadmin.conf',
    require => File['/etc/apache2/sites-available/phpmyadmin.conf'],
  }

  exec { 'restart-apache':
    command => 'sudo /etc/init.d/apache2 restart',
    require => Exec['enable-phpmyadmin'],
  }
}


class xdebug{

  file {"/etc/php5/apache2/conf.d/xdebug.ini":
       content => template('php/xdebug.ini.erb'),
       require => Package['php5-xdebug'],
       ensure => 'present',
    }
}

class prepare {
  class { 'apt': }
  apt::ppa { 'ppa:chris-lea/node.js': }
}

class nodejs{
  package {'nodejs':
    ensure => present,
    require => Class['prepare']
  }
}

class npm{
  exec{ '/usr/bin/npm install -g express-generator':
    require => Class['nodejs']
  }
    exec{ '/usr/bin/npm install -g nodemon':
    require => Class['nodejs']
  }
}

include base
include mysql
include http
include php
class { 'phpmyadmin':}
include xdebug

include prepare
include nodejs
include npm