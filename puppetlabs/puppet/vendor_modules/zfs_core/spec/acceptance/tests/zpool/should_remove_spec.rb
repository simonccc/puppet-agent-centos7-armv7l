require 'spec_helper_acceptance'

RSpec.context 'ZPool: Should Remove' do
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
    it 'removes a specified resource' do
      # ZPool: create
      on(agent, 'zpool create tstpool /ztstpool/dsk1')
      on(agent, 'zpool list') do
        assert_match(%r{tstpool}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove
      apply_manifest_on(agent, 'zpool{ tstpool: ensure=>absent }') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
      on(agent, 'zpool list') do
        assert_no_match(%r{tstpool}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
