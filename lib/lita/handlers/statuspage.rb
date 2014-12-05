module Lita
  module Handlers
    class Statuspage < Handler
      route(
        /^(?:statuspage|sp)\sincident\snew\s(.+)$/,
        :incident_new,
        command: true,
        help: {
          '(statuspage|sp) incident new name:"<name>"'       => 'Create a new realtime incident',
          '                             status:<status>'     => '(Optional) One of: investigating|identified|monitoring' \
                                                                '|resolved (default: investigating)',
          '                             message:"<message>"' => '(Optional) The initial message',
          '                             twitter:<state>'     => '(Optional) Post the new incident to Twitter, one of: ' \
                                                                '(true|t|false|f) (default:false)',
          '                             impact:<state>'      => '(Optional) Override calculated impact value, one of: ' \
                                                           '(minor|major|critical)'
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\supdate\s(.+)$/,
        :incident_update,
        command: true,
        help: {
          '(statuspage|sp) incident update id:ABC123 (...)' => 'Update an incident (takes same arguments as new)'
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\slist(\sall)?$/,
        :incident_list_all,
        command: true,
        help: {
          '(statuspage|sp) incident list all' => 'List all incidents'
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\slist\sscheduled$/,
        :incident_list_scheduled,
        command: true,
        help: {
          '(statuspage|sp) incident list scheduled' => 'List scheduled incidents'
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\slist\sunresolved$/,
        :incident_list_unresolved,
        command: true,
        help: {
          '(statuspage|sp) incident list unresolved' => 'List unresolved incidents'
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\sdelete\slatest$/,
        :incident_delete_latest,
        command: true,
        help: {
          '(statuspage|sp) incident delete latest' => 'Delete latest incident'
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\sdelete\sid:(\w+)$/,
        :incident_delete,
        command: true,
        help: {
          '(statuspage|sp) incident delete id:<id>' => 'Delete a specific incident'
        }
      )

      route(
        /^(?:statuspage|sp)\scomponent\slist(\sall)?$/,
        :component_list,
        command: true,
        help: {
          '(statuspage|sp) component list' => 'Lists all components'
        }
      )

      route(
        /^(?:statuspage|sp)\scomponent\supdate\s(.+)$/,
        :component_update,
        command: true,
        help: {
          '(statuspage|sp) component update' => 'Updates the component'
        }
      )

      def self.default_config(config)
        config.api_key = nil
        config.page_id = nil
      end

      def incident_new(response)
        args = parse_args(response.matches[0][0])

        unless args.key?('name')
          response.reply('Can\'t create incident, missing incident name')
          return
        end

        if args.key?('status') && !valid_incident_status?(args['status'])
          response.reply('Can\'t create incident, invalid incident state')
          return
        end

        if args.key?('twitter') && !valid_twitter_status?(args['twitter'])
          response.reply('Can\'t create incident, invalid twitter state')
          return
        end

        if args.key?('impact') && !valid_impact_value?(args['impact'])
          response.reply('Can\'t create incident, invalid impact value')
          return
        end

        response.reply(create_incident(args))
      end

      def incident_update(response)
        args = parse_args(response.matches[0][0])

        unless args.key?('id')
          response.reply('Can\'t update incident, missing incident ID')
          return
        end

        if args.length < 2
          response.reply('Can\'t update incident, nothing to update')
          return
        end

        if args.key?('status') && !valid_incident_status?(args['status'])
          response.reply('Can\'t update incident, invalid incident state')
          return
        end

        if args.key?('twitter') && !valid_twitter_status?(args['twitter'])
          response.reply('Can\'t update incident, invalid twitter state')
          return
        end

        if args.key?('impact') && !valid_impact_value?(args['impact'])
          response.reply('Can\'t update incident, invalid impact value')
          return
        end

        response.reply(update_incident(args['id'], args))
      end

      def incident_list_all(response)
        list_incidents('incidents.json').each do |msg|
          response.reply(msg)
        end
      end

      def incident_list_scheduled(response)
        list_incidents('incidents/scheduled.json').each do |msg|
          response.reply(msg)
        end
      end

      def incident_list_unresolved(response)
        list_incidents('incidents/unresolved.json').each do |msg|
          response.reply(msg)
        end
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
        components = api_request('get', 'components')
        if components
          if components.count > 0
            components.each do |component|
              response.reply(format_component(component))
            end
          else
            response.reply('No components to list')
          end
        else
          response.reply('Error fetching components')
        end
      end

      def component_update(response)
        args = parse_args(response.matches[0][0])
        request_args = {}
        if !args.key?('name') && !args.key?('id')
          response.reply('Need an identifier for the component')
        else
          if args.key?('status')
            if valid_component_status?(args['status'])
              request_args['component[status]'] = args['status']
            else
              response.reply('Invalid status to use in updates')
              return
            end
          else
            request_args['component[status]='] = ''
          end

          if args.key?('id')
            response.reply(update_component(args['id'], request_args))
          elsif args.key?('name')
            component = component(args['name'])
            response.reply(update_component(component['id'], request_args))
          else
            response.reply('Need an identifier for the component')
          end
        end
      end

      private

      def incident(id)
        incidents = api_request('get', 'incidents')
        if incidents && incidents.count > 0
          incidents.each do |incident|
            return incident if incident['id'] == id
          end
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
        response = []
        if incidents
          response = ['No incidents to list'] unless incidents.count > 0
          incidents.each do |incident|
            response.push("#{format_incident(incident)}")
          end
        else
          response = ['Error fetching incidents']
        end
        response
      end

      def create_incident(args)
        request_args = {}
        request_args['incident[name]'] = args['name']
        request_args['incident[status]'] = args['status'] if args.key?('status')
        request_args['incident[wants_twitter_update]'] = args['twitter'] if args.key?('twitter')
        request_args['incident[message]'] = args['message'] if args.key?('message')
        request_args['incident[impact_override]'] = args['impact'] if args.key?('impact')
        result = api_request('post', 'incidents.json', request_args)
        if result
          "Incident #{result['id']} created"
        else
          'Error creating incident'
        end
      end

      def update_incident(id, args)
        incident = incident(id)
        if incident
          request_args = {}
          request_args['incident[status]'] = args['status'] if args.key?('status')
          request_args['incident[wants_twitter_update]'] = args['twitter'] if args.key?('twitter')
          request_args['incident[message]'] = args['message'] if args.key?('message')
          request_args['incident[impact_override]'] = args['impact'] if args.key?('impact')
          result = api_request('patch', "incidents/#{id}.json", request_args)
          if result
            "Incident #{id} updated"
          else
            'Error updating incident'
          end
        else
          'Can\'t update incident, does not exist'
        end
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

      def component(identifier)
        components = api_request('get', 'components')
        return unless components && components.count > 0
        components.each do |component|
          return component if component['id'] == identifier ||
                              component['name'] == identifier
        end
      end

      def update_component(id, args)
        component = component(id)
        if component
          result = api_request('patch', "components/#{id}.json", args)
          if result
            "Component #{id} updated"
          else
            'Error updating component'
          end
        else
          'Component not found'
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
        "id:#{id})"
      end

      def format_component(component)
        name   = component['name']
        id     = component['id']
        status = component['status']
        "#{name} (" \
        "status: #{status}, " \
        "id:#{id})"
      end

      def valid_incident_status?(status)
        %w(investigating identified monitoring resolved).include?(status)
      end

      def valid_twitter_status?(status)
        %w(true t false f).include?(status)
      end

      def valid_impact_value?(value)
        %w(minor major critical).include?(value)
      end

      def valid_component_status?(status)
        %w(operational degraded_performance partial_outage major_outage).include?(status)
      end

      def parse_args(string)
        results = {}
        # TODO: Error handling on parse errors
        arg_pairs = Shellwords.split(string)
        arg_pairs.each do |pair|
          keyval = pair.split(':', 2)
          results[keyval[0]] = keyval[1]
        end
        results
      end

      def api_request(method, component, args = {})
        if Lita.config.handlers.statuspage.api_key.nil? ||
           Lita.config.handlers.statuspage.page_id.nil?
          Lita.logger.error('Missing API key or Page ID for Statuspage')
          fail 'Missing config'
        end

        url = 'https://api.statuspage.io/v1/pages/' \
              "#{Lita.config.handlers.statuspage.page_id}" \
              "/#{component}"

        http_response = http.send(method) do |req|
          req.url url, args
          req.headers['Authorization'] =
            "OAuth #{Lita.config.handlers.statuspage.api_key}"
        end

        if http_response.status == 200 ||
           http_response.status == 201
          MultiJson.load(http_response.body)
        else
          Lita.logger.error("HTTP #{method} for #{url} with #{args} returned #{http_response.status}")
          Lita.logger.error(http_response.body)
          nil
        end
      end
    end

    Lita.register_handler(Statuspage)
  end
end
