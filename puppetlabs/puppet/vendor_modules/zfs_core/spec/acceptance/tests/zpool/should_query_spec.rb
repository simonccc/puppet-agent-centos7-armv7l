require 'spec_helper_acceptance'

RSpec.context 'ZPool: Should Query' do
  before(:all) do
    # ZPool: setup
    solaris_agents.each do |agent|
      zpool_setup agent
    end
  end

  after(:all) do
    # ZPool: cleanup
    solaris_agents.each do |agent|
      zpool_clean agent
    end
  end

  solaris_agents.each do |agent|
    it 'queries both manages and unmanages zpool resources' do
      # ZPool: ensure create
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, disk=>'/ztstpool/dsk1' }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: query one
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{ensure *=> *'present'}, @result.stdout, "err: #{agent}")
      end

      # ZPool: query all
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{tstpool'}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
