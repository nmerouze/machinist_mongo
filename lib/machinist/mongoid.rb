require "machinist"
require "machinist/blueprints"

begin
  require "mongoid"
rescue LoadError
  puts "Mongoid is not installed (gem install mongoid)"
  exit
end

module Machinist
  class Lathe
    def assign_attribute(key, value)
      assigned_attributes[key.to_sym] = value
      if @object.respond_to?("#{key}=")
        @object.send("#{key}=", value)
      else
        @object.process(key => value)
      end
    end
  end
  
  class MongoidAdapter
    class << self
      def has_association?(object, attribute)
        object.class.associations[attribute.to_s]
      end
      
      def class_for_association(object, attribute)
        association = object.class.associations[attribute.to_s]
        association && association.klass
      end

      def assigned_attributes_without_associations(lathe)
        attributes = {}
        lathe.assigned_attributes.each_pair do |attribute, value|
          association = lathe.object.class.associations[attribute.to_s]
          if association && (association.macro == :belongs_to_related) && !value.nil?
            attributes[association.foreign_key.to_sym] = value.id
          else
            attributes[attribute] = value
          end
        end
        attributes        
      end      
    end
  end
  
  module MongoidExtensions
    module Document
      def make(*args, &block)
        lathe = Lathe.run(Machinist::MongoidAdapter, self.new, *args)
        unless Machinist.nerfed? || embedded
          lathe.object.save!
          lathe.object.reload
        end
        lathe.object(&block)
      end
      
      def make_unsaved(*args)
        Machinist.with_save_nerfed { make(*args) }.tap do |object|
          yield object if block_given?
        end
      end
      
      def plan(*args)
        lathe = Lathe.run(Machinist::MongoidAdapter, self.new, *args)
        Machinist::MongoidAdapter.assigned_attributes_without_associations(lathe)
      end
    end
  end
end

Mongoid::Document::ClassMethods.send(:include, Machinist::Blueprints::ClassMethods)
Mongoid::Document::ClassMethods.send(:include, Machinist::MongoidExtensions::Document)
