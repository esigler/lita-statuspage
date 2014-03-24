require 'multi_json'

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
        /^statuspage\sincident\slist$/,
        :incident_list,
        command: true,
        help: {
          'statuspage incident list' => 'List all incidents'
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

      def incident_list(response)
        incidents = api_get('incidents')
        response.reply('Not implemented yet.')
      end

      def incident_delete_latest(response)
        response.reply('Not implemented yet.')
      end

      def incident_delete(response)
        response.reply('Not implemented yet.')
      end

      def component_list(response)
        response.reply('Not implemented yet.')
      end

      def component_update(response)
        response.reply('Not implemented yet.')
      end

      private

      def parse_args(string)
        # /([a-z]+):(.+)/
      end

      def api_get(component, hash = {})
        if Lita.config.handlers.statuspage.api_key.nil? ||
           Lita.config.handlers.statuspage.page_id.nil?
          fail 'Bad config'
        end

        url = "https://api.statuspage.io/v1/pages/" \
              "#{Lita.config.handlers.statuspage.page_id}" \
              "/#{component}.json"

        http_response = http.get do |req|
          req.url url
          req.headers['Authorization'] =
            "OAuth #{Lita.config.handlers.statuspage.api_key}"
          hash.keys do |key|
            req.params[key] = hash[key]
          end
        end

        if http_response.status == 200
          MultiJson.load(http_response.body)
        else
          nil
        end
      end
    end

    Lita.register_handler(Statuspage)
  end
end
