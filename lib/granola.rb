require "granola/version"
require "json"

module Granola
  class << self
    # Public: Get/Set a Proc that takes an Object and a Hash of options and
    # returns a JSON String.
    #
    # The default implementation uses the standard library's JSON module, but
    # you're welcome to swap it out.
    #
    # Example:
    #
    #   require "yajl"
    #   Granola.json = ->(obj, **opts) { Yajl::Encoder.encode(obj, opts) }
    attr_accessor :json
  end

  if defined?(MultiJson)
    self.json = MultiJson.method(:dump)
  else
    self.json = JSON.method(:generate)
  end

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
    def self.list(ary, *args)
      List.new(ary, *args, with: self)
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

    # Public: Generate the JSON String.
    #
    # **options - Any options to be passed to the `Granola.json` Proc.
    #
    # Returns a String.
    def to_json(**options)
      Granola.json.(attributes, options)
    end

    # Public: Returns the MIME type generated by this serializer. By default
    # this will be `application/json`, but you can override in your serializers
    # if your API uses a different MIME type (e.g. `application/my-app+json`).
    #
    # Returns a String.
    def mime_type
      "application/json".freeze
    end
  end

  # Internal: The List serializer provides an interface for serializing lists of
  # objects, wrapping around a specific serializer. The preferred API for this
  # is to use `Granola::Serializer.list`.
  #
  # Example:
  #
  #   serializer = Granola::List.new(people, with: PersonSerializer)
  #   serializer.to_json
  #
  # You should use Serializer.list instead of this class.
  class List < Serializer
    # Internal: Get the serializer class to use for each item of the list.
    attr_reader :item_serializer

    # Public: Instantiate a new list serializer.
    #
    # list  - An Array-like structure.
    # *args - Any other arguments that the item serializer takes.
    #
    # Keywords:
    #   with: The subclass of Granola::Serializer to use when serializing
    #         specific elements in the list.
    def initialize(list, *args, with: serializer)
      @item_serializer = with
      @list = list.map { |obj| @item_serializer.new(obj, *args) }
    end

    # Public: Returns an Array of Hashes that can be serialized into JSON.
    def attributes
      @list.map(&:attributes)
    end
  end
end
