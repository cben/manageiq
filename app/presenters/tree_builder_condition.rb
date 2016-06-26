class TreeBuilderCondition < TreeBuilder
  private

  def tree_init_options(_tree_name)
    {:full_ids => true}
  end

  def set_locals_for_render
    locals = super
    locals.merge!(
      :id_prefix => "co_",
      :autoload  => true,
    )
  end

  # level 0 - root
  def root_options
    [t = N_("All Conditions"), t]
  end

  # level 1 - host / vm
  def x_get_tree_roots(count_only, _options)
    objects = []
    objects << {:id => "host", :text => N_("Host Conditions"), :image => "host",
                :tip => N_("Host Conditions")}
    objects << {:id => "vm", :text => N_("All VM and Instance Conditions"),
                :image => "vm", :tip => N_("All VM and Instance Conditions")}
    objects << {:id => "containerReplicator", :text => N_("Container Replicator Conditions"),
                :image => "container_replicator", :tip => N_("All Container Image Conditions")}
    objects << {:id => "containerGroup", :text => N_("Pod Conditions"),
                :image => "container_group", :tip => N_("All Container Image Conditions")}
    objects << {:id => "containerNode", :text => N_("Container Node Conditions"),
                :image => "container_node", :tip => N_("All Container Image Conditions")}
    objects << {:id => "containerImage", :text => N_("Container Image Conditions"),
                :image => "container_image", :tip => N_("All Container Image Conditions")}

    count_only_or_objects(count_only, objects)
  end

  # level 2 - conditions
  def x_get_tree_custom_kids(parent, count_only, options)
    assert_type(options[:type], :condition)
    condition_ids = %w(host vm containerReplicator containerGroup containerNode containerImage)
    return super unless condition_ids.include?(parent[:id])

    objects = Condition.where(:towhat => parent[:id].camelize)

    count_only_or_objects(count_only, objects, :description)
  end
end
