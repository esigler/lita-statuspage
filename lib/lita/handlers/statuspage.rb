module Lita
  module Handlers
    class Statuspage < Handler
      config :api_key, required: true
      config :page_id, required: true

      route(
        /^(?:statuspage|sp)\sincident\snew\s(.+)$/,
        :incident_new,
        command: true,
        help: {
          t('help.incident.new.syntax') => t('help.incident.new.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\supdate\s(.+)$/,
        :incident_update,
        command: true,
        help: {
          t('help.incident.update.syntax') => t('help.incident.update.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\slist(\sall)?$/,
        :incident_list_all,
        command: true,
        help: {
          t('help.incident.list_all.syntax') => t('help.incident.list_all.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\slist\sscheduled$/,
        :incident_list_scheduled,
        command: true,
        help: {
          t('help.incident.list_sch.syntax') => t('help.incident.list_sch.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\slist\sunresolved$/,
        :incident_list_unresolved,
        command: true,
        help: {
          t('help.incident.list_unr.syntax') => t('help.incident.list_unr.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\sdelete\slatest$/,
        :incident_delete_latest,
        command: true,
        help: {
          t('help.incident.delete_l.syntax') => t('help.incident.delete_l.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\sincident\sdelete\sid:(\w+)$/,
        :incident_delete,
        command: true,
        help: {
          t('help.incident.delete_i.syntax') => t('help.incident.delete_i.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\scomponent\slist(\sall)?$/,
        :component_list,
        command: true,
        help: {
          t('help.component.list.syntax') => t('help.component.list.desc')
        }
      )

      route(
        /^(?:statuspage|sp)\scomponent\supdate\s(.+)$/,
        :component_update,
        command: true,
        help: {
          t('help.component.update.syntax') => t('help.component.update.desc')
        }
      )

      def incident_new(response)
        args = parse_args(response.matches[0][0])

        return response.reply(t('error.invalid_arguments')) unless valid_args?(args)

        response.reply(create_incident(args))
      end

      def incident_update(response)
        args = parse_args(response.matches[0][0])

        return response.reply(t('error.invalid_arguments')) unless valid_args?(args)

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

        return response.reply(t('incident.not_found')) unless incident

        response.reply(delete_incident(incident['id']))
      end

      def incident_delete(response)
        incident_id = response.matches[0][0]
        response.reply(delete_incident(incident_id))
      end

      def component_list(response)
        components = api_request('get', 'components')

        return response.reply(t('error.api_request')) if components.nil?
        return response.reply(t('component.none')) if components.count == 0

        components.each do |component|
          response.reply(format_component(component))
        end
      end

      def component_update(response)
        args = parse_args(response.matches[0][0])
        c_id = identify_component(args)

        return response.reply(t('component.need_identifier')) unless c_id
        return response.reply(t('component.invalid_status')) unless valid_component_status?(args['status'])

        response.reply(update_component(c_id, 'component[status]' => args['status']))
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
        return [t('error.api_request')] unless incidents

        response = []
        response = ['No incidents to list'] unless incidents.count > 0
        incidents.each do |incident|
          response.push("#{format_incident(incident)}")
        end

        response
      end

      def create_incident(args)
        api_args = {}
        api_args['incident[name]'] = args['name']
        api_args['incident[status]'] = args['status'] if args.key?('status')
        api_args['incident[wants_twitter_update]'] = args['twitter'] if args.key?('twitter')
        api_args['incident[message]'] = args['message'] if args.key?('message')
        api_args['incident[impact_override]'] = args['impact'] if args.key?('impact')

        result = api_request('post', 'incidents.json', api_args)
        result ? t('incident.created', id: result['id']) : t('error.api_request')
      end

      def update_incident(id, args)
        incident = incident(id)
        return t('incident.not_found') unless incident

        api_args = {}
        api_args['incident[status]'] = args['status'] if args.key?('status')
        api_args['incident[wants_twitter_update]'] = args['twitter'] if args.key?('twitter')
        api_args['incident[message]'] = args['message'] if args.key?('message')
        api_args['incident[impact_override]'] = args['impact'] if args.key?('impact')

        result = api_request('patch', "incidents/#{id}.json", api_args)
        result ? t('incident.updated', id: id) : t('error.api_request')
      end

      def delete_incident(id)
        incident = incident(id)
        return t('incident.not_found') unless incident

        result = api_request('delete', "incidents/#{id}.json")
        result ? t('incident.deleted', id: id) : t('error.api_request')
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
        return t('component.not_found') unless component

        result = api_request('patch', "components/#{id}.json", args)
        result ? t('component.updated', id: id) : t('error.api_request')
      end

      def identify_component(args)
        return nil unless args.key?('name') || args.key?('id')

        if args.key?('id')
          return args['id']
        elsif args.key?('name')
          component = component(args['name'])
          return component['id']
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
        %w(operational
           degraded_performance
           partial_outage
           major_outage).include?(status)
      end

      def valid_args?(args)
        return false unless args.key?('name') || args.key?('id')

        return false if args.key?('status') &&
                        !valid_incident_status?(args['status'])

        return false if args.key?('twitter') &&
                        !valid_twitter_status?(args['twitter'])

        return false if args.key?('impact') &&
                        !valid_impact_value?(args['impact'])

        true
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
        url = "https://api.statuspage.io/v1/pages/#{config.page_id}/#{component}"

        http_response = http.send(method) do |req|
          req.url url, args
          req.headers['Authorization'] = "OAuth #{config.api_key}"
        end

        unless http_response.status == 200 || http_response.status == 201
          Lita.logger.error("#{method} for #{url} with #{args}: #{http_response.status}")
          return nil
        end

        MultiJson.load(http_response.body)
      end
    end

    Lita.register_handler(Statuspage)
  end
end
