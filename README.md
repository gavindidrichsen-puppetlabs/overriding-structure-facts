# overriding-structure-facts

## Context

The following test used to pass without throwing any informational warnings when using pdk 3.0.1:

```ruby
# frozen_string_literal: true

require 'spec_helper'

describe 'test_330::speed' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(networking:{interfaces: { eth0: { bindings: [{address: '10.10.10.10'},]}}}) }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
```

However, when using pdk 3.3.0, the following debug information is also output:

```ruby
Could not retrieve fact networking.fqdn
Could not retrieve fact networking.ip
.Could not retrieve fact networking.fqdn
Could not retrieve fact networking.ip
.Could not retrieve fact networking.fqdn
Could not retrieve fact networking.ip
```

The reason this is happening is that the `.merge()` will not actually inject a structured fact value but instead override the whole structured fact.

The solution is to use a more clever approach.  One option is to use a function override, which vox themselves developed.  This is explained below.

## Original issue `Could not retrieve fact networking...`

When overriding a fact in a test, e.g., `let(:facts) { os_facts.merge(networking:{interfaces: { eth0: { bindings: [{address: '10.10.10.10'},]}}}) }`, the `Could not retrieve fact networking....` occurs.  For example, 

```bash
root@rocky8-330 overriding-structure-facts (fix_to_override_structured_facts)$ git checkout original_observation
M       README.md
Switched to branch 'original_observation'
Your branch is up to date with 'origin/original_observation'.
root@rocky8-330 overriding-structure-facts (original_observation)$ cat spec/classes/speed_spec.rb 
# frozen_string_literal: true

require 'spec_helper'

describe 'test_330::speed' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(networking:{interfaces: { eth0: { bindings: [{address: '10.10.10.10'},]}}}) }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ pdk --version
3.3.0
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ 
root@rocky8-330 overriding-structure-facts (original_observation)$ pdk test unit
pdk (INFO): Using Ruby 3.2.5
pdk (INFO): Using Puppet 8.9.0
[✔] Preparing to run the unit tests.
/opt/puppetlabs/pdk/private/ruby/3.2.5/bin/ruby -I/root/.pdk/cache/ruby/3.2.0/gems/rspec-core-3.13.2/lib:/root/.pdk/cache/ruby/3.2.0/gems/rspec-support-3.13.1/lib /root/.pdk/cache/ruby/3.2.0/gems/rspec-core-3.13.2/exe/rspec --pattern spec/\{aliases,classes,defines,functions,hosts,integration,plans,tasks,type_aliases,types,unit\}/\*\*/\*_spec.rb --format progress
No facts were found in the FacterDB for Facter v4.5.1 on {"os.name"=>"RedHat", "os.release.full"=>"/^7/", "os.hardware"=>"x86_64"}, using v4.2.13 instead
No facts were found in the FacterDB for Facter v4.5.1 on {"os.name"=>"RedHat", "os.release.full"=>"/^8/", "os.hardware"=>"x86_64"}, using v4.5.2 instead
No facts were found in the FacterDB for Facter v4.5.1 on {"os.name"=>"RedHat", "os.release.full"=>"/^9/", "os.hardware"=>"x86_64"}, using v4.5.2 instead
Run options: exclude {:bolt=>true}
Could not retrieve fact networking.fqdn
Could not retrieve fact networking.ip
.Could not retrieve fact networking.fqdn
Could not retrieve fact networking.ip
.Could not retrieve fact networking.fqdn
Could not retrieve fact networking.ip
..

Coverage Report:

Total resources:   0
Touched resources: 0
Resource coverage: 100.00%


Finished in 0.41527 seconds (files took 0.98154 seconds to load)
4 examples, 0 failures

root@rocky8-330 overriding-structure-facts (original_observation)$ 
```

### The Solution override function.

The fix here is to add 2 override functions and adjust the test as illustrated in the PR <https://github.com/gavindidrichsen-puppetlabs/overriding-structure-facts/pull/1>.  

To see the update fix the output, run the following commands:

```bash
root@rocky8-330 overriding-structure-facts (original_observation)$ git checkout fix_to_override_structured_facts
M       README.md
Switched to branch 'fix_to_override_structured_facts'
Your branch is up to date with 'origin/fix_to_override_structured_facts'.
root@rocky8-330 overriding-structure-facts (fix_to_override_structured_facts)$ 

root@rocky8-330 overriding-structure-facts (fix_to_override_structured_facts)$ 
root@rocky8-330 overriding-structure-facts (fix_to_override_structured_facts)$ pdk test unit
pdk (INFO): Using Ruby 3.2.5
pdk (INFO): Using Puppet 8.9.0
[✔] Preparing to run the unit tests.
/opt/puppetlabs/pdk/private/ruby/3.2.5/bin/ruby -I/root/.pdk/cache/ruby/3.2.0/gems/rspec-core-3.13.2/lib:/root/.pdk/cache/ruby/3.2.0/gems/rspec-support-3.13.1/lib /root/.pdk/cache/ruby/3.2.0/gems/rspec-core-3.13.2/exe/rspec --pattern spec/\{aliases,classes,defines,functions,hosts,integration,plans,tasks,type_aliases,types,unit\}/\*\*/\*_spec.rb --format progress
No facts were found in the FacterDB for Facter v4.5.1 on {"os.name"=>"RedHat", "os.release.full"=>"/^7/", "os.hardware"=>"x86_64"}, using v4.2.13 instead
No facts were found in the FacterDB for Facter v4.5.1 on {"os.name"=>"RedHat", "os.release.full"=>"/^8/", "os.hardware"=>"x86_64"}, using v4.5.2 instead
No facts were found in the FacterDB for Facter v4.5.1 on {"os.name"=>"RedHat", "os.release.full"=>"/^9/", "os.hardware"=>"x86_64"}, using v4.5.2 instead
Run options: exclude {:bolt=>true}
....

Coverage Report:

Total resources:   0
Touched resources: 0
Resource coverage: 100.00%


Finished in 0.36417 seconds (files took 0.96797 seconds to load)
4 examples, 0 failures

root@rocky8-330 overriding-structure-facts (fix_to_override_structured_facts)$ 
```
