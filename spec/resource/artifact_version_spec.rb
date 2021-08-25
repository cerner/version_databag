require 'spec_helper'

describe 'version_databag::attrib_interpolate' do
  let(:runner) do
    ChefSpec::SoloRunner.new(step_into) do |node|
      node.override['version_databag']['databag'] = databag
      node.override['version_databag']['databag_item'] = databag_item
      node.override['version_databag']['artifact_specifications'] = [
      {
        'artifact_name' => 'Artifact1',
        'attribute_path' => "['application_cookbook']['version']"
      },
      {
        'artifact_name' => 'Artifact2',
        'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/<Artifact2>/README.md",
        'attribute_path' => "['reference_git']['item']"
      },
      {
        'artifact_name' => 'Artifact3',
        'attribute_path' => "['application_cookbook']['Artifact3']['version']"
      }
    ]
    end
  end

  let(:chef_run) {runner.converge("version_databag::default")}
  let(:step_into) {{step_into: ['version_databag_attrib_interpolate']}}

  let(:databag) {'Artifacts'}
  let(:databag_item) {'versions'}

  before do
    stub_data_bag_item(databag, databag_item).and_return({
      "Artifact1" => {
        "release" => "3.17",
        "snapshot" => "3.18-SNAPSHOT"
      },
      "Artifact2" => {
        "release" => "1.0"
      },
      "Artifact3" => {
        "release" => "1.3",
        "snapshot" => "1.4.SNAPSHOT"
      }
    })
  end

  it 'sets the versions' do
    expect(chef_run).to resolve_version_databag_attrib_interpolate(
      "Determine version for Artifact1 at ['application_cookbook']['version']")
    expect(chef_run).to resolve_version_databag_attrib_interpolate(
      "Determine version for Artifact2 at ['reference_git']['item']")
    expect(chef_run).to resolve_version_databag_attrib_interpolate(
      "Determine version for Artifact3 at ['application_cookbook']['Artifact3']['version']")
    expect(chef_run.node['application_cookbook']['version']).to eql('3.17')
    expect(chef_run.node['reference_git']['item']).to eql('https://raw.githubusercontent.com/cerner/version_databag/1.0/README.md')
    expect(chef_run.node['application_cookbook']['Artifact3']['version']).to eql('1.3')
  end

  describe '#get_version' do
    context 'when there is a missing artifact' do
      artifact_spec = {
        'artifact_name' => 'MissingArtifact',
        'attribute_path' => "['application_cookbook']['version']"
      }

      before do
        runner.node.override['version_databag']['artifact_specifications'] = [artifact_spec]
      end

      context 'when stepping in the resource' do
        it 'fails to find the artifact_name' do
          expect{chef_run}.to raise_error(RuntimeError,
            /Data bag #{databag}\/#{databag_item} does not contain an entry for #{artifact_spec['artifact_name']}/)
        end
      end

      context 'when staying out of the resource' do
        let(:step_into) {{}}
        it 'runs the resource' do
          expect(chef_run).to resolve_version_databag_attrib_interpolate(
            "Determine version for #{artifact_spec['artifact_name']} at #{artifact_spec['attribute_path']}")
        end
      end
    end

    context 'when there is a missing version type' do
      artifact_override_map = {"Artifact1" => "missing"}

      it 'fails to retrieve the version' do
        runner.node.override['version_databag']['artifact_override_map'] = artifact_override_map
        expect{chef_run}.to raise_error(RuntimeError,
            /version_type #{artifact_override_map.values[0]} is missing for #{artifact_override_map.keys[0]}/)
      end
    end

    context 'when there is a valid type override' do
      it 'honors both the override and the version type' do
        runner.node.override['version_databag']['artifact_override_map'] = {"Artifact3" => "snapshot"}
        expect(chef_run.node['application_cookbook']['version']).to eql('3.17')
        expect(chef_run.node['reference_git']['item']).to eql(
          'https://raw.githubusercontent.com/cerner/version_databag/1.0/README.md')
        expect(chef_run.node['application_cookbook']['Artifact3']['version']).to eql('1.4.SNAPSHOT')
      end
    end
  end

  describe '#substitute_value' do
    context 'when the delimiter is misconfigured' do
      it 'fails to substitute the value' do
        runner.node.override['version_databag']['delimiter'] = '<|>'
        expect{chef_run}.to raise_error(RuntimeError,
          /\['version_databag'\]\['delimiter'\] must be one or two characters to delimit the artifact_name/)
      end
    end

    context 'when the value substitution is misconfigured' do
      it 'fails to parse' do
        artifact_spec = {
          'artifact_name' => 'Artifact2',
          'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/Artifact2/README.md",
          'attribute_path' => "['reference_git']['item']"
        }
        runner.node.override['version_databag']['artifact_specifications'] = [artifact_spec]

        expect{chef_run}.to raise_error(RuntimeError,
          /The delimited artifact_name must be included in the value substitution: <#{artifact_spec['artifact_name']}>/)
      end
    end

    context 'when the delimiter is a single character' do
      it 'delimits by that character' do
        runner.node.override['version_databag']['delimiter'] = '|'
        artifact_spec = {
          'artifact_name' => 'Artifact2',
          'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/|Artifact2|/README.md",
          'attribute_path' => "['reference_git']['item']"
        }
        runner.node.override['version_databag']['artifact_specifications'] = [artifact_spec]
        expect{chef_run}.to_not raise_error
      end
    end

    context 'when there are multiple places to substitute' do
      it 'replaces them all' do
        artifact_spec = {
          'artifact_name' => 'Artifact2',
          'value_substitution' => "https://raw.githubusercontent.com/cerner/version_databag/<Artifact2>/README-<Artifact2>.md",
          'attribute_path' => "['reference_git']['item']"
        }
        runner.node.override['version_databag']['artifact_specifications'] = [artifact_spec]

        expect(chef_run.node['reference_git']['item']).to eql(
          'https://raw.githubusercontent.com/cerner/version_databag/1.0/README-1.0.md')
      end
    end
  end

  describe '#set_attribute' do
    context 'when only the beginning of the attribute path exists' do
      it 'populates the attribute' do
        runner.node.override['application_cookbook'] = {}
        expect(chef_run.node['application_cookbook']['version']).to eql('3.17')
      end
    end

    context 'when the full attribute path exists' do
      it 'does not populate the attribute' do
        runner.node.override['application_cookbook']['version'] = '4.3.2'
        expect(chef_run.node['application_cookbook']['version']).to eql('4.3.2')
      end
    end
  end
end
