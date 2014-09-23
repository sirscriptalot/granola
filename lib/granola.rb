require "multi_json"
require "granola/version"

module Granola
  # A Serializer describes how to serialize a certain type of object, by
  # declaring the structure of JSON objects.
  class Serializer
    attr_reader :object

    # Public: Instantiates a list serializer that wraps around an iterable of
    # objects of the type expected by this serializer class.
    #
    # Example:
    #
    #   serializer = PersonSerializer.list(people)
    #   serializer.to_json
    #
    # Returns a Granola::List.
    def self.list(ary)
      List.new(ary, self)
    end

    # Public: Initialize the serializer with a given object.
    #
    # object - The domain model that we want to serialize into JSON.
    def initialize(object)
      @object = object
    end

    # Public: Returns the Hash of attributes that should be serialized into
    # JSON.
    #
    # Raises NotImplementedError unless you override in subclasses.
    def attributes
      fail NotImplementedError
    end

    # Public: Generate the JSON string using the current MultiJson adapter.
    #
    # **options - Any options valid for `MultiJson.dump`.
    #
    # Returns a String.
    def to_json(**options)
      MultiJson.dump(attributes, options)
    end
  end

  # Internal: The List serializer provides an interface for serializing lists of
  # objects, wrapping around a specific serializer.
  #
  # Example:
  #
  #   serializer = Granola::List.new(people, PersonSerializer)
  #   serializer.to_json
  #
  # You should use Serializer.list instead of this class.
  class List < Serializer
    # Internal: Get the serializer class to use for each item of the list.
    attr_reader :item_serializer

    # Public: Instantiate a new list serializer.
    #
    # list       - An Array-like structure.
    # serializer - A subclass of Granola::Serializer.
    def initialize(list, serializer)
      @item_serializer = serializer
      @list = list.map { |obj| serializer.new(obj) }
    end

    # Public: Returns an Array of Hashes that can be serialized into JSON.
    def attributes
      @list.map(&:attributes)
    end
  end
end