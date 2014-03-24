require 'spec_helper'

describe Lita::Handlers::Statuspage, lita_handler: true do
  it { routes_command('statuspage incident new name:"foo"').to(:incident_new) }
  it { routes_command('statuspage incident update latest').to(:incident_update) }
  it { routes_command('statuspage incident list').to(:incident_list) }
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
      expect { send_command('statuspage incident list') }.to raise_error('Bad config')
    end
  end

  describe 'with valid config' do
    before do
      Lita.config.handlers.statuspage.api_key = 'foo'
      Lita.config.handlers.statuspage.page_id = 'bar'
    end

    describe '#incident_new' do
      it 'shows a warning' do
        send_command('statuspage incident new name:"foo"')
        expect(replies.last).to eq('Not implemented yet.')
      end
    end

    describe '#incident_update' do
    end

    describe '#incident_list' do
    end

    describe '#incident_delete' do
    end

    describe '#component_list' do
    end

    describe '#component_update' do
    end
  end
end
