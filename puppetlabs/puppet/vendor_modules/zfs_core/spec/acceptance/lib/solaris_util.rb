OPTS = { poolpath: '/ztstpool', pool: 'tstpool', fs: 'tstfs' }.freeze

def zfs_clean(agent, o = {})
  o = OPTS.merge(o)
  on agent, 'zfs destroy -f -r %s/%s ||:' % [o[:pool], o[:fs]]
  on agent, 'zpool destroy -f %s ||:' % o[:pool]
  on agent, 'rm -rf %s ||:' % o[:poolpath]
end

def zfs_setup(agent, o = {})
  o = OPTS.merge(o)
  on agent, 'mkdir -p %s/mnt' % o[:poolpath]
  on agent, 'mkdir -p %s/mnt2' % o[:poolpath]
  on agent, 'mkfile 64m %s/dsk' % o[:poolpath]
  on agent, 'zpool create %s %s/dsk' % [o[:pool], o[:poolpath]]
end

def zpool_clean(agent, o = {})
  o = OPTS.merge(o)
  on agent, 'zpool destroy -f %s ||:' % o[:pool]
  on agent, 'rm -rf %s ||:' % o[:poolpath]
end

def zpool_setup(agent, o = {})
  o = OPTS.merge(o)
  on agent, 'mkdir -p %s/mnt||:' % o[:poolpath]
  on agent, 'mkfile 100m %s/dsk1 %s/dsk2 %s/dsk3 %s/dsk5 ||:' % ([o[:poolpath]] * 4)
  on agent, 'mkfile 50m %s/dsk4 ||:' % o[:poolpath]
end
