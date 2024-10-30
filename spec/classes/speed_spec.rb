# frozen_string_literal: true

require 'spec_helper'

describe 'test_330::speed' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { override_facts(os_facts, networking:{interfaces: { eth0: { bindings: [{address: '10.10.10.10'},]}}}) }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
