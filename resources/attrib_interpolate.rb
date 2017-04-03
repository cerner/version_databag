
actions :resolve
default_action :resolve

attribute :attribute_path, kind_of: String, required: true
attribute :artifact_name, kind_of: String, required: true
attribute :value_substitution, kind_of: String, default: nil
attribute :data_bag_name, kind_of: String, default: lazy {node['version_databag']['databag']}
attribute :data_bag_item_name, kind_of: String, default: lazy {node['version_databag']['databag_item']}
