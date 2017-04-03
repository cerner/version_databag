#This recipe calls the artifact_spec lwrp to determine default versions or value substitutions for a given array.

if node['version_databag']['artifact_specifications'] && node['version_databag']['databag'] && node['version_databag']['databag_item']
  node['version_databag']['artifact_specifications'].each_with_index do |artifact_spec, index|
    if artifact_spec['artifact_name'].nil? || artifact_spec['attribute_path'].nil?
      log "Both artfact_name and attribute_path must be defined for ['version_databag']['artifact_specifications'][#{index}]" do
        level :warn
      end
    else
      provider_name = "Determine version for #{artifact_spec['artifact_name']} at #{artifact_spec['attribute_path']}"
      version_databag_attrib_interpolate provider_name do
        artifact_name artifact_spec['artifact_name']
        attribute_path artifact_spec['attribute_path']
        value_substitution artifact_spec['value_substitution']
        action :nothing
      end.run_action(:resolve)
    end
  end
else
  ['artifact_specifications', 'databag', 'databag_item'].each do |key|
    log "Need to define ['version_databag']['#{key}']" do
      level :warn
      only_if { node['version_databag'][key].nil? }
    end
  end
end
