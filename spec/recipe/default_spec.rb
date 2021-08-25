require 'spec_helper'

describe 'version_databag::default' do
  let(:runner) { ChefSpec::SoloRunner.new }
  let(:chef_run) {runner.converge(described_recipe)}

  let(:databag) {'Artifacts'}
  let(:databag_item) {'versions'}

  let(:set_databag_attributes) do
    runner.node.override['version_databag'] = {
      'databag' => databag,
      'databag_item' => databag_item
    }
  end

  context 'when no attributes are set' do
    it 'only logs warnings' do
      ['artifact_specifications', 'databag', 'databag_item'].each do |key|
        expect(chef_run).to write_log("Need to define ['version_databag']['#{key}']").with(level: :warn)
      end
    end
  end

  context 'when artifact_specifications are set incorrectly' do
    it 'only logs warnings' do
      set_databag_attributes
      artifact_specifications = [
        {
          'artifact_name' => 'Artifact1',
        },
        {
          'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/<Artifact2>/README.md",
          'attribute_path' => "['reference_git']['item']"
        }
      ]
      runner.node.override['version_databag']['artifact_specifications'] = artifact_specifications

      artifact_specifications.each_with_index do |artifact_spec, index|
        expect(chef_run).to write_log(
          "Both artfact_name and attribute_path must be defined for ['version_databag']['artifact_specifications'][#{index}]"
        ).with(level: :warn)
      end
    end
  end

  context 'when attributes are correct' do
    it 'calls the provider' do
      set_databag_attributes
      artifact_specifications = [
        {
          'artifact_name' => 'Artifact2',
          'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/<Artifact2>/README.md",
          'attribute_path' => "['reference_git']['item']"
        }
      ]
      runner.node.override['version_databag']['artifact_specifications'] = artifact_specifications

      artifact_specifications.each do |artifact_spec|
        expect(chef_run).to resolve_version_databag_attrib_interpolate(
          "Determine version for #{artifact_spec['artifact_name']} at #{artifact_spec['attribute_path']}"
          ).with(
            attribute_path: "['reference_git']['item']",
            artifact_name: 'Artifact2',
            value_substitution: "https://raw.githubusercontent.com/cerner/version_databag/<Artifact2>/README.md",
            data_bag_name: databag,
            data_bag_item_name: databag_item
          ).at_compile_time
      end
    end
  end
end
