# Class: s3fs
#
# This module installs s3fs
#
# Parameters:
#
#  [*ensure*]                - 'present',
#  [*s3fs_package*]          - $s3fs::params::s3fs_package,
#  [*download_dir*]          - Dir where s3fs tar.gz is downloaded
#  [*version*]               - s3fs version
#  [*download_url*]          - s3fs tar.gz download link
#  [*aws_access_key_id*]     - aws access key id
#  [*aws_secret_access_key*] - aws secret access key
#  [*credentials_file*]      - location of aws credentials file
#
# Actions:
#
# Requires:
#
#  Class['s3fs::dependencies'], Class['s3fs::params']
#
# Sample Usage:
#
#  class { 's3fs':
#    $aws_access_key_id     => 'randomKey',
#    $aws_secret_access_key => 'randomSecret',
#  }
#

# http://code.google.com/p/s3fs/downloads/detail?name=s3fs-1.62.tar.gz&can=2&q=
class s3fs (
  $aws_secret_access_key,
  $aws_access_key_id,
  $ensure                = 'present',
  $s3fs_package          = 's3fs',
  $download_dir          = '/var/tmp',
  $version               = '1.61',
  $download_url          = 'http://s3fs.googlecode.com/files',
  $credentials_file      = '/etc/passwd-s3fs',
) {

  $credentials = inline_template(
    "<%= @aws_access_key_id %>:<%= @aws_secret_access_key %>\n")

  Class['s3fs::dependencies'] -> Class['s3fs']

  include s3fs::dependencies

  file{ 's3fs_credentials':
    ensure  => $ensure,
    path    => $credentials_file,
    content => $credentials,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
  }

  Exec['s3fs_tar_gz']
    ~> Exec['s3fs_extract']
    ~> Exec['s3fs_configure']
    ~> Exec['s3fs_make']
    ~> Exec['s3fs_install']

  # Distribute s3fs source from within module to control version (could
  # also download from Google directly):
  exec { 's3fs_tar_gz':
    command   => "/usr/bin/curl -o ${download_dir}/s3fs-${version}.tar.gz ${download_url}/s3fs-${version}.tar.gz",
    logoutput => true,
    timeout   => 300,
    unless    => "/usr/bin/which /usr/local/bin/s3fs && /usr/local/bin/s3fs --version | grep ${version}",
  }

  # Extract s3fs source:
  exec { 's3fs_extract':
    creates   => "${download_dir}/s3fs-${version}",
    cwd       => "${download_dir}",
    command   => "tar --no-same-owner -xzf ${download_dir}/s3fs-$version.tar.gz",
    logoutput => true,
    timeout   => 300,
    path      => '/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true,
  }

  # Configure s3fs build:
  exec { 's3fs_configure':
    creates     => "${download_dir}/s3fs-${version}/config.status",
    cwd         => "${download_dir}/s3fs-${version}",
    command     => "${download_dir}/s3fs-${version}/configure",
    logoutput   => true,
    timeout     => 300,
    refreshonly => true,
  }

  # Build s3fs:
  exec { 's3fs_make':
    creates     => "${download_dir}/s3fs-${version}/src/s3fs",
    cwd         => "${download_dir}/s3fs-${version}",
    command     => "/usr/bin/make",
    logoutput   => true,
    timeout     => 300,
    refreshonly => true,
  }

  # Install s3fs
  exec { 's3fs_install':
    command     => "/usr/bin/make install",
    cwd         => "${download_dir}/s3fs-${version}",
    logoutput   => true,
    timeout     => 300,
    refreshonly => true,
  }

}
