Puppet::Type.type(:zone).provide(:solaris) do
  desc 'Provider for Solaris Zones.'

  commands adm: '/usr/sbin/zoneadm', cfg: '/usr/sbin/zonecfg'
  defaultfor osfamily: :solaris

  mk_resource_methods

  # Convert the output of a list into a hash
  def self.line2hash(line)
    fields = [:id, :name, :ensure, :path, :uuid, :brand, :iptype]
    properties = Hash[fields.zip(line.split(':'))]

    del_id = [:brand, :uuid]
    # Configured but not installed zones do not have IDs
    del_id << :id if properties[:id] == '-'
    del_id.each { |p| properties.delete(p) }

    properties[:ensure] = properties[:ensure].to_sym
    properties[:iptype] = 'exclusive' if properties[:iptype] == 'excl'

    properties
  end

  def self.instances
    adm(:list, '-cp').split("\n").map do |line|
      new(line2hash(line))
    end
  end

  def multi_conf(name, should)
    has = properties[name]
    has = [] if !has || has == :absent
    rms = has - should
    adds = should - has
    (rms.map { |o| yield(:rm, o) } + adds.map { |o| yield(:add, o) }).join("\n")
  end

  def self.def_prop(var, str)
    define_method('%s_conf' % var.to_s) do |v|
      str % v
    end
    define_method('%s=' % var.to_s) do |v|
      setconfig send(('%s_conf' % var).to_sym, v)
    end
  end

  def self.def_multiprop(var, &conf)
    define_method(var.to_s) do |_v|
      o = properties[var]
      return '' if o.nil? || o == :absent
      o.join(' ')
    end
    define_method('%s=' % var.to_s) do |v|
      setconfig send(('%s_conf' % var).to_sym, v)
    end
    define_method('%s_conf' % var.to_s) do |v|
      multi_conf(var, v, &conf)
    end
  end

  def_prop :iptype, 'set ip-type=%s'
  def_prop :autoboot, 'set autoboot=%s'
  def_prop :path, 'set zonepath=%s'
  def_prop :pool, 'set pool=%s'
  def_prop :shares, "add rctl\nset name=zone.cpu-shares\nadd value (priv=privileged,limit=%s,action=none)\nend"

  def_multiprop :ip do |action, str|
    interface, ip, defrouter = str.split(':')
    case action
    when :add
      cmd = ['add net']
      cmd << "set physical=#{interface}" if interface
      cmd << "set address=#{ip}" if ip
      cmd << "set defrouter=#{defrouter}" if defrouter
      cmd << 'end'
      cmd.join("\n")
    when :rm
      if ip
        "remove net address=#{ip}"
      elsif interface
        "remove net physical=#{interface}"
      else
        raise ArgumentError, _('can not remove network based on default router')
      end
    else raise action
    end
  end

  def_multiprop :dataset do |action, str|
    case action
    when :add then ['add dataset', "set name=#{str}", 'end'].join("\n")
    when :rm then "remove dataset name=#{str}"
    else raise action
    end
  end

  def_multiprop :inherit do |action, str|
    case action
    when :add then ['add inherit-pkg-dir', "set dir=#{str}", 'end'].join("\n")
    when :rm then "remove inherit-pkg-dir dir=#{str}"
    else raise action
    end
  end

  def my_properties
    [:path, :iptype, :autoboot, :pool, :shares, :ip, :dataset, :inherit]
  end

  # Perform all of our configuration steps.
  def configure
    raise 'Path is required' unless @resource[:path]
    arr = ["create -b #{@resource[:create_args]}"]

    # Then perform all of our configuration steps.  It's annoying
    # that we need this much internal info on the resource.
    resource.properties.each do |property|
      next unless my_properties.include? property.name
      method = (property.name.to_s + '_conf').to_sym
      arr << send(method, @resource[property.name]) unless property.safe_insync?(properties[property.name])
    end
    setconfig(arr.join("\n"))
  end

  def destroy
    zonecfg :delete, '-F'
  end

  def add_cmd(cmd)
    @cmds = [] if @cmds.nil?
    @cmds << cmd
  end

  def exists?
    properties[:ensure] != :absent
  end

  # We cannot use the execpipe in util because the pipe is not opened in
  # read/write mode.
  def exec_cmd(var)
    # In bash, the exit value of the last command is the exit value of the
    # entire pipeline
    out = execute("echo \"#{var[:input]}\" | #{var[:cmd]}", failonfail: false, combine: true)
    st = $CHILD_STATUS.exitstatus
    { out: out, exit: st }
  end

  # Clear out the cached values.
  def flush
    return if @cmds.nil? || @cmds.empty?
    str = (@cmds << 'commit' << 'exit').join("\n")
    @cmds = []
    @property_hash.clear

    command = "#{command(:cfg)} -z #{@resource[:name]} -f -"
    r = exec_cmd(cmd: command, input: str)
    raise ArgumentError, _('Failed to apply configuration') if r[:exit] != 0 || r[:out] =~ %r{not allowed}
  end

  def install
    if @resource[:clone] # TODO: add support for "-s snapshot"
      zoneadm :clone, @resource[:clone]
    elsif @resource[:install_args]
      zoneadm :install, @resource[:install_args].split(' ')
    else
      zoneadm :install
    end
  end

  # Look up the current status.
  def properties
    if @property_hash.empty?
      @property_hash = status || {}
      if @property_hash.empty?
        @property_hash[:ensure] = :absent
      else
        @resource.class.validproperties.each do |name|
          @property_hash[name] ||= :absent
        end
      end
    end
    @property_hash.dup
  end

  # We need a way to test whether a zone is in process.  Our 'ensure'
  # property models the static states, but we need to handle the temporary ones.
  def processing?
    hash = status
    return false unless hash
    ['incomplete', 'ready', 'shutting_down'].include? hash[:ensure]
  end

  # Collect the configuration of the zone. The output looks like:
  # zonename: z1
  # zonepath: /export/z1
  # brand: native
  # autoboot: true
  # bootargs:
  # pool:
  # limitpriv:
  # scheduling-class:
  # ip-type: shared
  # hostid:
  # net:
  #         address: 192.168.1.1
  #         physical: eg0001
  #         defrouter not specified
  # net:
  #         address: 192.168.1.3
  #         physical: eg0002
  #         defrouter not specified
  #
  def getconfig
    output = zonecfg :info

    name = nil
    current = nil
    hash = {}
    output.split("\n").each do |line|
      case line
      when %r{^(\S+):\s*$}
        name = Regexp.last_match(1)
        current = nil # reset it
      when %r{^(\S+):\s*(\S+)$}
        hash[Regexp.last_match(1).to_sym] = Regexp.last_match(2)
      when %r{^\s+(\S+):\s*(.+)$}
        if name
          hash[name] ||= []
          unless current
            current = {}
            hash[name] << current
          end
          current[Regexp.last_match(1).to_sym] = Regexp.last_match(2)
        else
          err "Ignoring '#{line}'"
        end
      else
        debug "Ignoring zone output '#{line}'"
      end
    end

    hash
  end

  # Execute a configuration string.  Can't be private because it's called
  # by the properties.
  def setconfig(str)
    add_cmd str
  end

  # rubocop:disable Metrics/BlockNesting
  def start
    # Check the sysidcfg stuff
    cfg = @resource[:sysidcfg]
    if cfg
      fail 'Path is required' unless @resource[:path]
      zoneetc = File.join(@resource[:path], 'root', 'etc')
      sysidcfg = File.join(zoneetc, 'sysidcfg')

      # if the zone root isn't present "ready" the zone
      # which makes zoneadmd mount the zone root
      zoneadm :ready unless File.directory?(zoneetc)

      unless Puppet::FileSystem.exist?(sysidcfg)
        begin
          # For compatibility reasons use System encoding for this OS file
          # the manifest string is UTF-8 so this could result in conversion errors
          # which should propagate to users
          Puppet::FileSystem.open(sysidcfg, 0o600, "w:#{Encoding.default_external.name}") do |f|
            f.puts cfg
          end
        rescue => detail
          puts detail.stacktrace if Puppet[:debug]
          raise Puppet::Error, "Could not create sysidcfg: #{detail}", detail.backtrace
        end
      end
    end

    zoneadm :boot
  end
  # rubocop:enable Metrics/BlockNesting

  # Return a hash of the current status of this zone.
  def status
    begin
      output = adm '-z', @resource[:name], :list, '-p'
    rescue Puppet::ExecutionFailure
      return nil
    end

    main = self.class.line2hash(output.chomp)

    # Now add in the configuration information
    config_status.each do |name, value|
      main[name] = value
    end

    main
  end

  def ready
    zoneadm :ready
  end

  def stop
    zoneadm :halt
  end

  def unconfigure
    zonecfg :delete, '-F'
  end

  def uninstall
    zoneadm :uninstall, '-F'
  end

  private

  # Turn the results of getconfig into status information.
  def config_status
    config = getconfig
    result = {}

    result[:autoboot] = (config[:autoboot]) ? config[:autoboot].to_sym : :true
    result[:pool] = config[:pool]
    result[:shares] = config[:shares]
    dir = config['inherit-pkg-dir']
    if dir
      result[:inherit] = dir.map { |dirs| dirs[:dir] }
    end
    datasets = config['dataset']
    if datasets
      result[:dataset] = datasets.map { |dataset| dataset[:name] }
    end
    result[:iptype] = config[:'ip-type'] if config[:'ip-type']
    net = config['net']
    if net
      result[:ip] = net.map do |params|
        if params[:defrouter]
          "#{params[:physical]}:#{params[:address]}:#{params[:defrouter]}"
        elsif params[:address]
          "#{params[:physical]}:#{params[:address]}"
        else
          params[:physical]
        end
      end
    end

    result
  end

  def zoneadm(*cmd)
    adm('-z', @resource[:name], *cmd)
  rescue Puppet::ExecutionFailure => detail
    raise Puppet::Error, "Could not #{cmd[0]} zone: #{detail}", detail
  end

  def zonecfg(*cmd)
    # You apparently can't get the configuration of the global zone (strictly in solaris11)
    return '' if name == 'global'
    begin
      cfg('-z', name, *cmd)
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not #{cmd[0]} zone: #{detail}", detail
    end
  end
end
