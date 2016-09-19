class ManageIQ::Providers::Openshift::ContainerManager::EventCatcherHawkular < ManageIQ::Providers::Hawkular::MiddlewareManager::EventCatcher
  def self.ems_class
    #byebug_term
    ManageIQ::Providers::Openshift::ContainerManager
  end
end
