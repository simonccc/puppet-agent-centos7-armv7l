require 'spec_helper_acceptance'

RSpec.context 'ZFS: Basic Tests' do
  before(:all) do
    solaris_agents.each do |agent|
      # ZFS: cleanup
      zfs_clean agent

      # ZFS: setup
      zfs_setup agent

      # ZFS: ensure clean slate
      apply_manifest_on(agent, 'zfs { "tstpool/tstfs": ensure=>absent}')
    end
  end

  after(:all) do
    # ZFS: cleanup
    solaris_agents.each do |agent|
      zfs_clean agent
    end
  end

  solaris_agents.each do |agent|
    it 'can create and clean up an idempotent resource' do
      # ZFS: basic - ensure it is created
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present}') do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZFS: idempotence - create
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present}') do
        assert_no_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZFS: cleanup for next test
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>absent}') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end

    it 'can create and clean up a resource with a mount point' do
      # ZFS: create with a mount point
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present,  mountpoint=>"/ztstpool/mnt"}') do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZFS: change mount point and verify
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present,  mountpoint=>"/ztstpool/mnt2"}') do
        assert_match(%r{mountpoint changed '.ztstpool.mnt'.* to '.ztstpool.mnt2'}, @result.stdout, "err: #{agent}")
      end

      # ZFS: ensure can be removed
      apply_manifest_on(agent, 'zfs { "tstpool/tstfs": ensure=>absent}') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
