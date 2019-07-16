require 'spec_helper_acceptance'

RSpec.context 'ZFS: Should Query' do
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
    it 'can query and report both managed and unmanaged resources' do
      # ZFS: basic - ensure it is created
      apply_manifest_on(agent, 'zfs {"tstpool/tstfs": ensure=>present}') do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # query one.
      on(agent, 'puppet resource zfs tstpool/tstfs') do
        assert_match(%r{ensure *=> *'present'}, @result.stdout, "err: #{agent}")
      end

      # query all.
      on(agent, 'puppet resource zfs') do
        assert_match(%r{tstpool.tstfs}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
