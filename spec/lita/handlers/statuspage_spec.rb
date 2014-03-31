require 'spec_helper'

describe Lita::Handlers::Statuspage, lita_handler: true do
  let(:incidents) do
    File.read('spec/files/incidents.json')
  end

  let(:incidents_empty) do
    '[]'
  end

  let(:incidents_scheduled) do
    File.read('spec/files/incidents_scheduled.json')
  end

  let(:incidents_unresolved) do
    File.read('spec/files/incidents_unresolved.json')
  end

  let(:incident_deleted) do
    File.read('spec/files/incident_deleted.json')
  end

  let(:components) do
    File.read('spec/files/components.json')
  end

  let(:components_empty) do
    '[]'
  end

  it { routes_command('statuspage incident new name:"foo"').to(:incident_new) }
  it { routes_command('statuspage incident update latest').to(:incident_update) }
  it { routes_command('statuspage incident list all').to(:incident_list_all) }
  it { routes_command('statuspage incident list scheduled').to(:incident_list_scheduled) }
  it { routes_command('statuspage incident list unresolved').to(:incident_list_unresolved) }
  it { routes_command('statuspage incident delete latest').to(:incident_delete_latest) }
  it { routes_command('statuspage incident delete id:omgwtfbbq').to(:incident_delete) }
  it { routes_command('statuspage component list').to(:component_list) }
  it { routes_command('statuspage component update latest').to(:component_update) }

  describe '.default_config' do
    it 'sets api_key to nil' do
      expect(Lita.config.handlers.statuspage.api_key).to be_nil
    end

    it 'sets page_id to nil' do
      expect(Lita.config.handlers.statuspage.page_id).to be_nil
    end
  end

  describe 'without valid config' do
    it 'should error out on any command' do
      expect { send_command('statuspage incident list all') }.to raise_error('Missing config')
    end
  end

  describe 'with valid config' do
    before do
      Lita.config.handlers.statuspage.api_key = 'foo'
      Lita.config.handlers.statuspage.page_id = 'bar'
    end

    describe '#incident_new' do
    end

    describe '#incident_update' do
    end

    describe '#incident_list_all' do
      it 'shows a list of incidents if there are any' do
        response = double('Faraday::Response', status: 200, body: incidents)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list all')
        expect(replies.last).to eq('Test Incident (created: 2014-03-24, ' \
                                   'status: resolved, id: td9ftgzcyz4m)')
      end

      it 'shows a warning if there arent any' do
        response = double('Faraday::Response', status: 200, body: incidents_empty)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list all')
        expect(replies.last).to eq('No incidents to list')
      end

      it 'shows an error if there was an issue fetching the incidents' do
        response = double('Faraday::Response', status: 500)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list all')
        expect(replies.last).to eq('Error fetching incidents')
      end
    end

    describe '#incident_list_scheduled' do
      it 'shows a list of incidents if there are any' do
        response = double('Faraday::Response', status: 200, body: incidents_scheduled)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list scheduled')
        expect(replies.last).to eq('Test Maintenance (created: 2014-03-30, ' \
                                   'status: scheduled, id: 3tzsm37ryws0)')
      end

      it 'shows a warning if there arent any' do
        response = double('Faraday::Response', status: 200, body: incidents_empty)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list scheduled')
        expect(replies.last).to eq('No incidents to list')
      end

      it 'shows an error if there was an issue fetching the incidents' do
        response = double('Faraday::Response', status: 500)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list scheduled')
        expect(replies.last).to eq('Error fetching incidents')
      end
    end

    describe '#incident_list_unresolved' do
      it 'shows a list of incidents if there are any' do
        response = double('Faraday::Response', status: 200, body: incidents_unresolved)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list unresolved')
        expect(replies.last).to eq('Unresolved incident (created: 2014-03-30, ' \
                                   'status: investigating, id: 2ttv50n0n8zj)')
      end

      it 'shows a warning if there arent any' do
        response = double('Faraday::Response', status: 200, body: incidents_empty)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list scheduled')
        expect(replies.last).to eq('No incidents to list')
      end

      it 'shows an error if there was an issue fetching the incidents' do
        response = double('Faraday::Response', status: 500)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident list scheduled')
        expect(replies.last).to eq('Error fetching incidents')
      end
    end

    describe '#incident_delete_latest' do
      it 'shows an ack if the incident was deleted' do
        get_response = double('Faraday::Response', status: 200, body: incidents_unresolved)
        delete_response = double('Faraday::Response', status: 200, body: incident_deleted)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(get_response)
        allow_any_instance_of(Faraday::Connection).to receive(:delete).and_return(delete_response)
        send_command('statuspage incident delete latest')
        expect(replies.last).to eq('Incident 2ttv50n0n8zj deleted')
      end

      it 'shows a warning if there wasnt an incident to delete' do
        response = double('Faraday::Response', status: 404)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident delete latest')
        expect(replies.last).to eq('No latest incident found')
      end

      it 'shows an error if there was an issue deleting the incident' do
        get_response = double('Faraday::Response', status: 200, body: incidents_unresolved)
        delete_response = double('Faraday::Response', status: 500)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(get_response)
        allow_any_instance_of(Faraday::Connection).to receive(:delete).and_return(delete_response)
        send_command('statuspage incident delete latest')
        expect(replies.last).to eq('Error deleting incident')
      end
    end

    describe '#incident_delete' do
      it 'shows an ack if the incident was deleted' do
        get_response = double('Faraday::Response', status: 200, body: incidents_unresolved)
        delete_response = double('Faraday::Response', status: 200, body: incident_deleted)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(get_response)
        allow_any_instance_of(Faraday::Connection).to receive(:delete).and_return(delete_response)
        send_command('statuspage incident delete id:2ttv50n0n8zj')
        expect(replies.last).to eq('Incident 2ttv50n0n8zj deleted')
      end

      it 'shows a warning if there wasnt an incident to delete' do
        response = double('Faraday::Response', status: 404)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage incident delete id:2ttv50n0n8zj')
        expect(replies.last).to eq('Incident not found')
      end

      it 'shows an error if there was an issue deleting the incident' do
        get_response = double('Faraday::Response', status: 200, body: incidents_unresolved)
        delete_response = double('Faraday::Response', status: 500)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(get_response)
        allow_any_instance_of(Faraday::Connection).to receive(:delete).and_return(delete_response)
        send_command('statuspage incident delete id:2ttv50n0n8zj')
        expect(replies.last).to eq('Error deleting incident')
      end
    end

    describe '#component_list' do
      it 'shows a list of components if there are any' do
        response = double('Faraday::Response', status: 200, body: components)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage component list')
        expect(replies.last).to eq('Management Portal (example) (status: operational, id: v6z6tpldcw85)')
      end

      it 'shows a warning if there arent any' do
        response = double('Faraday::Response', status: 200, body: components_empty)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage component list')
        expect(replies.last).to eq('No components to list')
      end

      it 'shows an error if there was an issue fetching the components' do
        response = double('Faraday::Response', status: 500)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response)
        send_command('statuspage component list')
        expect(replies.last).to eq('Error fetching components')
      end
    end

    describe '#component_update' do
    end
  end
end
