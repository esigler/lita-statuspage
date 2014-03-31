module Lita
  module Handlers
    class Statuspage < Handler
      route(
        /^statuspage\sincident\snew\s(.+)$/,
        :incident_new,
        command: true,
        help: {
          'statuspage incident new (...)' => 'Create a new realtime incident'
        }
      )

      route(
        /^statuspage\sincident\supdate\s(.+)$/,
        :incident_update,
        command: true,
        help: {
          'statuspage incident update (...)' => 'Update an incident'
        }
      )

      route(
        /^statuspage\sincident\slist\sall$/,
        :incident_list_all,
        command: true,
        help: {
          'statuspage incident list all' => 'List all incidents'
        }
      )

      route(
        /^statuspage\sincident\slist\sscheduled$/,
        :incident_list_scheduled,
        command: true,
        help: {
          'statuspage incident list scheduled' => 'List scheduled incidents'
        }
      )

      route(
        /^statuspage\sincident\slist\sunresolved$/,
        :incident_list_unresolved,
        command: true,
        help: {
          'statuspage incident list unresolved' => 'List unresolved incidents'
        }
      )

      route(
        /^statuspage\sincident\sdelete\slatest$/,
        :incident_delete_latest,
        command: true,
        help: {
          'statuspage incident delete latest' => 'Delete latest incident'
        }
      )

      route(
        /^statuspage\sincident\sdelete\sid:(\w+)$/,
        :incident_delete,
        command: true,
        help: {
          'statuspage incident delete id:<id>' => 'Delete a specific incident'
        }
      )

      route(
        /^statuspage\scomponent\slist$/,
        :component_list,
        command: true,
        help: {
          'statuspage component list' => 'Lists all components'
        }
      )

      route(
        /^statuspage\scomponent\supdate\s(.+)$/,
        :component_update,
        command: true,
        help: {
          'statuspage component update' => 'Updates the component'
        }
      )

      def self.default_config(config)
        config.api_key = nil
        config.page_id = nil
      end

      def incident_new(response)
        response.reply('Not implemented yet.')
      end

      def incident_update(response)
        response.reply('Not implemented yet.')
      end

      def incident_list_all(response)
        response.reply(list_incidents('incidents.json'))
      end

      def incident_list_scheduled(response)
        response.reply(list_incidents('incidents/scheduled.json'))
      end

      def incident_list_unresolved(response)
        response.reply(list_incidents('incidents/unresolved.json'))
      end

      def incident_delete_latest(response)
        incident = latest_incident
        if incident
          response.reply(delete_incident(incident['id']))
        else
          response.reply('No latest incident found')
        end
      end

      def incident_delete(response)
        incident_id = response.matches[0][0]
        response.reply(delete_incident(incident_id))
      end

      def component_list(response)
        response.reply('Not implemented yet.')
      end

      def component_update(response)
        response.reply('Not implemented yet.')
      end

      private

      def incident(id)
        incidents = api_request('get', 'incidents')
        return nil unless incidents && incidents.count > 0
        incidents.each do |incident|
          return incident if incident['id'] == id
        end
        nil
      end

      def latest_incident
        incidents = api_request('get', 'incidents')
        return nil unless incidents && incidents.count > 0
        incidents.first
      end

      def list_incidents(resource)
        incidents = api_request('get', resource)
        response = ''
        if incidents
          response = 'No incidents to list' unless incidents.count > 0
          incidents.each do |incident|
            response += "#{format_incident(incident)}"
          end
        else
          response = 'Error fetching incidents'
        end
        response
      end

      def delete_incident(id)
        incident = incident(id)
        if incident
          result = api_request('delete', "incidents/#{id}.json")
          if result
            "Incident #{id} deleted"
          else
            'Error deleting incident'
          end
        else
          'Incident not found'
        end
      end

      def format_incident(incident)
        name    = incident['name']
        id      = incident['id']
        status  = incident['status']
        created = Date.parse(incident['created_at'])
        "#{name} (" \
        "created: #{created.strftime('%Y-%m-%d')}, " \
        "status: #{status}, " \
        "id: #{id})"
      end

      def parse_args(string)
        # /([a-z]+):(.+)/
      end

      def api_request(method, component, args = {})
        if Lita.config.handlers.statuspage.api_key.nil? ||
           Lita.config.handlers.statuspage.page_id.nil?
          Lita.logger.error('Missing API key or Page ID for Statuspage')
          fail 'Missing config'
        end

        url = "https://api.statuspage.io/v1/pages/" \
              "#{Lita.config.handlers.statuspage.page_id}" \
              "/#{component}"

        http_response = http.send(method) do |req|
          req.url url
          req.headers['Authorization'] =
            "OAuth #{Lita.config.handlers.statuspage.api_key}"
          args.keys do |key|
            req.params[key] = args[key]
          end
        end

        MultiJson.load(http_response.body) if http_response.status == 200
      end
    end

    Lita.register_handler(Statuspage)
  end
end
