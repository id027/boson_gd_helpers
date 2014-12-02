module GDUnused
  def unused(project_id)
    require 'gooddata'
    client = GoodData.connect

    def is_date_attribute?(attribute)
      things = ["week",
       "euweek.in.year",
       "day.in.week",
       "day.in.month",
       "day.in.quarter",
       "day.in.euweek",
       "date",
       "quarter.in.year",
       "week.in.year",
       "day.in.year",
       "month",
       "quarter",
       "month.in.quarter",
       "week.in.quarter",
       "year",
       "euweek",
       "euweek.in.quarter",
       "month.in.year"]
      potential_id = attribute.identifier.split('.')[1..-1].join('.')
      things.include?(potential_id) ? true : false
    end    

    def get_date_dimension(attribute)
      attribute.identifier.split('.').first
    end

    project = client.projects(project_id)
    unused_facts = project.facts.pselect { |fact| fact.used_by('metric').empty? }
                                .map { |m| [:fact, m.obj_id, m.title, m.identifier] }

    used_attributes_in_reports = project.reports.pmap {|r| r.latest_report_definition }.pmapcat { |rd| rd.using('attribute') }.map { |a| a['link'] }
    used_attributes_in_metrics = project.metrics.pmapcat { |rd| rd.using('attribute') }.map { |a| a['link'] }
    unused_attrs = project.attributes.reject {|a| used_attributes_in_reports.include?(a.uri) }.reject { |a| used_attributes_in_metrics.include?(a.uri) }

    # unused_attrs = project.attributes.pselect {|attr| attr.used_by('metric').empty? && attr.used_by('reportDefinition').empty?}
    #                                  .map { |m| [:attribute, m.obj_id, m.title, m.identifier] }
    unused_attr_without_date_attrs = unused_attrs.reject {|a| is_date_attribute?(a)}

    puts "UNUSED ATTRIBUTES"
    puts Hirb::Helpers::AutoTable.render(unused_attr_without_date_attrs.map {|a| {type: :attribute, title: a.title, obj_id: a.obj_id, identifier: a.identifier}})

    puts "UNUSED ATTRIBUTES"
    puts Hirb::Helpers::AutoTable.render(unused_facts.map {|a| {type: :fact, title: a.title, obj_id: a.obj_id, identifier: a.identifier}})

    puts "UNUSED DATE DIMENSIONS"
    unused_date_dims = unused_attrs.select {|a| is_date_attribute?(a)}.group_by {|x| get_date_dimension(x)}.map {|k,v| [k, v.count]}.select {|k, v| v == 18}
    puts Hirb::Helpers::AutoTable.render(unused_date_dims)
  end
end
