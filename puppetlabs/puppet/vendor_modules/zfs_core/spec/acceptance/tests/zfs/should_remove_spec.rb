require 'spec_helper_acceptance'

RSpec.context 'ZFS: Should Remove' do
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
    it 'can remove resources' do
      # ZFS: create
      on agent, 'zfs create tstpool/tstfs'

      # ZFS: ensure can be removed.
      apply_manifest_on(agent, 'zfs { "tstpool/tstfs": ensure=>absent}') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
