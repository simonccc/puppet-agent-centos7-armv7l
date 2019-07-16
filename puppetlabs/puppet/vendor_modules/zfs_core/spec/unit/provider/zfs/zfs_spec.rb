require 'spec_helper'

describe Puppet::Type.type(:zfs).provider(:zfs) do
  let(:name) { 'myzfs' }
  let(:zfs) { '/usr/sbin/zfs' }

  let(:resource) do
    Puppet::Type.type(:zfs).new(name: name, provider: :zfs)
  end

  let(:provider) { resource.provider }

  before(:each) do
    allow(provider.class).to receive(:which).with('zfs') { zfs }
  end

  context '.instances' do
    it 'has an instances method' do
      expect(provider.class).to respond_to(:instances)
    end

    it 'lists instances' do
      allow(provider.class).to receive(:zfs).with(:list, '-H') { File.read(my_fixture('zfs-list.out')) }
      instances = provider.class.instances.map { |p| { name: p.get(:name), ensure: p.get(:ensure) } }
      expect(instances.size).to eq(2)
      expect(instances[0]).to eq(name: 'rpool', ensure: :present)
      expect(instances[1]).to eq(name: 'rpool/ROOT', ensure: :present)
    end
  end

  context '#add_properties' do
    it 'returns an array of properties' do
      resource[:mountpoint] = '/foo'

      expect(provider.add_properties).to eq(['-o', 'mountpoint=/foo'])
    end

    it 'returns an empty array' do
      expect(provider.add_properties).to eq([])
    end
  end

  context '#create' do
    it 'executes zfs create' do
      expect(provider).to receive(:zfs).with(:create, name)

      provider.create
    end

    Puppet::Type.type(:zfs).validproperties.each do |prop|
      next if [:ensure, :volsize].include?(prop)
      it "should include property #{prop}" do
        resource[prop] = prop

        expect(provider).to receive(:zfs).with(:create, '-o', "#{prop}=#{prop}", name)

        provider.create
      end
    end

    it 'uses -V for the volsize property' do
      resource[:volsize] = '10'
      expect(provider).to receive(:zfs).with(:create, '-V', '10', name)
      provider.create
    end
  end

  context '#destroy' do
    it 'executes zfs destroy' do
      expect(provider).to receive(:zfs).with(:destroy, name)

      provider.destroy
    end
  end

  context '#exists?' do
    it 'returns true if the resource exists' do
      # return stuff because we have to slice and dice it
      expect(provider).to receive(:zfs).with(:list, name)

      expect(provider).to be_exists
    end

    it "returns false if returned values don't match the name" do
      expect(provider).to receive(:zfs).with(:list, name).and_raise(Puppet::ExecutionFailure, 'Failed')

      expect(provider).not_to be_exists
    end
  end

  describe 'zfs properties' do
    [:aclinherit, :aclmode, :atime, :canmount, :checksum,
     :compression, :copies, :dedup, :devices, :exec, :logbias,
     :mountpoint, :nbmand,  :primarycache, :quota, :readonly,
     :recordsize, :refquota, :refreservation, :reservation,
     :secondarycache, :setuid, :shareiscsi, :sharenfs, :sharesmb,
     :snapdir, :version, :volsize, :vscan, :xattr].each do |prop|
      it "should get #{prop}" do
        expect(provider).to receive(:zfs).with(:get, '-H', '-o', 'value', prop, name).and_return("value\n")

        expect(provider.send(prop)).to eq('value')
      end

      it "should set #{prop}=value" do
        expect(provider).to receive(:zfs).with(:set, "#{prop}=value", name)

        provider.send("#{prop}=", 'value')
      end
    end
  end
  describe 'zoned' do
    context 'on FreeBSD' do
      before(:each) do
        allow(Facter).to receive(:value).with(:operatingsystem).and_return('FreeBSD')
      end
      it "gets 'jailed' property" do
        expect(provider).to receive(:zfs).with(:get, '-H', '-o', 'value', :jailed, name).and_return("value\n")
        expect(provider.send('zoned')).to eq('value')
      end

      it 'sets jalied=value' do
        expect(provider).to receive(:zfs).with(:set, 'jailed=value', name)
        provider.send('zoned=', 'value')
      end
    end

    context 'when not running FreeBSD' do
      before(:each) do
        allow(Facter).to receive(:value).with(:operatingsystem).and_return('Solaris')
      end
      it "gets 'zoned' property" do
        expect(provider).to receive(:zfs).with(:get, '-H', '-o', 'value', :zoned, name).and_return("value\n")
        expect(provider.send('zoned')).to eq('value')
      end

      it 'sets zoned=value' do
        expect(provider).to receive(:zfs).with(:set, 'zoned=value', name)
        provider.send('zoned=', 'value')
      end
    end
  end
  describe 'acltype' do
    context 'when available' do
      it "gets 'acltype' property" do
        expect(provider).to receive(:zfs).with(:get, '-H', '-o', 'value', :acltype, name).and_return("value\n")
        expect(provider.send('acltype')).to eq('value')
      end
      it 'sets acltype=value' do
        expect(provider).to receive(:zfs).with(:set, 'acltype=value', name)
        provider.send('acltype=', 'value')
      end
    end

    context 'when not available' do
      it "gets '-' for the acltype property" do
        expect(provider).to receive(:zfs).with(:get, '-H', '-o', 'value', :acltype, name).and_raise(RuntimeError, 'not valid')
        expect(provider.send('acltype')).to eq('-')
      end
      it 'does not error out when trying to set acltype' do
        expect(provider).to receive(:zfs).with(:set, 'acltype=value', name).and_raise(RuntimeError, 'not valid')
        expect { provider.send('acltype=', 'value') }.not_to raise_error
      end
    end
  end
end
