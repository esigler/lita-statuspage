require 'spec_helper'

describe Lita::Handlers::Statuspage, lita_handler: true do
  let(:incidents) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/incidents.json'))
  end

  let(:incidents_empty) do
    double('Faraday::Response',
           status: 200,
           body: '[]')
  end

  let(:incidents_scheduled) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/incidents_scheduled.json'))
  end

  let(:incidents_unresolved) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/incidents_unresolved.json'))
  end

  let(:incidents_updated) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/incidents_update.json'))
  end

  let(:incident_new) do
    double('Faraday::Response',
           status: 201,
           body: File.read('spec/files/incident_new.json'))
  end

  let(:incident_deleted) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/incident_deleted.json'))
  end

  let(:incident_updated) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/incident_updated.json'))
  end

  let(:components) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/components.json'))
  end

  let(:components_empty) do
    double('Faraday::Response',
           status: 200,
           body: '[]')
  end

  let(:component_update) do
    double('Faraday::Response',
           status: 200,
           body: File.read('spec/files/component_update.json'))
  end

  let(:generic_error) do
    double('Faraday::Response',
           status: 500,
           body: '')
  end

  let(:generic_missing) do
    double('Faraday::Response',
           status: 404,
           body: '')
  end

  def catch(symbol, result)
    allow_any_instance_of(Faraday::Connection).to receive(symbol)
      .and_return(result)
  end

  %w(statuspage sp).each do |name|
    it do
      is_expected.to route_command("#{name} incident new name:\"foo\"")
        .to(:incident_new)
      is_expected.to route_command("#{name} incident update latest")
        .to(:incident_update)
      is_expected.to route_command("#{name} incident list")
        .to(:incident_list_all)
      is_expected.to route_command("#{name} incident list all")
        .to(:incident_list_all)
      is_expected.to route_command("#{name} incident list scheduled")
        .to(:incident_list_scheduled)
      is_expected.to route_command("#{name} incident list unresolved")
        .to(:incident_list_unresolved)
      is_expected.to route_command("#{name} incident delete latest")
        .to(:incident_delete_latest)
      is_expected.to route_command("#{name} incident delete id:omgwtfbbq")
        .to(:incident_delete)
      is_expected.to route_command("#{name} component list")
        .to(:component_list)
      is_expected.to route_command("#{name} component list all")
        .to(:component_list)
      is_expected.to route_command("#{name} component update latest")
        .to(:component_update)
    end
  end

  before do
    Lita.config.handlers.statuspage.api_key = 'foo'
    Lita.config.handlers.statuspage.page_id = 'bar'
  end

  describe '#incident_new' do
    it 'shows an ack when the incident is created' do
      catch(:post, incident_new)
      send_command('statuspage incident new name:"lp0 on fire"')
      expect(replies.last).to eq('Incident b0m7dz4tzpl3 created')
    end

    it 'shows a warning if the incident does not have a required name' do
      send_command('sp incident new status:investigating')
      expect(replies.last).to eq('Can\'t create incident, ' \
                                 'invalid arguments')
    end

    it 'shows a warning if the incident status is not valid' do
      send_command('sp incident new name:"It dun broke" status:ignoring')
      expect(replies.last).to eq('Can\'t create incident, ' \
                                 'invalid arguments')
    end

    it 'shows a warning if the twitter status is not valid' do
      send_command('sp incident new name:"It dun broke" twitter:lavender')
      expect(replies.last).to eq('Can\'t create incident, ' \
                                 'invalid arguments')
    end

    it 'shows a warning if the impact value is not valid' do
      send_command('sp incident new name:"It dun broke" impact:apocalypse')
      expect(replies.last).to eq('Can\'t create incident, ' \
                                 'invalid arguments')
    end

    it 'shows an error if there was an issue creating the incident' do
      catch(:get, generic_error)
      send_command('statuspage incident new name:"It dun broke"')
      expect(replies.last).to eq('Error creating incident')
    end
  end

  describe '#incident_update' do
    it 'shows an ack when the incident is updated' do
      catch(:get, incidents_updated)
      catch(:patch, incident_updated)
      send_command('statuspage incident update id:b0m7dz4tzpl3 ' \
                   'message:"Howdy"')
      expect(replies.last).to eq('Incident b0m7dz4tzpl3 updated')
    end

    it 'shows a warning if the incident does not exist' do
      catch(:get, incidents)
      send_command('sp incident update id:b0m7dz4tzpl3 message:"Howdy"')
      expect(replies.last).to eq('Can\'t update incident, does not exist')
    end

    it 'shows a warning if the incident does not have an id' do
      send_command('sp incident update status:investigating')
      expect(replies.last).to eq('Can\'t update incident, ' \
                                 'invalid arguments')
    end

    it 'shows a warning if the incident status is not valid' do
      send_command('sp incident update id:b0m7dz4tzpl3 status:running_away')
      expect(replies.last).to eq('Can\'t update incident, ' \
                                 'invalid arguments')
    end

    it 'shows a warning if the twitter status is not valid' do
      send_command('sp incident update id:b0m7dz4tzpl3 twitter:magenta')
      expect(replies.last).to eq('Can\'t update incident, ' \
                                 'invalid arguments')
    end

    it 'shows a warning if the impact value is not valid' do
      send_command('sp incident update id:b0m7dz4tzpl3 impact:ragnarok')
      expect(replies.last).to eq('Can\'t update incident, ' \
                                 'invalid arguments')
    end

    it 'shows an error if there was an issue updating the incident' do
      catch(:get, incidents_updated)
      catch(:patch, generic_error)
      send_command('sp incident update id:b0m7dz4tzpl3 message:"Howdy"')
      expect(replies.last).to eq('Error updating incident')
    end
  end

  describe '#incident_list_all' do
    it 'shows a list of incidents if there are any' do
      catch(:get, incidents)
      send_command('sp incident list all')
      expect(replies.last).to eq('Test Incident (created: 2014-03-24, ' \
                                 'status: resolved, id:td9ftgzcyz4m)')
    end

    it 'shows a warning if there arent any' do
      catch(:get, incidents_empty)
      send_command('sp incident list all')
      expect(replies.last).to eq('No incidents to list')
    end

    it 'shows an error if there was an issue fetching the incidents' do
      catch(:get, generic_error)
      send_command('sp incident list all')
      expect(replies.last).to eq('Error fetching incidents')
    end
  end

  describe '#incident_list_scheduled' do
    it 'shows a list of incidents if there are any' do
      catch(:get, incidents_scheduled)
      send_command('sp incident list scheduled')
      expect(replies.last).to eq('Test Maintenance (created: 2014-03-30, ' \
                                 'status: scheduled, id:3tzsm37ryws0)')
    end

    it 'shows a warning if there arent any' do
      catch(:get, incidents_empty)
      send_command('sp incident list scheduled')
      expect(replies.last).to eq('No incidents to list')
    end

    it 'shows an error if there was an issue fetching the incidents' do
      catch(:get, generic_error)
      send_command('sp incident list scheduled')
      expect(replies.last).to eq('Error fetching incidents')
    end
  end

  describe '#incident_list_unresolved' do
    it 'shows a list of incidents if there are any' do
      catch(:get, incidents_unresolved)
      send_command('statuspage incident list unresolved')
      expect(replies.last).to eq('Unresolved incident (created: ' \
                                 '2014-03-30, status: investigating, ' \
                                 'id:2ttv50n0n8zj)')
    end

    it 'shows a warning if there arent any' do
      catch(:get, incidents_empty)
      send_command('statuspage incident list scheduled')
      expect(replies.last).to eq('No incidents to list')
    end

    it 'shows an error if there was an issue fetching the incidents' do
      catch(:get, generic_error)
      send_command('statuspage incident list scheduled')
      expect(replies.last).to eq('Error fetching incidents')
    end
  end

  describe '#incident_delete_latest' do
    it 'shows an ack if the incident was deleted' do
      catch(:get, incidents_unresolved)
      catch(:delete, incident_deleted)
      send_command('statuspage incident delete latest')
      expect(replies.last).to eq('Incident 2ttv50n0n8zj deleted')
    end

    it 'shows a warning if there wasnt an incident to delete' do
      catch(:get, generic_missing)
      send_command('statuspage incident delete latest')
      expect(replies.last).to eq('No latest incident found')
    end

    it 'shows an error if there was an issue deleting the incident' do
      catch(:get, incidents_unresolved)
      catch(:delete, generic_error)
      send_command('statuspage incident delete latest')
      expect(replies.last).to eq('Error deleting incident')
    end
  end

  describe '#incident_delete' do
    it 'shows an ack if the incident was deleted' do
      catch(:get, incidents_unresolved)
      catch(:delete, incident_deleted)
      send_command('statuspage incident delete id:2ttv50n0n8zj')
      expect(replies.last).to eq('Incident 2ttv50n0n8zj deleted')
    end

    it 'shows a warning if there wasnt an incident to delete' do
      catch(:get, generic_missing)
      send_command('statuspage incident delete id:2ttv50n0n8zj')
      expect(replies.last).to eq('Incident not found')
    end

    it 'shows an error if there was an issue deleting the incident' do
      catch(:get, incidents_unresolved)
      catch(:delete, generic_error)
      send_command('statuspage incident delete id:2ttv50n0n8zj')
      expect(replies.last).to eq('Error deleting incident')
    end
  end

  describe '#component_list' do
    it 'shows a list of components if there are any' do
      catch(:get, components)
      send_command('statuspage component list')
      expect(replies.last).to eq('Management Portal (example) ' \
                                 '(status: operational, id:v6z6tpldcw85)')
    end

    it 'shows a warning if there arent any' do
      catch(:get, components_empty)
      send_command('statuspage component list')
      expect(replies.last).to eq('No components to list')
    end

    it 'shows an error if there was an issue fetching the components' do
      catch(:get, generic_error)
      send_command('statuspage component list')
      expect(replies.last).to eq('Error fetching components')
    end
  end

  describe '#component_update' do
    it 'shows an ack if the component is updated via id' do
      catch(:get, components)
      catch(:patch, component_update)
      send_command('sp component update id:v6z6tpldcw85 status:major_outage')
      expect(replies.last).to eq('Component v6z6tpldcw85 updated')
    end

    it 'shows an ack if the component is updated via name' do
      catch(:get, components)
      catch(:patch, component_update)
      send_command('sp component update name:"Management Portal ' \
                   '(example)" status:major_outage')
      expect(replies.last).to eq('Component v6z6tpldcw85 updated')
    end

    it 'shows a warning if there is no identifier to the component' do
      send_command('sp component update status:major_outage')
      expect(replies.last).to eq('Need an identifier for the component')
    end

    it 'shows a warning if the status is invalid' do
      send_command('sp component update id:v6z6tpldcw85 status:big_problem')
      expect(replies.last).to eq('Invalid status to use in updates')
    end

    it 'shows an error if there was an issue updating the component' do
      catch(:get, components)
      catch(:patch, generic_error)
      send_command('sp component update id:v6z6tpldcw85 status:major_outage')
      expect(replies.last).to eq('Error updating component')
    end
  end
end
