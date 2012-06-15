#Copyright 2008 ThoughtWorks, Inc.  All rights reserved.

module RESTfulLoaders
  class RemoteError < StandardError
    def self.parse(response_body)
      Hash.from_xml(response_body)['hash'].delete("message")
    end  
  end  
  
  class Base
    def initialize(project_name)
      @xml_model = if (String === project_name)
        @project_name = project_name
        OpenStruct.new(Hash.from_xml(get(project_name)))
      else
        project_name
      end    
      raise "No such project resource available! #{@project_name}" unless (@xml_model && @xml_model.to_s != '')
    end

    def get(url)
      url = URI.parse(url) unless url.respond_to?(:path)
      get_request = Net::HTTP::Get.new(url.request_uri)
      get_request.basic_auth(url.user, url.password)
      response = Net::HTTP.start(url.host, url.port) { |http| http.request(get_request) }
      if response.code.to_s != "200" 
        raise RemoteError, RemoteError.parse(response.body)
      end  
      response.body
    end  
  
    def load_all_card_types_from_xml
      extract_array_of 'card_types', :from => @xml_model.project
    end  

    def load_all_property_definitions_from_xml
      extract_array_of 'property_definitions', :from => @xml_model.project
    end  

    def load_all_card_types_property_definitions_from_xml
      load_all_card_types_from_xml.collect do |card_type_xml| 
        card_types_property_definitions = OpenStruct.new(card_type_xml).card_types_property_definitions
        [card_types_property_definitions['card_type_property_definition']].flatten if card_types_property_definitions
      end.compact.flatten
    end  

    def card_types_property_definitions_by_card_type_id_loader(card_type_id)
      LoadCardTypesPropertyDefinitionsByCardTypeId.new(card_type_id, @xml_model)
    end  
  
    def card_types_property_definitions_by_property_definition_id_loader(property_definition_id)
      LoadCardTypesPropertyDefinitionsByPropertyDefinitionId.new(property_definition_id, @xml_model)
    end
  
    def values_by_property_definition_id_loader(property_definition_id)
      LoadValuesByPropertyDefinitionId.new(property_definition_id, @xml_model)
    end  

    def card_type_by_id_loader(card_type_id)
      LoadCardTypeById.new(card_type_id, @xml_model)
    end
  
    def property_definition_by_id_loader(property_definition_id)
      LoadPropertyDefinitionById.new(property_definition_id, @xml_model)
    end
    
    def card_types_by_project_id_loader
      LoadCardTypesByProjectId.new(@xml_model)
    end  

    def property_definitions_by_project_id_loader
      LoadPropertyDefinitionsByProjectId.new(@xml_model)
    end  
    
    def team_by_project_id_loader
      LoadTeamByProjectId.new(@xml_model)
    end
    
    def project_variables_by_project_id_loader
      LoadProjectVariablesByProjectId.new(@xml_model)
    end
    
    def extract_array_of(container_key, options)
      contents_hash = options[:from]
      container = contents_hash[container_key]
      container ? [container[container_key.singularize]].flatten : []
    end      
  end

  class ProjectLoader < Base
    class MqlExecutionDelegate < SimpleDelegator
      def initialize(delegate, mql_executor)
        @mql_executor = mql_executor
        __setobj__(delegate)
      end
      
      def execute_mql(mql)
        @mql_executor.execute_mql(mql, self)
      rescue => e
        __getobj__.send(:add_alert, e.message)
        []
      end
      
      def can_be_cached?(mql)
        @mql_executor.can_be_cached?(mql, self)
      rescue => e
        __getobj__.send(:add_alert, e.message)
        []
      end
      
      def format_number_with_project_precision(number)
        @mql_executor.format_number_with_project_precision(number, self)
      rescue => e
        __getobj__.send(:add_alert, e.message)
      end
      
      def format_date_with_project_date_format(date)
        @mql_executor.format_date_with_project_date_format(date, self)
      rescue => e
        __getobj__.send(:add_alert, e.message)
      end
    end  

    def initialize(project_name, macro_context=nil, alert_receiver=nil)
      super(project_name)
      @macro_context = macro_context
      @alert_receiver = alert_receiver
    end
      
    def load_project_from_xml
      @xml_model.project
    end  
    
    def project
      project = MqlExecutionDelegate.new(Mingle::Project.new(OpenStruct.new(load_project_from_xml), :alert_receiver => @alert_receiver), self)
      project.card_types_loader = card_types_by_project_id_loader
      project.property_definitions_loader = property_definitions_by_project_id_loader
      project.team_loader = team_by_project_id_loader
      project.project_variables_loader = project_variables_by_project_id_loader
      project
    end
    
    def execute_mql(mql, project)
      from_xml_data(
        Hash.from_xml(
          get(
            build_request_url(:path => "/projects/#{project.identifier}/cards/execute_mql.xml", :query => "mql=#{mql}"))))
    end
    
    def can_be_cached?(mql, project)
      from_xml_data(
        Hash.from_xml(
          get(
          build_request_url(:path => "/projects/#{project.identifier}/cards/can_be_cached.xml", :query => "mql=#{mql}"))))
    end
    
    def format_number_with_project_precision(number, project)
      from_xml_data(
        Hash.from_xml(
          get(
            build_request_url(:path => "/projects/#{project.identifier}/cards/format_number_to_project_precision.xml", :query => "number=#{number}"))))
    end
    
    def format_date_with_project_date_format(date, project)  
      from_xml_data(
        Hash.from_xml(
          get(
            build_request_url(:path => "/projects/#{project.identifier}/cards/format_string_to_date_format.xml", :query => "date=#{date}"))))
    end
    
    def build_request_url(params)
      url = URI.parse(@project_name)
      request_class = if url.scheme == 'http'
        URI::HTTP
      elsif
        URI::HTTPS
      else
        raise "Unknown protocol used to access project resource #{@project_name}. Supported protocols are HTTP & HTTPS"
      end  
      default_params = {:userinfo => "#{url.user}:#{url.password}", :host => url.host, :port => url.port.to_s}      
      request_class.build2(default_params.merge(params))
    end  
    
    def from_xml_data(data)
      if data.is_a?(Hash) && data.keys.size == 1
        from_xml_data(data.values.first)
      else
        data
      end
    end
      
  end

  class LoadCardTypesByProjectId < Base
    def load
      load_all_card_types_from_xml.collect do |ct|
        card_type = Mingle::CardType.new(OpenStruct.new(ct))
        card_type.card_types_property_definitions_loader = card_types_property_definitions_by_card_type_id_loader(ct['id'])
        card_type
      end.sort_by(&:position)
    end  
  end

  class LoadPropertyDefinitionsByProjectId < Base
    def load
      load_all_property_definitions_from_xml.collect do |pd|
        property_definition = Mingle::PropertyDefinition.new(OpenStruct.new(pd))
        property_definition.card_types_property_definitions_loader = card_types_property_definitions_by_property_definition_id_loader(pd['id'])
        property_definition.values_loader = values_by_property_definition_id_loader(pd['id'])
        property_definition
      end
    end  
  end

  class LoadCardTypesPropertyDefinitionsByCardTypeId < Base
    def initialize(card_type_id, fixture_file_name)
      super(fixture_file_name)
      @card_type_id = card_type_id
    end  
  
    def load
      load_all_card_types_property_definitions_from_xml.collect do |ctpd|
        next unless ctpd['card_type_id'] == @card_type_id

        card_type_property_definition = Mingle::CardTypePropertyDefinition.new(OpenStruct.new(ctpd))
        card_type_property_definition.card_type_loader = card_type_by_id_loader(ctpd['card_type_id'])
        card_type_property_definition.property_definition_loader = property_definition_by_id_loader(ctpd['property_definition_id'])
        card_type_property_definition
      end.compact.sort_by(&:position).compact
    end  

  end  

  class LoadCardTypesPropertyDefinitionsByPropertyDefinitionId < Base
    def initialize(property_definition_id, fixture_file_name)
      super(fixture_file_name)
      @property_definition_id = property_definition_id
    end  

    def load
      load_all_card_types_property_definitions_from_xml.collect do |ctpd|
        next unless ctpd['property_definition_id'] == @property_definition_id
      
        card_type_property_definition = Mingle::CardTypePropertyDefinition.new(OpenStruct.new(ctpd))
        card_type_property_definition.card_type_loader = card_type_by_id_loader(ctpd['card_type_id'])
        card_type_property_definition.property_definition_loader = property_definition_by_id_loader(ctpd['property_definition_id'])
        card_type_property_definition
      end.compact.sort_by(&:position).compact
    end  

  end

  class LoadCardTypeById < Base
    def initialize(card_type_id, fixture_file_name)
      super(fixture_file_name)
      @card_type_id = card_type_id
    end  

    def load
      yaml = load_all_card_types_from_xml.detect { |ct| ct['id'] == @card_type_id }
      ct = Mingle::CardType.new(OpenStruct.new(yaml))
      ct.card_types_property_definitions_loader = card_types_property_definitions_by_card_type_id_loader(yaml['id'])
      ct
    end  
  end  

  class LoadPropertyDefinitionById < Base
    def initialize(property_definition_id, fixture_file_name)
      super(fixture_file_name)
      @property_definition_id = property_definition_id
    end

    def load
      yaml = load_all_property_definitions_from_xml.detect { |pd| pd['id'] == @property_definition_id }
      pd = Mingle::PropertyDefinition.new(OpenStruct.new(yaml))
      pd.card_types_property_definitions_loader = card_types_property_definitions_by_property_definition_id_loader(yaml['id'])
      pd.values_loader = values_by_property_definition_id_loader(yaml['id'])
      pd
    end  
  end

  class LoadValuesByPropertyDefinitionId < Base
    def initialize(property_definition_id, fixture_file_name)
      super(fixture_file_name)
      @property_definition_id = property_definition_id
    end
  
    def load
      property_definition = load_all_property_definitions_from_xml.detect { |property_definition_xml| property_definition_xml['id'] == @property_definition_id }
      return unless property_definition
      extract_array_of('values', :from => property_definition).collect do |property_value_xml| 
        property_value = Mingle::PropertyValue.new(OpenStruct.new(property_value_xml)) 
        property_value.property_definition_loader = property_definition_by_id_loader(property_value_xml['property_definition_id'])
        property_value
      end.compact
    end  
  end
  
  class LoadTeamByProjectId < Base
    def load
      extract_array_of('users', :from => @xml_model.project).collect { |user| Mingle::User.new(OpenStruct.new(user)) }
    end  
  end

  class LoadProjectVariablesByProjectId < Base
    def load
      extract_array_of('project_variables', :from => @xml_model.project).collect { |pv| Mingle::ProjectVariable.new(OpenStruct.new(pv)) }
    end  
  end
end