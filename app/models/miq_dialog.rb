class MiqDialog < ApplicationRecord
  validates :name, :description, :presence => true
  validates :name, :uniqueness => { :scope => :dialog_type, :case_sensitive => false }

  DIALOG_DIR = "product/dialogs/miq_dialogs".freeze

  DIALOG_TYPES = [
    [_("VM Provision"),                "MiqProvisionWorkflow"],
    [_("Configured System Provision"), "MiqProvisionConfiguredSystemWorkflow"],
    [_("Host Provision"),              "MiqHostProvisionWorkflow"],
    [_("VM Migrate"),                  "VmMigrateWorkflow"],
  ].freeze

  serialize :content

  def self.seed
    sync_from_dir(Rails.root)
    sync_from_plugins
  end

  def self.sync_from_dir(root)
    root = root.join(DIALOG_DIR)
    Dir.glob(root.join("*.yaml")).each { |f| sync_from_file(f, root) }
  end

  def self.sync_from_plugins
    Vmdb::Plugins.instance.registered_provider_plugins.each do |plugin|
      sync_from_dir(plugin.root)
    end
  end

  def self.sync_from_file(filename, root)
    item = YAML.load_file(filename)

    item[:filename] = filename.sub("#{root}/", "")
    item[:file_mtime] = File.mtime(filename).utc
    item[:default] = true

    rec = find_by(:name => item[:name], :filename => item[:filename])

    if rec
      if rec.filename && (rec.file_mtime.nil? || rec.file_mtime.utc < item[:file_mtime])
        _log.info("[#{rec.name}] file has been updated on disk, synchronizing with model")
        rec.update_attributes(item)
        rec.save
      end
    else
      _log.info("[#{item[:name]}] file has been added to disk, adding to model")
      create(item)
    end
  end
end
