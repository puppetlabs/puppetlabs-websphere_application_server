require 'spec_helper'

describe Puppet::Type.type(:websphere_jdbc_datasource) do
  it 'requires the cell parameter ' do
    expect {
      described_class.new(name: 'Puppet Test',
                          scope: 'cell',
                          profile_base: '/opt/IBM/WebSphere/AppServer/profiles')
    }.to raise_error(Puppet::Error, %r{cell})
  end
end
