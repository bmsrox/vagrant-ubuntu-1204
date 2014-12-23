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

#CONFIGURAÇÃO DE REWRITE E APACHE
class http{

    define apache::loadmodule () {
        exec { "sudo /usr/sbin/a2enmod $name" :
            unless => "/bin/readlink -e /etc/apache2/mods-enabled/${name}.load",
            notify => Service[apache2],
            require => Package['apache2']
        }
    }


    package { "apache2":
        ensure => present,
    }

    apache::loadmodule{"rewrite":}

    service { "apache2":
        ensure => running,
        require => Package["apache2"],
    }
}

#INSTALAÇÃO DO PHP
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

#INSTALAÇÃO DO MYSQL
class mysql{

  package { "mysql-server":
    ensure => present,
  }

  service { "mysql":
    ensure => running,
    require => Package["mysql-server"],
  }
}

#INSTALAÇÃO DO PHPMYADMIN
class phpmyadmin(){
   package { 'phpmyadmin':
    ensure => present,
    require => Class['php']
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

#INSTALAÇÃO DO XDEBUG
class xdebug{

  exec{ 'sudo /usr/bin/pecl install xdebug -y':
    require => Class['php']
  }

  file {"/etc/php5/apache2/conf.d/xdebug.ini":
       content => template('php/xdebug.ini.erb'),
       require => [Class['php'], Exec['sudo /usr/bin/pecl install xdebug -y']],
       ensure => 'present',
       notify => Service[apache2]
    }
}

#ADD O REPOSITORIO DE INSTALAÇÃO DO NODE.JS
class prepare {
  class { 'apt': }
  apt::ppa { 'ppa:chris-lea/node.js': }
}

#INSTALAÇÃO NODE.JS
class nodejs{
  package {'nodejs':
    ensure => present,
    require => Class['prepare']
  }
}

#CONFIGURA OS NPMs
class npm{

  exec{ '/usr/bin/npm install -g express-generator':
    require => Class['nodejs']
  }

  exec{ '/usr/bin/npm install -g nodemon':
    require => Class['nodejs']
  }

}

#INSTALAÇÃO MONGODB
class mongodb{

  exec {'import_public_key':
    command => '/usr/bin/apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10',
  }

  file {'/etc/apt/sources.list.d/mongodb.list':
    ensure  => 'present',
    content => template('mongodb/mongodb.erb'),
    require => Exec['import_public_key'],
  }

  exec {'install_mongodb':
    command => 'sudo /usr/bin/apt-get install mongodb-org -y',
    require => [Class['nodejs'], File['/etc/apt/sources.list.d/mongodb.list'], Class['base']],
    tries => 3,
    logoutput => on_failure
  }

  service {'mongod':
    ensure  => 'running',
    require => Exec['install_mongodb'],
  }
}

#INSTALAÇÃO LAMP
include base
include mysql
include http
include php
class { 'phpmyadmin':}
include xdebug

#INSTALAÇÃO MEAN
include prepare
include nodejs
include npm
include mongodb