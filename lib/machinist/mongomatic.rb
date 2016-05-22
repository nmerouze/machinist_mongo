require "machinist"
require "machinist/blueprints"

begin
  require "mongomatic"
rescue LoadError
  puts "Mongomatic is not installed (gem install mongomatic)"
  exit
end

module Machinist
  class Lathe
    def assign_attribute(key, value)
      assigned_attributes[key.to_sym] = value
      if @object.respond_to?("#{key}=")
        @object.send("#{key}=", value)
      elsif @object.respond_to?(:process)
        @object.process(key => value)
      else
        @object[key] = value
      end
    end
  end

  class MongomaticAdapter
    class << self
      def has_association?(object, attribute)
        false
      end

      def class_for_association(object, attribute)
        nil
      end

      def assigned_attributes_without_associations(lathe)
        attributes = {}
        lathe.assigned_attributes.each_pair do |attribute, value|
          attributes[attribute] = value
        end
        attributes
      end
    end
  end

  module MongomaticExtensions
    module Base
      def make(*args, &block)
        lathe = Lathe.run(Machinist::MongomaticAdapter, self.new, *args)
        unless Machinist.nerfed?
          lathe.object.insert
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
        lathe = Lathe.run(Machinist::MongomaticAdapter, self.new, *args)
        Machinist::MongomaticAdapter.assigned_attributes_without_associations(lathe)
      end
    end
  end
end

Mongomatic::Base.send(:extend, Machinist::Blueprints::ClassMethods)
Mongomatic::Base.send(:extend, Machinist::MongomaticExtensions::Base)

