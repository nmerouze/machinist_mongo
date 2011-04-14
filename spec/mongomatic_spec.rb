require File.dirname(__FILE__) + "/spec_helper"
require "machinist/mongomatic"

Spec::Mongomatic.configure!

class Address < Mongomatic::Base
end

class Person < Mongomatic::Base
end

class Post < Mongomatic::Base
end

class Comment < Mongomatic::Base
end

describe Machinist, "Mongomatic adapter" do

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

    context "attribute assignment" do
      it "should allow assigning a value to an attribute" do
        Post.blueprint { title "1234" }
        post = Post.make
        post[:title].should == "1234"
      end

      it "should allow arbitrary attributes on the base model in its blueprint" do
        Post.blueprint { foo "bar" }
        post = Post.make
        post[:foo].should == "bar"
      end
    end
  end

  describe "make_unsaved method" do
    it "should not save the constructed object" do
      Person.blueprint { }
      person = Person.make_unsaved
      person.should be_new_record
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

end
