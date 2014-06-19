require "machinist"
require "machinist/blueprints"
begin
  require "mongo_mapper"
  require "mongo_mapper/embedded_document"
rescue LoadError
  puts "MongoMapper is not installed (gem install mongo_mapper)"
  exit
end

module Machinist

  class Lathe
    def assign_attribute(key, value)
      assigned_attributes[key.to_sym] = value
      if @object.respond_to? "#{key}="
        @object.send("#{key}=", value)
      else
        @object[key] = value
      end
    end
  end

  class MongoMapperAdapter
    def self.has_association?(object, attribute)
      object.class.associations[attribute]
    end

    def self.class_for_association(object, attribute)
      association = object.class.associations[attribute]
      association && association.klass
    end

    def self.assigned_attributes_without_associations(lathe)
      attributes = {}
      lathe.assigned_attributes.each_pair do |attribute, value|
        association = lathe.object.class.associations[attribute]
        if association && association.belongs_to? && !value.nil?
          attributes[association.foreign_key.to_sym] = value.id
        else
          attributes[attribute] = value
        end
      end
      attributes
    end
  end

  module MongoMapperExtensions

    module Document
      extend ActiveSupport::Concern
        
      module ClassMethods
        include Machinist::Blueprints::ClassMethods

        def make(*args, &block)
          lathe = Lathe.run(Machinist::MongoMapperAdapter, self.new, *args)
          unless Machinist.nerfed?
            lathe.object.save!
            lathe.object.reload
          end
          lathe.object(&block)
        end

        def make_unsaved(*args)
          Machinist.with_save_nerfed{ make(*args) }.tap do |object|
            yield object if block_given?
          end
        end

        def plan(*args)
          lathe = Lathe.run(Machinist::MongoMapperAdapter, self.new, *args)
          Machinist::MongoMapperAdapter.assigned_attributes_without_associations(lathe)
        end
      end
    end

    module EmbeddedDocument
      extend ActiveSupport::Concern

      module ClassMethods
        include Machinist::Blueprints::ClassMethods

        def make(*args, &block)
          lathe = Lathe.run(Machinist::MongoMapperAdapter, self.new, *args)
          lathe.object(&block)
        end
      end
    end
  end
end

module MongoMapper::Document
  include Machinist::MongoMapperExtensions::Document
end

module MongoMapper::EmbeddedDocument
  include Machinist::MongoMapperExtensions::EmbeddedDocument
end
