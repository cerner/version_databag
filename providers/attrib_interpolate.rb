def whyrun_supported?
  true
end

use_inline_resources

action :resolve do
  artifact_name = @new_resource.artifact_name
  attribute_path = @new_resource.attribute_path
  value_substitution = @new_resource.value_substitution
  data_bag_name = @new_resource.data_bag_name
  data_bag_item_name = @new_resource.data_bag_item_name

  version_value = get_version(artifact_name, data_bag_name, data_bag_item_name)

  if value_substitution
    version_value = substitute_value(value_substitution, artifact_name, version_value)
  end

  set_attribute(attribute_path, version_value)
end

# Gets the version for a given artifact_name from the given databag
# +artifact_name+:: The name of the artifact
# +data_bag_name+:: The name of the data bag folder
# +data_bag_item_name+:: The name of the data bag json
def get_version(artifact_name, data_bag_name, data_bag_item_name)
  versions_data_bag = data_bag_item(data_bag_name, data_bag_item_name)
  version_info = versions_data_bag[artifact_name]
  raise "Data bag #{data_bag_name}/#{data_bag_item_name} does not contain an entry for #{artifact_name}" if !version_info

  version_type = node['version_databag']['version_type']
  artifact_override_map = node['version_databag']['artifact_override_map']
  if artifact_override_map && artifact_override_map[artifact_name]
    version_type = artifact_override_map[artifact_name]
  end

  raise "version_type #{version_type} is missing for #{artifact_name}" if !version_info.include?(version_type)
  version_info[version_type]
end

# Substitutes the delimited artifact_name with the version_value in the value_substitution.
# If no match is found for the criteria, then an exception will be raised.
# +value_substitution+:: The string to perform version substitution on
# +artifact_name+:: The name of the artifact
# +version_value+:: The artifact version
def substitute_value(value_substitution, artifact_name, version_value)
  delimiter = node['version_databag']['delimiter']
  raise "['version_databag']['delimiter'] must be one or two characters to delimit the artifact_name" unless
        delimiter && delimiter.size > 0 && delimiter.size <= 2
  if delimiter.size == 1
    delimiter = delimiter + delimiter
  end
  raise "The delimited artifact_name must be included in the value substitution: #{delimiter[0]}#{artifact_name}#{delimiter[1]}" unless
        value_substitution["#{delimiter[0]}#{artifact_name}#{delimiter[1]}"]

  value_substitution.gsub("#{delimiter[0]}#{artifact_name}#{delimiter[1]}", version_value)
end

# Sets the given attribute_path to the version_value if the path isn't already specified
# +attribute_path+:: The path of the attribute to set
# +version_value+:: The artifact version derived value
def set_attribute(attribute_path, attribute_value)
  begin
    attribute_path_value = eval('node' + attribute_path)
  rescue NoMethodError
    # if the beginning of the attribute path not yet defined, this rescue is needed
    # to prevent an exception while attempting to retrieve the value on the node
  end
  if !attribute_path_value
    eval('node.default' + attribute_path + ' = attribute_value')
  end
end
