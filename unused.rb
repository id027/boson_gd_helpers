module GDUnused
  def unused(project_id)
    require 'gooddata'
    client = GoodData.connect
    project = client.projects(project_id)

    unused_facts = project.facts.pselect {|fact| fact.used_by('metric').empty?}
                                .map {|m| [:fact, m.obj_id, m.title, m.identifier]}
    unused_attrs = project.attributes.pselect {|fact| fact.used_by('metric').empty? && fact.used_by('reportDefintion').empty?}
                                     .map {|m| [:attribute, m.obj_id, m.title, m.identifier]}
    unused_attrs + unused_facts
  end
end
