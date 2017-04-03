# version_databag

[![Cookbook Version](https://img.shields.io/cookbook/v/version_databag.svg)](https://community.opscode.com/cookbooks/version_databag)
[![Build Status](https://travis-ci.org/cerner/version_databag.svg?branch=master)](https://travis-ci.org/cerner/version_databag)

A Chef cookbook that provides functionality to dynamically retrieve artifact versioning information from a configurable Chef data bag. Note, this cookbook requires a minimum version of Chef **12.3.0** to be able to be used.

Attributes
----------

All attributes are under the scope of the cookbook name: "version_databag"

|key|Type|Description|Default|
|---|---|---|---|
|version_type|String|The type of version to retrieve from the databag|"release"|
|databag|String|The databag containing the version data|nil|
|databag_item|String|The databag item containing the version data|nil|
|artifact_override_map|Hash|A hash of artifact_name => version_type to override the base version_type for the specified artifact|nil|
|artifact_specifications|Array|An array of hashes containing the artifact specification. The artifact specification includes **artifact_name**, **attribute_path**, and optionally *value_substitution*|nil|
|delimiter|String|A one or two character String of a delimiter when using value substitution|"<>"|

Recipes
-------

**default** - Accepts an array of hashes containing artifact_name, attribute_path, and optionally a value_substitutions. This recipe calls the attrib_interpolate provider for each artifact specification in the array assuming they are defined along with the location of the data bag and data bag item. If an individual hash does not contain both required values (artifact_name and attribute path), that hash will be skipped with a log message of the index of the offending hash in the array.

Example recipe call with an artifact specification and a value substitution:

```ruby
'version_databag' => {
  'databag' => 'Artifacts',
  'databag_item' => 'versions',
  'artifact_specifications' => [
    {
      'artifact_name' => 'Artifact1',
      'attribute_path' => "['application_cookbook']['version']"
    },
    {
      'artifact_name' => 'Artifact2',
      'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/<Artifact2>/README.md",
      'attribute_path' => "['reference_git']['item']"
    }
  ]
}
```

Example of the sample Artifacts/versions data bag that contains the versions referenced above:

```json

{
  "id": "versions",
  "Artifact1": {
    "release": "3.17",
    "snapshot": "3.18-SNAPSHOT"
  },
  "Artifact2": {
    "release": "1.0"
  },
  "Artifact3": {
    "release": "1.3",
    "snapshot": "1.4.SNAPSHOT"
  }
}
```

After the execution of the above recipe, the following code would contain these results:

```ruby
node['application_cookbook']['version']
#=> 3.17

node['reference_git']['item']
#=> https://raw.githubusercontent.com/cerner/version_databag/1.0/README.md
```

Providers
---------

**attrib_interpolate** - Handles the logic to derive an artifact version from a given artifact_name from the defined data bag and populates the corresponding attribute_path. Alternatively, the provider can substitute the version into a string using the delimited artifact name as a value substitution. The provider is available to pass dynamically named artifacts or artifacts defined in a wrapper cookbook's attributes. **Note:** the provider call should be executed in Chef's "compile phase" to allow the attributes to be available as downstream cookbooks execute during the "execution phase".

*Examples below reference the same Artifacts/version data bag previously mentioned.*

**Example 1:**  Assign the artifact version to the attribute_path through a calling cookbook with an artifact_override_map

Configured attributes:

```ruby
default_attributes 'application_cookbook' => {
  'artifacts' => ['Artifact1', 'Artifact3']
  },
  "version_databag" => {
  	"databag" => "Artifacts",
  	"databag_item" => "versions",
    "artifact_override_map" => {
      "Artifact3" => "snapshot"
    }
  }
```

Cookbook code:

```
node['application_cookbook']['artifacts'].each do |artifact|
  version_databag_attrib_interpolate "Determine the version of #{artifact}" do
    artifact_name artifact
    attribute_path "['application_cookbook']['#{artifact}']['version']"
    action :nothing
  end.run_action(:resolve)
end
```

Output:

```ruby
node['application_cookbook']['Artifact1']['version']
#=> 3.17

node['application_cookbook']['Artifact3']['version']
#=> 1.4.SNAPSHOT
```

**Example 2:**  Substitute the version into a value substitution string with a custom delimiter

Configured attributes:

```ruby
default_attributes 'version_databag' => {
  'databag' => 'Artifacts',
  'databag_item' => 'versions',
  'delimiter' => '|'
}
```

Cookbook code:

```ruby
version_databag_attrib_interpolate "Determine artifact version git value substitution" do
  artifact_name 'Artifact2'
  attribute_path "['reference_git']['item']"
  value_substitution "https://raw.githubusercontent.com/cerner/version_databag/|Artifact2|/README.md"
  action :nothing
end.run_action(:resolve)
```

Output:

```ruby
node['reference_git']['item']
#=> https://raw.githubusercontent.com/cerner/version_databag/1.0/README.md
```


Testing
-------

### How to run tests

To run the tests for this cookbook you must install [ChefDK](https://downloads.chef.io/chef-dk/).

The unit tests are written with [rspec](http://rspec.info/) and [chefspec](https://github.com/sethvargo/chefspec).
They can be run with `chef exec rspec`.

The lint testing uses [Foodcritic](http://www.foodcritic.io/) and can be run with `chef exec foodcritic . -f any`.

Contributing
------------

See [CONTRIBUTING.md](CONTRIBUTING.md)

LICENSE
-------

Copyright 2015 Cerner Innovation, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0) Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
