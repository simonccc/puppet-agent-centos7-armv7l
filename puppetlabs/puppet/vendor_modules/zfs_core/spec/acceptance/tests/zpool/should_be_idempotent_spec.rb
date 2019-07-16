require 'spec_helper_acceptance'

RSpec.context 'ZPool: Should be Idempotent' do
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
    it 'creates an idempotent resource' do
      # ZPool: ensure create
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, disk=>'/ztstpool/dsk1' }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: idempotency - create
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, disk=>'/ztstpool/dsk1' }") do
        assert_no_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end
    end
  end
end
