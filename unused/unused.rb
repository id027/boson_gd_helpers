module GDUnused

  options :login=>:string, :password=>:string, :server=>:string
  # Processes a project and tells you what is not used and can be removed
  def unused(project_id, options)
    def install_gem(gem_name, gem_ver = nil)
      begin
        if gem_ver
          gem gem_name, gem_ver
        else
          gem gem_name
        end
      rescue Gem::LoadError
        if gem_ver
          system("gem install #{gem_name} --version #{gem_ver}")
        else
          system("gem install #{gem_name}")
        end
        Gem.clear_paths
      ensure
        require gem_name
      end
    end
    
    install_gem('gooddata')
    install_gem('highline')
    client = options.empty? ? GoodData.connect : GoodData.connect(options)

    def create_counter
      x = 0
      lambda { x += 1 }
    end

    def generate_drop_maql(obj)
      if obj[:type] == :fact || obj[:type] == :attribute
        puts "DROP {#{obj[:identifier]}} CASCADE;"
      end
    end

    def generate_sync_maql(objs_to_generate_maql)
      objs_to_generate_maql.map {|x| x[:dataset]}.compact.uniq.each do |ds|
        puts "SYNCHRONIZE {#{ds}} PRESERVE DATA;"
      end
    end

    def generate_maql_report(objs_to_generate_maql)
      puts
      puts "=========="
      objs_to_generate_maql.each do |obj|
        generate_drop_maql(obj)
      end
      generate_sync_maql(objs_to_generate_maql)
      puts "=========="
      
    end

    counter = create_counter

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

    def get_dataset(obj)
      datasets = obj.used_by('dataSet').map {|x| obj.client.get(x['link'])}.map {|x| x['dataSet']['meta']['identifier']}
      datasets.empty? ? nil : datasets.first
    end

    def get_date_dimension(attribute)
      attribute.identifier.split('.').first
    end

    project = client.projects(project_id)
    unused_facts = project.facts.pselect { |fact| fact.used_by('metric').empty? }

    # used_attributes_in_reports = project.reports.pmap {|r| r.latest_report_definition }.pmapcat { |rd| rd.using('attribute') }.map { |a| a['link'] }
    # used_attributes_in_metrics = project.metrics.pmapcat { |rd| rd.using('attribute') }.map { |a| a['link'] }
    # unused_attrs = project.attributes.reject {|a| used_attributes_in_reports.include?(a.uri) }.reject { |a| used_attributes_in_metrics.include?(a.uri) }

    unused_attrs = project.attributes.pselect {|attr| attr.used_by('metric').empty? && attr.used_by('reportDefinition').empty?}
    unused_attr_without_date_attrs = unused_attrs.reject {|a| is_date_attribute?(a)}
    unused_date_dims = unused_attrs.select {|a| is_date_attribute?(a)}.group_by {|x| get_date_dimension(x)}.map {|k,v| [k, v.count]}.select {|k, v| v == 18}

    unused_objects = []
    unused_objects = unused_objects.concat(unused_attr_without_date_attrs.pmap { |a| { dataset: get_dataset(a), counter: counter.call, type: :attribute, title: a.title, obj_id: a.obj_id, identifier: a.identifier }})
    unused_objects = unused_objects.concat(unused_facts.map { |a| { dataset: get_dataset(a), counter: counter.call, type: :fact, title: a.title, obj_id: a.obj_id, identifier: a.identifier }})
    unused_facts = unused_facts.concat(unused_date_dims.map { |k, v| { counter: "", date_dimension_id: k, type: :date_dimension }})

    puts "UNUSED ATTRIBUTES"
    puts Hirb::Helpers::AutoTable.render(unused_objects.select { |x| x[:type] == :attribute }.map {|x| x.except(:dataset)}.sort_by {|x| x[:counter]})

    puts "UNUSED FACTS"
    puts Hirb::Helpers::AutoTable.render(unused_objects.select { |x| x[:type] == :fact }.map {|x| x.except(:dataset)}.sort_by {|x| x[:counter]})

    puts "UNUSED DATE DIMENSIONS"
    puts Hirb::Helpers::AutoTable.render(unused_objects.select { |x| x[:type] == :date_dimension }.map {|x| x.except(:dataset)}.sort_by {|x| x[:counter]})
    puts
    response = HighLine.ask("Please enter numbers of the items you would like to generate drop MAQL DDL for as a list of comma separated numbers or enter for generating all. NO MAQL DDL will be automatically executed.", lambda { |str| str.split(/,\s*/) }) do |q|
    end

    if response.empty?
      generate_maql_report(unused_objects)
    else
      nums = response.map { |x| x.to_i rescue nil }.compact
      objs_to_generate_maql = unused_objects.select {|o| nums.include?(o[:counter])}
      generate_maql_report(objs_to_generate_maql)
    end

    puts ""
  end
end
