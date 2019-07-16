require 'spec_helper_acceptance'

RSpec.context 'ZFS: Should Create' do
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
    it 'creates a zfs resource' do
      # ZFS: ensure it is created
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present}') do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # verify
      on(agent, 'zfs list') do
        assert_match(%r{tstpool.tstfs}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
