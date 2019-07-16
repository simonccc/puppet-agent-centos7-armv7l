require 'spec_helper_acceptance'

RSpec.context 'ZFS: Should be Idempotent' do
  before(:all) do
    # ZFS: setup
    solaris_agents.each do |agent|
      zfs_setup agent
    end
  end

  after(:all) do
    # ZFS: cleanup
    solaris_agents.each do |agent|
      zfs_clean agent
    end
  end

  solaris_agents.each do |agent|
    it 'creates and updates a resource in an idempotent way' do
      # ZFS: create with a mount point
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present,  mountpoint=>"/ztstpool/mnt"}') do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZFS: idempotence - create
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present}') do
        assert_no_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZFS: change mount point and verify
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present,  mountpoint=>"/ztstpool/mnt2"}') do
        assert_match(%r{mountpoint changed '.ztstpool.mnt'.* to '.ztstpool.mnt2'}, @result.stdout, "err: #{agent}")
      end

      # ZFS: change mount point and verify idempotence
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present,  mountpoint=>"/ztstpool/mnt2"}') do
        assert_no_match(%r{changed}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
