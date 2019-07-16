require 'puppet/provider/nameservice/objectadd'
require 'date'
require 'puppet/util/libuser'
require 'time'
require 'puppet/error'

Puppet::Type.type(:user).provide :useradd, :parent => Puppet::Provider::NameService::ObjectAdd do
  desc "User management via `useradd` and its ilk.  Note that you will need to
    install Ruby's shadow password library (often known as `ruby-libshadow`)
    if you wish to manage user passwords."

  commands :add => "useradd", :delete => "userdel", :modify => "usermod", :password => "chage"

  options :home, :flag => "-d", :method => :dir
  options :comment, :method => :gecos
  options :groups, :flag => "-G"
  options :password_min_age, :flag => "-m", :method => :sp_min
  options :password_max_age, :flag => "-M", :method => :sp_max
  options :password_warn_days, :flag => "-W", :method => :sp_warn
  options :password, :method => :sp_pwdp
  options :expiry, :method => :sp_expire,
    :munge => proc { |value|
      if value == :absent
        ''
      else
        case Facter.value(:operatingsystem)
        when 'Solaris'
          # Solaris uses %m/%d/%Y for useradd/usermod
          expiry_year, expiry_month, expiry_day = value.split('-')
          [expiry_month, expiry_day, expiry_year].join('/')
        else
          value
        end
      end
    },
    :unmunge => proc { |value|
      if value == -1
        :absent
      else
        # Expiry is days after 1970-01-01
        (Date.new(1970,1,1) + value).strftime('%Y-%m-%d')
      end
    }

  optional_commands :localadd => "luseradd", :localdelete => "luserdel", :localmodify => "lusermod", :localpassword => "lchage"
  has_feature :libuser if Puppet.features.libuser?

  def exists?
    return !!localuid if @resource.forcelocal?
    super
  end

  def uid
     return localuid if @resource.forcelocal?
     get(:uid)
  end

  def finduser(key, value)
    passwd_file = "/etc/passwd"
    passwd_keys = ['account', 'password', 'uid', 'gid', 'gecos', 'directory', 'shell']
    index = passwd_keys.index(key)
    File.open(passwd_file) do |f|
      f.each_line do |line|
         user = line.split(":")
         if user[index] == value
             f.close
             return user
         end
      end
    end
    false
  end

  def local_username
    finduser('uid', @resource.uid)
  end

  def localuid
    user = finduser('account', resource[:name])
    return user[2] if user
    false
  end

  def shell=(value)
    check_valid_shell
    set("shell", value)
  end

  verify :gid, "GID must be an integer" do |value|
    value.is_a? Integer
  end

  verify :groups, "Groups must be comma-separated" do |value|
    value !~ /\s/
  end

  has_features :manages_homedir, :allows_duplicates, :manages_expiry
  has_features :system_users unless %w{HP-UX Solaris}.include? Facter.value(:operatingsystem)

  has_features :manages_passwords, :manages_password_age if Puppet.features.libshadow?
  has_features :manages_shell

  def check_allow_dup
    # We have to manually check for duplicates when using libuser
    # because by default duplicates are allowed.  This check is
    # to ensure consistent behaviour of the useradd provider when
    # using both useradd and luseradd
    if (!@resource.allowdupe?) && @resource.forcelocal?
       if @resource.should(:uid) && finduser('uid', @resource.should(:uid).to_s)
           raise(Puppet::Error, "UID #{@resource.should(:uid).to_s} already exists, use allowdupe to force user creation")
       end
    elsif @resource.allowdupe? && (!@resource.forcelocal?)
       return ["-o"]
    end
    []
  end

  def check_valid_shell
    unless File.exists?(@resource.should(:shell))
      raise(Puppet::Error, "Shell #{@resource.should(:shell)} must exist")
    end
    unless File.executable?(@resource.should(:shell).to_s)
      raise(Puppet::Error, "Shell #{@resource.should(:shell)} must be executable")
    end
  end

  def check_manage_home
    cmd = []
    if @resource.managehome? && (!@resource.forcelocal?)
      cmd << "-m"
    elsif (!@resource.managehome?) && Facter.value(:osfamily) == 'RedHat'
      cmd << "-M"
    end
    cmd
  end

  def check_system_users
    if self.class.system_users? && resource.system?
      ["-r"]
    else
      []
    end
  end

  def add_properties
    cmd = []
    # validproperties is a list of properties in undefined order
    # sort them to have a predictable command line in tests
    Puppet::Type.type(:user).validproperties.sort.each do |property|
      next if property == :ensure
      next if property_manages_password_age?(property)
      next if (property == :groups) && @resource.forcelocal?
      next if (property == :expiry) && @resource.forcelocal?
      
      value = @resource.should(property)
      if value && value != ""
        # the value needs to be quoted, mostly because -c might
        # have spaces in it
        cmd << flag(property) << munge(property, value)
      end
    end
    cmd
  end

  def addcmd
    if @resource.forcelocal?
      cmd = [command(:localadd)]
      @custom_environment = Puppet::Util::Libuser.getenv
    else
      cmd = [command(:add)]
    end
    if (!@resource.should(:gid)) && Puppet::Util.gid(@resource[:name])
      cmd += ["-g", @resource[:name]]
    end
    cmd += add_properties
    cmd += check_allow_dup
    cmd += check_manage_home
    cmd += check_system_users
    cmd << @resource[:name]
  end

  def modifycmd(param, value)
    if @resource.forcelocal?
      case param
      when :groups, :expiry
        cmd = [command(:modify)]
      else
        cmd = [command(property_manages_password_age?(param) ? :localpassword : :localmodify)]
      end
      @custom_environment = Puppet::Util::Libuser.getenv
    else
      cmd = [command(property_manages_password_age?(param) ? :password : :modify)]
    end
    cmd << flag(param) << value
    cmd += check_allow_dup if param == :uid
    cmd << @resource[:name]

    cmd
  end

  def deletecmd
    if @resource.forcelocal?
      cmd = [command(:localdelete)]
      @custom_environment = Puppet::Util::Libuser.getenv
    else
      cmd = [command(:delete)]
    end
    # Solaris `userdel -r` will fail if the homedir does not exist.
    if @resource.managehome? && (('Solaris' != Facter.value(:operatingsystem)) || Dir.exist?(Dir.home(@resource[:name])))
      cmd << '-r'
    end
    cmd << @resource[:name]
  end

  def passcmd
    if @resource.forcelocal?
      cmd = command(:localpassword)
      @custom_environment = Puppet::Util::Libuser.getenv
    else
      cmd = command(:password)
    end
    age_limits = [:password_min_age, :password_max_age, :password_warn_days].select { |property| @resource.should(property) }
    if age_limits.empty?
      nil
    else
      [cmd, age_limits.collect { |property| [flag(property), @resource.should(property)]}, @resource[:name]].flatten
    end
  end

  [:expiry, :password_min_age, :password_max_age, :password_warn_days, :password].each do |shadow_property|
    define_method(shadow_property) do
      if Puppet.features.libshadow?
        ent = Shadow::Passwd.getspnam(@canonical_name)
        if ent
          method = self.class.option(shadow_property, :method)
          return unmunge(shadow_property, ent.send(method))
        end
      end
      :absent
    end
  end

  def create
    if @resource[:shell]
      check_valid_shell
    end
     super
     if @resource.forcelocal? && self.groups?
       set(:groups, @resource[:groups])
     end
     if @resource.forcelocal? && @resource[:expiry]
       set(:expiry, @resource[:expiry])
     end
  end

  def groups?
    !!@resource[:groups]
  end

  def property_manages_password_age?(property)
    property.to_s =~ /password_.+_age|password_warn_days/
  end
end
