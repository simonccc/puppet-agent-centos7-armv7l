require 'spec_helper_acceptance'

RSpec.context 'ZPool: Basic Tests' do
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
    it 'can create an idempotent zpool resource' do
      # ZPool: create zpool disk
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, disk=>'/ztstpool/dsk1' }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: zpool should be idempotent
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, disk=>'/ztstpool/dsk1' }") do
        assert_no_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove zpool
      apply_manifest_on(agent, 'zpool{ tstpool: ensure=>absent }') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end

    it 'can create a zpool resource with a disk array' do
      # ZPool: create zpool with a disk array
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, disk=>['/ztstpool/dsk1','/ztstpool/dsk2'] }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify disk array was created
      on agent, 'zpool list -H' do
        assert_match(%r{tstpool}, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify puppet resource reports on the disk array
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{ensure => 'present'}, @result.stdout, "err: #{agent}")
        assert_match(%r{disk +=> .'.+dsk1 .+dsk2'.}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove zpool in preparation for mirror tests
      apply_manifest_on(agent, 'zpool{ tstpool: ensure=>absent }') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end

    it 'can create a mirrored zpool resource with 3 virtual devices' do
      # ZPool: create mirrored zpool with 3 virtual devices
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, mirror=>['/ztstpool/dsk1 /ztstpool/dsk2 /ztstpool/dsk3'] }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify mirrors were created
      on agent, 'zpool status -v tstpool' do
        # 	NAME                STATE     READ WRITE CKSUM
        # tstpool             ONLINE       0     0     0
        #   mirror-0          ONLINE       0     0     0
        #     /ztstpool/dsk1  ONLINE       0     0     0
        #     /ztstpool/dsk2  ONLINE       0     0     0
        #     /ztstpool/dsk3  ONLINE       0     0     0
        assert_match(%r{tstpool.*\n\s+mirror.*\n\s*/ztstpool/dsk1.*\n\s*/ztstpool/dsk2.*\n\s*/ztstpool/dsk3}m, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify puppet resource reports on the mirror
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{ensure => 'present'}, @result.stdout, "err: #{agent}")
        assert_match(%r{mirror => \['/ztstpool/dsk1 /ztstpool/dsk2 /ztstpool/dsk3'\]}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove zpool in preparation for multiple mirrors
      apply_manifest_on(agent, 'zpool{ tstpool: ensure=>absent }') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end

    it 'can create two mirrored zpools each with two virtual devices' do
      # ZPool: create 2 mirrored zpools each with 2 virtual devices
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, mirror=>['/ztstpool/dsk1 /ztstpool/dsk2', '/ztstpool/dsk3 /ztstpool/dsk5'] }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify both mirrors were created
      on agent, 'zpool status -v tstpool' do
        # 	NAME                STATE     READ WRITE CKSUM
        # tstpool             ONLINE       0     0     0
        #   mirror-0          ONLINE       0     0     0
        #     /ztstpool/dsk1  ONLINE       0     0     0
        #     /ztstpool/dsk2  ONLINE       0     0     0
        #   mirror-1          ONLINE       0     0     0
        #     /ztstpool/dsk3  ONLINE       0     0     0
        #     /ztstpool/dsk5  ONLINE       0     0     0
        assert_match(%r{tstpool.*\n\s+mirror.*\n\s*/ztstpool/dsk1.*\n\s*/ztstpool/dsk2.*\n\s+mirror.*\n\s*/ztstpool\/dsk3.*\n\s*/ztstpool/dsk5}m, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify puppet resource reports on both mirrors
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{ensure => 'present'}, @result.stdout, "err: #{agent}")
        assert_match(%r{mirror => \['/ztstpool/dsk1 /ztstpool/dsk2', '/ztstpool/dsk3 /ztstpool/dsk5'\]}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove zpool in preparation for raidz test
      apply_manifest_on(agent, 'zpool{ tstpool: ensure=>absent }') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end

    it 'can create raidz pool consisting of three virtual devices' do
      # ZPool: create raidz pool consisting of 3 virtual devices
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, raidz=>['/ztstpool/dsk1 /ztstpool/dsk2 /ztstpool/dsk3'] }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify raidz pool was created
      on agent, 'zpool status -v tstpool' do
        # 	NAME                STATE     READ WRITE CKSUM
        # tstpool             ONLINE       0     0     0
        #   raidz1-0          ONLINE       0     0     0
        #     /ztstpool/dsk1  ONLINE       0     0     0
        #     /ztstpool/dsk2  ONLINE       0     0     0
        #     /ztstpool/dsk3  ONLINE       0     0     0
        assert_match(%r{tstpool.*\n\s+raidz.*\n\s*/ztstpool/dsk1.*\n\s*/ztstpool/dsk2.*\n\s*/ztstpool/dsk3}m, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify puppet reports on the raidz pool
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{ensure => 'present'}, @result.stdout, "err: #{agent}")
        assert_match(%r{raidz  => \['/ztstpool/dsk1 /ztstpool/dsk2 /ztstpool/dsk3'\]}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove zpool in preparation for multiple raidz pools
      apply_manifest_on(agent, 'zpool{ tstpool: ensure=>absent }') do
        assert_match(%r{ensure: removed}, @result.stdout, "err: #{agent}")
      end
    end

    it 'can create two raidz zpools each with two virtual devices' do
      # ZPool: create 2 mirrored zpools each with 2 virtual devices
      apply_manifest_on(agent, "zpool{ tstpool: ensure=>present, raidz=>['/ztstpool/dsk1 /ztstpool/dsk2', '/ztstpool/dsk3 /ztstpool/dsk5'] }") do
        assert_match(%r{ensure: created}, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify both raidz were created
      on agent, 'zpool status -v tstpool' do
        # 	NAME                STATE     READ WRITE CKSUM
        # tstpool             ONLINE       0     0     0
        #   raidz1-0          ONLINE       0     0     0
        #     /ztstpool/dsk1  ONLINE       0     0     0
        #     /ztstpool/dsk2  ONLINE       0     0     0
        #   raidz1-1          ONLINE       0     0     0
        #     /ztstpool/dsk3  ONLINE       0     0     0
        #     /ztstpool/dsk5  ONLINE       0     0     0
        assert_match(%r{tstpool.*\n\s+raidz.*\n\s*/ztstpool/dsk1.*\n\s*/ztstpool/dsk2.*\n\s+raidz.*\n\s*/ztstpool/dsk3.*\n\s*/ztstpool/dsk5}m, @result.stdout, "err: #{agent}")
      end

      # ZPool: verify puppet resource reports on both raidz
      on(agent, puppet('resource zpool tstpool')) do
        assert_match(%r{ensure => 'present'}, @result.stdout, "err: #{agent}")
        assert_match(%r{raidz  => \['/ztstpool/dsk1 /ztstpool/dsk2', '/ztstpool/dsk3 /ztstpool/dsk5'\]}, @result.stdout, "err: #{agent}")
      end

      # ZPool: remove
      apply_manifest_on(agent, 'zpool { tstpool: ensure => absent }') do
        assert_match(%(ensure: removed), @result.stdout, "err: #{agent}")
      end
    end
  end
end
