require 'spec_helper'

describe Puppet::Type.type(:zfs) do
  properties = [:ensure, :mountpoint, :compression, :copies, :quota, :reservation, :sharenfs, :snapdir]

  properties.each do |property|
    it "should have a #{property} property" do
      expect(described_class.attrclass(property).ancestors).to be_include(Puppet::Property)
    end
  end

  parameters = [:name]

  parameters.each do |parameter|
    it "should have a #{parameter} parameter" do
      expect(described_class.attrclass(parameter).ancestors).to be_include(Puppet::Parameter)
    end
  end

  it 'autorequires the containing zfs and the zpool' do
    zfs_provider = instance_double 'provider'
    allow(zfs_provider).to receive(:name).and_return(:zfs)
    allow(described_class).to receive(:defaultprovider) { zfs_provider }

    zpool_provider = instance_double 'provider'
    allow(zpool_provider).to receive(:name).and_return(:zpool)
    allow(Puppet::Type.type(:zpool)).to receive(:defaultprovider) { zpool_provider }

    foo_pool = Puppet::Type.type(:zpool).new(name: 'foo')

    foo_bar_zfs = described_class.new(name: 'foo/bar')
    foo_bar_baz_zfs = described_class.new(name: 'foo/bar/baz')
    foo_bar_baz_buz_zfs = described_class.new(name: 'foo/bar/baz/buz')

    Puppet::Resource::Catalog.new :testing do |conf|
      [foo_pool, foo_bar_zfs, foo_bar_baz_zfs, foo_bar_baz_buz_zfs].each { |resource| conf.add_resource resource }
    end

    req = foo_bar_baz_buz_zfs.autorequire.map { |edge| edge.source.ref }

    [foo_pool.ref, foo_bar_zfs.ref, foo_bar_baz_zfs.ref].each { |ref| expect(req.include?(ref)).to eq(true) }
  end
end
