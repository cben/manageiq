class ManageIQ::Providers::Openshift::ContainerManager::EventCatcherHawkular < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner

  def self.ems_class
    #byebug_term
    ManageIQ::Providers::Openshift::ContainerManager
  end
end
