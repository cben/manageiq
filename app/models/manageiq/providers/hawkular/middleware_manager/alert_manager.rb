module ManageIQ::Providers
  class Hawkular::MiddlewareManager::AlertManager
    require 'hawkular/hawkular_client'

    def initialize(ems)
      @alerts_client = ems.alerts_client
    end

    def process_alert(operation, miq_alert)
      #byebug_term
      group_trigger = convert_to_group_trigger(miq_alert)
      group_conditions = convert_to_group_conditions(miq_alert)
      case operation
      when :new
        @alerts_client.create_group_trigger(group_trigger)
        @alerts_client.set_group_conditions(group_trigger.id,
                                            :FIRING,
                                            group_conditions)
      when :update
        @alerts_client.update_group_trigger(group_trigger)
        @alerts_client.set_group_conditions(group_trigger.id,
                                            :FIRING,
                                            group_conditions)
      when :delete
        @alerts_client.delete_group_trigger(group_trigger.id)
      end
    end

    def convert_to_group_trigger(miq_alert)
      eval_method = miq_alert[:conditions][:eval_method]
      firing_match = case eval_method
                     when "mw_heap_used", "mw_non_heap_used" then 'ANY'
                     else 'ALL'
                     end
      ::Hawkular::Alerts::Trigger.new('id'          => "MiQ-#{miq_alert[:id]}",
                                      'name'        => miq_alert[:description],
                                      'description' => miq_alert[:description],
                                      'enabled'     => miq_alert[:enabled],
                                      'type'        => :GROUP,
                                      'eventType'   => :EVENT,
                                      'firingMatch' => firing_match,
                                      'tags'        => {
                                        'miq.event_type'    => 'hawkular_event',
                                        'miq.resource_type' => miq_alert[:based_on]
                                      })
    end

    def convert_to_group_conditions(miq_alert)
      eval_method = miq_alert[:conditions][:eval_method]
      options = miq_alert[:conditions][:options]
      case eval_method
      when "mw_accumulated_gc_duration"       then generate_mw_gc_condition(eval_method, options)
      when "mw_heap_used", "mw_non_heap_used" then generate_mw_jvm_conditions(eval_method, options)
      when "hwk_docker_storage_usage" then generate_hwk_docker_storage_conditions(options)
      end
    end

    def generate_mw_gc_condition(eval_method, options)
      c = ::Hawkular::Alerts::Trigger::Condition.new({})
      c.trigger_mode = :FIRING
      c.data_id = MiddlewareServer.supported_metrics_by_column[eval_method]
      c.type = :RATE
      c.operator = convert_operator(options[:mw_operator])
      c.threshold = options[:value_mw_garbage_collector].to_i
      ::Hawkular::Alerts::Trigger::GroupConditionsInfo.new([c])
    end

    def generate_mw_jvm_conditions(eval_method, options)
      data_id = MiddlewareServer.supported_metrics_by_column[eval_method]
      data2_id = MiddlewareServer.supported_metrics_by_column["mw_heap_max"]
      c = []
      c[0] = generate_mw_compare_condition(data_id, data2_id, :GT, options[:value_mw_greater_than].to_f / 100)
      c[1] = generate_mw_compare_condition(data_id, data2_id, :LT, options[:value_mw_less_than].to_f / 100)
      ::Hawkular::Alerts::Trigger::GroupConditionsInfo.new(c)
    end

    def generate_mw_compare_condition(data_id, data2_id, operator, data2_multiplier)
      c = ::Hawkular::Alerts::Trigger::Condition.new({})
      c.trigger_mode = :FIRING
      c.data_id = data_id
      c.data2_id = data2_id
      c.type = :COMPARE
      c.operator = operator
      c.data2_multiplier = data2_multiplier
      c
    end

    def generate_hwk_docker_storage_conditions(options)
      c = ::Hawkular::Alerts::Trigger::Condition.new({})
      c.trigger_mode = :FIRING
      c.data_id = "docker.storage.data.space.percent_available"
      c.type = :THRESHOLD
      c.operator = :LT
      c.threshold = options[:value_mw_greater_than].to_i
      ::Hawkular::Alerts::Trigger::GroupConditionsInfo.new([c])
    end

    def convert_operator(op)
      case op
      when "<"       then :LT
      when "<=", "=" then :LTE
      when ">"       then :GT
      when ">="      then :GTE
      end
    end
  end
end
