class ManageIQ::Providers::Hawkular::MiddlewareManager::EventCatcher < ManageIQ::Providers::BaseManager::EventCatcher
  require_nested :Runner

  # TODO: I'm trying to run ContainerManager::EventCatcherHawkular which inherits from this,
  # but apparently this class gets instantiated ~~instead~~ too, and then killed by sync_workers
  # because there are no Middleware providers.
  def self.ems_class
    #byebug_term
    ManageIQ::Providers::Openshift::ContainerManager
  end
end
