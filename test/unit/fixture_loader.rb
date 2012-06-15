#Copyright 2008 ThoughtWorks, Inc.  All rights reserved.

module FixtureLoaders
  class Base
    def initialize(mingle_file_name, macro_context=nil, alert_receiver=nil)
      @mingle_file_name = mingle_file_name
      @expanded_fixture = File.join(File.dirname(__FILE__), '..', 'fixtures', mingle_file_name)
      raise "No such project fixture! #{mingle_file_name}" unless File.exist?(@expanded_fixture)
    end
  
    def load_fixtures_for(name)
      YAML::load(File.open("#{@expanded_fixture}/#{name}.yml"))
    end
  
    def card_types_property_definitions_by_card_type_id_loader(card_type_id)
      LoadCardTypesPropertyDefinitionsByCardTypeId.new(card_type_id, @mingle_file_name)
    end  
  
    def card_types_property_definitions_by_property_definition_id_loader(property_definition_id)
      LoadCardTypesPropertyDefinitionsByPropertyDefinitionId.new(property_definition_id, @mingle_file_name)
    end
  
    def values_by_property_definition_id_loader(property_definition_id)
      LoadValuesByPropertyDefinitionId.new(property_definition_id, @mingle_file_name)
    end  

    def card_type_by_id_loader(card_type_id)
      LoadCardTypeById.new(card_type_id, @mingle_file_name)
    end
  
    def property_definition_by_id_loader(property_definition_id)
      LoadPropertyDefinitionById.new(property_definition_id, @mingle_file_name)
    end  
    
    def card_types_by_project_id_loader
      LoadCardTypesByProjectId.new(@mingle_file_name)
    end  

    def property_definitions_by_project_id_loader
      LoadPropertyDefinitionsByProjectId.new(@mingle_file_name)
    end  
    
    def team_by_project_id_loader
      LoadTeamByProjectId.new(@mingle_file_name)
    end
    
    def project_variables_by_project_id_loader
      LoadProjectVariablesByProjectId.new(@mingle_file_name)
    end    
    
  end

  class ProjectLoader < Base
    def project
      project_attributes = load_fixtures_for('projects').first
      project = Mingle::Project.new(OpenStruct.new(project_attributes), nil)
      project.card_types_loader = card_types_by_project_id_loader
      project.property_definitions_loader = property_definitions_by_project_id_loader
      project.team_loader = team_by_project_id_loader
      project.project_variables_loader = project_variables_by_project_id_loader
      project
    end
  end

  class LoadCardTypesByProjectId < Base
    def load
      load_fixtures_for('card_types').collect do |ct|
        card_type = Mingle::CardType.new(OpenStruct.new(ct))
        card_type.card_types_property_definitions_loader = card_types_property_definitions_by_card_type_id_loader(ct['id'])
        card_type
      end.sort_by(&:position)
    end  
  end

  class LoadPropertyDefinitionsByProjectId < Base
    def load
      load_fixtures_for('property_definitions').collect do |pd|
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
      load_fixtures_for('card_types_property_definitions').collect do |ctpd|
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
      load_fixtures_for('card_types_property_definitions').collect do |ctpd|
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
      yaml = load_fixtures_for('card_types').detect { |ct| ct['id'] == @card_type_id }
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
      yaml = load_fixtures_for('property_definitions').detect { |pd| pd['id'] == @property_definition_id }
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
      result = load_fixtures_for('property_values').collect do |pv|
        next unless pv['property_definition_id'] == @property_definition_id
        property_value = Mingle::PropertyValue.new(OpenStruct.new(pv))
        property_value.property_definition_loader = property_definition_by_id_loader(pv['property_definition_id'])
        property_value
      end.compact
    end  
  end
  
  class LoadTeamByProjectId < Base
    def load
      load_fixtures_for('users').collect { |user| Mingle::User.new(OpenStruct.new(user)) }
    end  
  end

  class LoadProjectVariablesByProjectId < Base
    def load
      load_fixtures_for('project_variables').collect { |pv| Mingle::ProjectVariable.new(OpenStruct.new(pv)) }
    end  
  end
end
