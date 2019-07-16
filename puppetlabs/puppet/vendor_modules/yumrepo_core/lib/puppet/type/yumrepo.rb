require 'uri'

Puppet::Type.newtype(:yumrepo) do
  @doc = "The client-side description of a yum repository. Repository
    configurations are found by parsing `/etc/yum.conf` and
    the files indicated by the `reposdir` option in that file
    (see `yum.conf(5)` for details).

    Most parameters are identical to the ones documented
    in the `yum.conf(5)` man page.

    Continuation lines that yum supports (for the `baseurl`, for example)
    are not supported. This type does not attempt to read or verify the
    existence of files listed in the `include` attribute."

  # Ensure yumrepos can be removed too.
  ensurable
  # Doc string for properties that can be made 'absent'
  ABSENT_DOC = 'Set this to `absent` to remove it from the file completely.'.freeze
  # False can be false/0/no and True can be true/1/yes in yum.
  YUM_BOOLEAN = %r{^(true|false|0|1|no|yes)$}
  YUM_BOOLEAN_DOC = 'Valid values are: false/0/no or true/1/yes.'.freeze

  # Common munge logic for YUM_BOOLEAN values. Munges for two requirements:
  # 1) Because of how regex validation works in Puppet::Parameter::Value,
  # Boolean false and lowercase false will not be considered invalid. However,
  # if the user specified false (or true), they meant False (or True).
  # 2) In order for parameter removal to work correctly, when absent is passed
  # as a string it needs to be munged back to a symbol.
  munge_yum_bool = proc do |val|
    (val.to_s == 'absent') ? :absent : val.to_s.capitalize
  end

  VALID_SCHEMES = ['file', 'http', 'https', 'ftp'].freeze

  newparam(:name, namevar: true) do
    desc "The name of the repository.  This corresponds to the
     `repositoryid` parameter in `yum.conf(5)`."
  end

  newparam(:target) do
    desc 'The target parameter will be enabled in a future release and should not be used.'

    defaultto :absent
  end

  newproperty(:descr) do
    desc "A human-readable description of the repository.
      This corresponds to the name parameter in `yum.conf(5)`.
      #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:mirrorlist) do
    desc "The URL that holds the list of mirrors for this repository.
      #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s == 'absent'
      parsed = URI.parse(value)

      unless VALID_SCHEMES.include?(parsed.scheme)
        raise _('Must be a valid URL')
      end
    end
  end

  newproperty(:baseurl) do
    desc "The URL for this repository. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s == 'absent'

      value.split(%r{\s+}).each do |uri|
        parsed = URI.parse(uri)

        unless VALID_SCHEMES.include?(parsed.scheme)
          raise _('Must be a valid URL')
        end
      end
    end
  end

  newproperty(:enabled) do
    desc "Whether this repository is enabled.
    #{YUM_BOOLEAN_DOC}
    #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:gpgcheck) do
    desc "Whether to check the GPG signature on packages installed
      from this repository.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:payload_gpgcheck) do
    desc "Whether to check the GPG signature of the packages payload.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:repo_gpgcheck) do
    desc "Whether to check the GPG signature on repodata.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:gpgkey) do
    desc "The URL for the GPG key with which packages from this
      repository are signed. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s == 'absent'

      value.split(%r{\s+}).each do |uri|
        parsed = URI.parse(uri)

        unless VALID_SCHEMES.include?(parsed.scheme)
          raise _('Must be a valid URL')
        end
      end
    end
  end

  newproperty(:mirrorlist_expire) do
    desc "Time (in seconds) after which the mirrorlist locally cached
      will expire.\n#{ABSENT_DOC}"

    newvalues(%r{^[0-9]+$}, :absent)
  end

  newproperty(:include) do
    desc "The URL of a remote file containing additional yum configuration
      settings. Puppet does not check for this file's existence or validity.
      #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s == 'absent'
      parsed = URI.parse(value)

      unless VALID_SCHEMES.include?(parsed.scheme)
        raise _('Must be a valid URL')
      end
    end
  end

  newproperty(:exclude) do
    desc "The string of package names or shell globs separated by spaces to exclude.
      Packages that match the package name given or shell globs will never be
      considered in updates or installs for this repo.
      #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:gpgcakey) do
    desc "The URL for the GPG CA key for this repository. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s == 'absent'
      parsed = URI.parse(value)

      unless VALID_SCHEMES.include?(parsed.scheme)
        raise _('Must be a valid URL')
      end
    end
  end

  newproperty(:includepkgs) do
    desc "The string of package names or shell globs separated by spaces to
      include. If this is set, only packages matching one of the package
      names or shell globs will be considered for update or install
      from this repository. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:enablegroups) do
    desc "Whether yum will allow the use of package groups for this
      repository.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:failovermethod) do
    desc "The failover method for this repository; should be either
      `roundrobin` or `priority`. #{ABSENT_DOC}"

    newvalues(%r{^roundrobin|priority$}, :absent)
  end

  newproperty(:keepalive) do
    desc "Whether HTTP/1.1 keepalive should be used with this repository.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:retries) do
    desc "Set the number of times any attempt to retrieve a file should
      retry before returning an error. Setting this to `0` makes yum
     try forever.\n#{ABSENT_DOC}"

    newvalues(%r{^[0-9]+$}, :absent)
  end

  newproperty(:http_caching) do
    desc "What to cache from this repository. #{ABSENT_DOC}"

    newvalues(%r{^(packages|all|none)$}, :absent)
  end

  newproperty(:timeout) do
    desc "Number of seconds to wait for a connection before timing
      out. #{ABSENT_DOC}"

    newvalues(%r{^\d+$}, :absent)
  end

  newproperty(:metadata_expire) do
    desc "Number of seconds after which the metadata will expire.
      #{ABSENT_DOC}"

    newvalues(%r{^([0-9]+[dhm]?|never)$}, :absent)
  end

  newproperty(:protect) do
    desc "Enable or disable protection for this repository. Requires
      that the `protectbase` plugin is installed and enabled.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:priority) do
    desc "Priority of this repository. Can be any integer value
      (including negative). Requires that the `priorities` plugin
      is installed and enabled.
      #{ABSENT_DOC}"

    newvalues(%r{^-?\d+$}, :absent)
  end

  newproperty(:throttle) do
    desc "Enable bandwidth throttling for downloads. This option
      can be expressed as a absolute data rate in bytes/sec or a
      percentage `60%`. An SI prefix (k, M or G) may be appended
      to the data rate values.\n#{ABSENT_DOC}"

    newvalues(%r{^\d+[kMG%]?$}, :absent)
  end

  newproperty(:bandwidth) do
    desc "Use to specify the maximum available network bandwidth
      in bytes/second. Used with the `throttle` option. If `throttle`
      is a percentage and `bandwidth` is `0` then bandwidth throttling
      will be disabled. If `throttle` is expressed as a data rate then
      this option is ignored.\n#{ABSENT_DOC}"

    newvalues(%r{^\d+[kMG]?$}, :absent)
  end

  newproperty(:cost) do
    desc "Cost of this repository. #{ABSENT_DOC}"

    newvalues(%r{^\d+$}, :absent)
  end

  newproperty(:proxy) do
    desc "URL of a proxy server that Yum should use when accessing this repository.
      This attribute can also be set to `'_none_'`, which will make Yum bypass any
      global proxy settings when accessing this repository.
      #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s =~ %r{^(absent|_none_)$}
      parsed = URI.parse(value)

      unless VALID_SCHEMES.include?(parsed.scheme)
        raise _('Must be a valid URL')
      end
    end
  end

  newproperty(:proxy_username) do
    desc "Username for this proxy. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:proxy_password) do
    desc "Password for this proxy. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:s3_enabled) do
    desc "Access the repository via S3.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:sslcacert) do
    desc "Path to the directory containing the databases of the
      certificate authorities yum should use to verify SSL certificates.
      #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:sslverify) do
    desc "Should yum verify SSL certificates/hosts at all.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:sslclientcert) do
    desc "Path  to the SSL client certificate yum should use to connect
      to repositories/remote sites. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:sslclientkey) do
    desc "Path to the SSL client key yum should use to connect
      to repositories/remote sites. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
  end

  newproperty(:metalink) do
    desc "Metalink for mirrors. #{ABSENT_DOC}"

    newvalues(%r{.*}, :absent)
    validate do |value|
      next if value.to_s == 'absent'
      parsed = URI.parse(value)

      unless VALID_SCHEMES.include?(parsed.scheme)
        raise _('Must be a valid URL')
      end
    end
  end

  newproperty(:skip_if_unavailable) do
    desc "Should yum skip this repository if unable to reach it.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:assumeyes) do
    desc "Determines if yum prompts for confirmation of critical actions.
      #{YUM_BOOLEAN_DOC}
      #{ABSENT_DOC}"

    newvalues(YUM_BOOLEAN, :absent)
    munge(&munge_yum_bool)
  end

  newproperty(:deltarpm_percentage) do
    desc "Percentage value that determines when to use deltas for this repository.
      When the delta is larger than this percentage value of the package, the
      delta is not used.
      #{ABSENT_DOC}"

    newvalues(%r{^\d+$}, :absent)
  end

  newproperty(:deltarpm_metadata_percentage) do
    desc "Percentage value that determines when to download deltarpm metadata.
      When the deltarpm metadata is larger than this percentage value of the
      package, deltarpm metadata is not downloaded.
      #{ABSENT_DOC}"

    newvalues(%r{^\d+$}, :absent)
  end

  newproperty(:username) do
    desc "Username to use for basic authentication to a repo or really any url.
      #{ABSENT_DOC}"
    newvalues(%r{.*}, :absent)
  end

  newproperty(:password) do
    desc "Password to use with the username for basic authentication.
      #{ABSENT_DOC}"
    newvalues(%r{.*}, :absent)
  end

  private

  def set_sensitive_parameters(sensitive_parameters) # rubocop:disable Style/AccessorMethodName
    parameter(:password).sensitive = true if parameter(:password)
    parameter(:proxy_password).sensitive = true if parameter(:proxy_password)
    super(sensitive_parameters)
  end
end
