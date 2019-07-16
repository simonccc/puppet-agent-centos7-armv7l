Puppet::Type.type(:zpool).provide(:zpool) do
  desc 'Provider for zpool.'

  commands zpool: 'zpool'

  # NAME    SIZE  ALLOC   FREE    CAP  HEALTH  ALTROOT
  def self.instances
    zpool(:list, '-H').split("\n").map do |line|
      name, _size, _alloc, _free, _cap, _health, _altroot = line.split(%r{\s+})
      new(name: name, ensure: :present)
    end
  end

  def process_zpool_data(pool_array)
    if pool_array == []
      return Hash.new(:absent)
    end
    # get the name and get rid of it
    pool = {}
    pool[:pool] = pool_array[0]
    pool_array.shift

    tmp = []

    # order matters here :(
    pool_array.reverse_each do |value|
      sym = nil
      case value
      when 'spares'
        sym = :spare
      when 'logs'
        sym = :log
      when %r{^mirror|^raidz1|^raidz2}
        sym = (value =~ %r{^mirror}) ? :mirror : :raidz
        pool[:raid_parity] = 'raidz2' if value =~ %r{^raidz2}
      else
        tmp << value
        sym = :disk if value == pool_array.first
      end

      if sym
        pool[sym] = (pool[sym]) ? pool[sym].unshift(tmp.reverse.join(' ')) : [tmp.reverse.join(' ')]
        tmp.clear
      end
    end

    pool
  end

  # rubocop:disable Style/AccessorMethodName
  # rubocop:disable Style/NumericPredicate
  def get_pool_data
    # https://docs.oracle.com/cd/E19082-01/817-2271/gbcve/index.html
    # we could also use zpool iostat -v mypool for a (little bit) cleaner output
    out = execute("zpool status #{@resource[:pool]}", failonfail: false, combine: false)
    zpool_data = out.lines.select { |line| line.index("\t") == 0 }.map { |l| l.strip.split("\s")[0] }
    zpool_data.shift
    zpool_data
  end

  def current_pool
    @current_pool = process_zpool_data(get_pool_data) unless defined?(@current_pool) && @current_pool
    @current_pool
  end

  def flush
    @current_pool = nil
  end

  # Adds log and spare
  def build_named(name)
    prop = @resource[name.to_sym]
    if prop
      [name] + prop.map { |p| p.split(' ') }.flatten
    else
      []
    end
  end

  # query for parity and set the right string
  def raidzarity
    (@resource[:raid_parity]) ? @resource[:raid_parity] : 'raidz1'
  end

  # handle mirror or raid
  def handle_multi_arrays(prefix, array)
    array.map { |a| [prefix] + a.split(' ') }.flatten
  end

  # builds up the vdevs for create command
  def build_vdevs
    disk = @resource[:disk]
    mirror = @resource[:mirror]
    raidz = @resource[:raidz]

    if disk
      disk.map { |d| d.split(' ') }.flatten
    elsif mirror
      handle_multi_arrays('mirror', mirror)
    elsif raidz
      handle_multi_arrays(raidzarity, raidz)
    end
  end

  def create
    zpool(*([:create, @resource[:pool]] + build_vdevs + build_named('spare') + build_named('log')))
  end

  def destroy
    zpool :destroy, @resource[:pool]
  end

  def exists?
    if current_pool[:pool] == :absent
      false
    else
      true
    end
  end

  [:disk, :mirror, :raidz, :log, :spare].each do |field|
    define_method(field) do
      current_pool[field]
    end

    # rubocop:disable Style/SignalException
    define_method(field.to_s + '=') do |should|
      fail "zpool #{field} can't be changed. should be #{should}, currently is #{current_pool[field]}"
    end
  end
end
