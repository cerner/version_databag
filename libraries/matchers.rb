if defined?(ChefSpec)
  def resolve_version_databag_attrib_interpolate(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:version_databag_attrib_interpolate, :resolve, resource_name)
  end
end
