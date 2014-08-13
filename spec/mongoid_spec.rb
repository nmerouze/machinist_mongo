require File.dirname(__FILE__) + "/spec_helper"
require "machinist/mongoid"

Spec::Mongoid.configure!

class Address
  include Mongoid::Document
  
  field :street
  field :zip
  field :country
  embedded_in :person, :inverse_of => :address
end

class Person
  include Mongoid::Document
  
  field :name, :accessible => false
  field :password
  field :admin, :type => Boolean, :default => false

  embeds_one :address
end

class Post
  include Mongoid::Document
  
  field :title
  field :body
  field :published, :type => Boolean, :default => true
  
  has_many_related :comments
end

class Comment
  include Mongoid::Document
  
  field :body
  field :post_id
  field :author_id
  
  belongs_to_related :post
  belongs_to_related :author, :class_name => "Person"
end

describe Machinist, "Mongoid::Document adapter" do 

  before(:each) do
    Person.clear_blueprints!
    Post.clear_blueprints!
    Comment.clear_blueprints!
  end

  describe "make method" do
    it "should save the constructed object" do
      Person.blueprint { }
      person = Person.make
      person.should_not be_new_record
    end
    
    it "should create an object through embedded_in association" do
      Post.blueprint { }
      Comment.blueprint { post }
      Comment.make.post.class.should == Post
    end
      
    it "should create an object through embedded_in association with a class_name attribute" do
      Person.blueprint { }
      Comment.blueprint { author }
      Comment.make.author.class.should == Person
    end
    
    it "should create an object through embedded_in association using a named blueprint" do
      Post.blueprint { }
      Post.blueprint(:dummy) do
        title { 'Dummy Post' }
      end
      Comment.blueprint { post(:dummy) }
      Comment.make.post.title.should == 'Dummy Post'
    end

    it "should be able to set attributes which are marked as inaccessible" do
      Person.blueprint do
        name { 'Foobar User' }
      end
      Person.make.name.should == 'Foobar User'
    end

    it "should link has_many_related objects back to its parent" do
      Post.blueprint {}
      Comment.blueprint {}
      post = Post.make
      post.comments.make.post.should == post
    end
  end
  
  describe "plan method" do
    it "should not save the constructed object" do
      person_count = Person.count
      Person.blueprint { }
      person = Person.plan
      Person.count.should == person_count
    end
    
    it "should return a regular attribute in the hash" do
      Post.blueprint { title "Test" }
      post = Post.plan
      post[:title].should == "Test"
    end
    
    it "should create an object through a embedded_in association, and return its id" do
      Post.blueprint { }
      Comment.blueprint { post }
      post_count = Post.count
      comment = Comment.plan
      Post.count.should == post_count + 1
      comment[:post].should be_nil
      comment[:post_id].should_not be_nil
    end

    context "attribute assignment" do 
      it "should allow assigning a value to an attribute" do
        Post.blueprint { title "1234" }
        post = Post.make
        post.title.should == "1234"
      end

      it "should allow arbitrary attributes on the base model in its blueprint" do
        Post.blueprint { foo "bar" }
        post = Post.make
        post.foo.should == "bar"
      end
    end
  end
  
  describe "make_unsaved method" do
    it "should not save the constructed object" do
      Person.blueprint { }
      person = Person.make_unsaved
      person.should be_new_record
    end
    
    it "should not save associated objects" do
      pending
      # Post.blueprint { }
      # Comment.blueprint { post }
      # comment = Comment.make_unsaved
      # comment.post.should be_new_record
    end
    
    it "should save objects made within a passed-in block" do
      Post.blueprint { }
      Comment.blueprint { }
      comment = nil
      post = Post.make_unsaved { comment = Comment.make }
      post.should be_new_record
      comment.should_not be_new_record
    end
  end
  
  describe "make method with embedded documents" do
    it "should construct object" do
      Address.blueprint { }
      address = Address.make
      address.should be_instance_of(Address)
    end

    it "should make an embed object" do
      Address.blueprint { }
      Person.blueprint do
        address { Address.make }
      end
      Person.make.address.should be_instance_of(Address)
    end

    it "should allow arbitrary attributes on the base model in its blueprint" do
      Address.blueprint { foo "bar" }
      addr = Address.make
      addr.foo.should == "bar"
    end
  end
  
end
