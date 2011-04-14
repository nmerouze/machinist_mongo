$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"
require "rubygems"
require "rspec"
require "sham"

module Spec
  module MongoMapper
    def self.configure!
      ::MongoMapper.database = "machinist_mongomapper"

      ::Rspec.configure do |config|
        config.before(:each) { Sham.reset }
        config.after(:all)   { ::MongoMapper.database.collections.each { |c| c.remove } }
      end
    end
  end

  module Mongoid
    def self.configure!
      ::Mongoid.configure do |config|
        config.master = Mongo::Connection.new.db("machinist_mongoid")
        config.allow_dynamic_fields = true
      end

      ::Rspec.configure do |config|
        config.before(:each) { Sham.reset }
        config.after(:all)   { ::Mongoid.master.collections.each { |c| c.remove } }
      end
    end
  end

  module Mongomatic
    def self.configure!
      ::Mongomatic.db = Mongo::Connection.new.db("machinist_mongomatic")

      ::Rspec.configure do |config|
        config.before(:each) { Sham.reset }
        config.after(:all)   { ::Mongomatic::Base.db.collections.each { |c| c.remove } }
      end
    end

  end
end
