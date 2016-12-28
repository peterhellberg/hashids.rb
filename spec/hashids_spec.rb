# encoding: utf-8

require "minitest/autorun"
require "minitest/spec"
require "minitest/pride"

require_relative "../lib/hashids"

describe Hashids do
  let(:salt)              { 'this is my salt' }
  let(:seps)              { 'UHuhtcITCsFifS'  }
  let(:guards)            { 'AdG0'            }
  let(:hashids)           { Hashids.new(salt) }

  let(:default_seps) {
    "cfhistuCFHISTU"
  }

  let(:default_alphabet)  {
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  }

  let(:alphabet)          {
    "5N6y2rljDQak4xgzn8ZR1oKYLmJpEbVq3OBv9WwXPMe7"
  }

  describe "setup" do
    it "has a default alphabet" do
      Hashids::DEFAULT_ALPHABET.must_equal default_alphabet
    end

    it "has default separators" do
      Hashids::DEFAULT_SEPS.must_equal default_seps
    end

    it "has a default salt" do
      Hashids.new.encode(1,2,3).must_equal "o2fXhV"
    end

    it "has the correct salt" do
      hashids.instance_variable_get(:@salt).must_equal salt
    end

    it "defaults to a min_length of 0" do
      hashids.instance_variable_get(:@min_hash_length).must_equal 0
    end

    it "generates the correct seps" do
      hashids.instance_variable_get(:@seps).must_equal seps
    end

    it "generates the correct @guards" do
      hashids.instance_variable_get(:@guards).must_equal guards
    end

    it "generates the correct alphabet" do
      hashids.instance_variable_get(:@alphabet).must_equal alphabet
    end

    it "has a minimum alphabet length" do
      -> {
        Hashids.new("", 0, 'shortalphabet')
      }.must_raise Hashids::AlphabetError
    end

    it "has a final alphabet length that can be shorter than the minimum" do
      Hashids.new("this is my salt", 0, 'cfhistuCFHISTU01').
        alphabet.must_equal "10"
    end

    it "checks the alphabet for spaces" do
      -> {
        Hashids.new("", 0, 'abc odefghijklmnopqrstuv')
      }.must_raise Hashids::AlphabetError
    end
  end

  describe "encode" do
    it "encodes a single number" do
      hashids.encode(12345).must_equal 'NkK9'

      hashids.tap do |h|
        h.encode(-1).must_equal          ''
        h.encode(1).must_equal           'NV'
        h.encode(22).must_equal          'K4'
        h.encode(333).must_equal         'OqM'
        h.encode(9999).must_equal        'kQVg'
        h.encode(123_000).must_equal     '58LzD'
        h.encode(456_000_000).must_equal '5gn6mQP'
        h.encode(987_654_321).must_equal 'oyjYvry'
      end
    end

    it "can encode a list of numbers" do
      hashids.tap do |h|
        h.encode(1,2,3).must_equal "laHquq"
        h.encode(2,4,6).must_equal "44uotN"
        h.encode(99,25).must_equal "97Jun"

        h.encode(1337,42,314).
          must_equal "7xKhrUxm"

        h.encode(683, 94108, 123, 5).
          must_equal "aBMswoO2UB3Sj"

        h.encode(547, 31, 241271, 311, 31397, 1129, 71129).
          must_equal "3RoSDhelEyhxRsyWpCx5t1ZK"

        h.encode(21979508, 35563591, 57543099, 93106690, 150649789).
          must_equal "p2xkL3CK33JjcrrZ8vsw4YRZueZX9k"
      end
    end

    it "can encode a list of numbers passed in as an array" do
      hashids.encode([1,2,3]).must_equal "laHquq"
    end

    it "can encode  string encoded number" do
      hashids.encode('1').must_equal "NV"
      hashids.encode('-1').must_equal ""
    end

    it "raises exception if integer conversion fails" do
      -> { hashids.encode('-') }.must_raise ArgumentError
    end

    it "returns an empty string if no numbers" do
      hashids.encode.must_equal ""
    end

    it "returns an empty string if any of the numbers are negative" do
      hashids.encode(-1).must_equal ""
      hashids.encode(10,-10).must_equal ""
    end

    it "can encode to a minumum length" do
      h = Hashids.new(salt, 18)
      h.encode(1).must_equal "aJEDngB0NV05ev1WwP"

      h.encode(4140, 21147, 115975, 678570, 4213597, 27644437).
        must_equal "pLMlCWnJSXr1BSpKgqUwbJ7oimr7l6"
    end

    it "can encode with a custom alphabet" do
      h = Hashids.new(salt, 0, "ABCDEFGhijklmn34567890-:")
      h.encode(1,2,3,4,5).must_equal "6nhmFDikA0"
    end

    it "does not produce repeating patterns for identical numbers" do
      hashids.encode(5,5,5,5).must_equal "1Wc8cwcE"
    end

    it "does not produce repeating patterns for incremented numbers" do
      hashids.encode(*(1..10).to_a).must_equal "kRHnurhptKcjIDTWC3sx"
    end

    it "does not produce similarities between incrementing number hashes" do
      hashids.encode(1).must_equal 'NV'
      hashids.encode(2).must_equal '6m'
      hashids.encode(3).must_equal 'yD'
      hashids.encode(4).must_equal '2l'
      hashids.encode(5).must_equal 'rD'
    end
  end

  describe "encode_hex" do
    it "encodes hex string" do
      hashids.tap { |h|
        h.encode_hex("FA").must_equal    "lzY"
        h.encode_hex("26dd").must_equal  "MemE"
        h.encode_hex("FF1A").must_equal  "eBMrb"
        h.encode_hex("12abC").must_equal "D9NPE"
        h.encode_hex("185b0").must_equal "9OyNW"
        h.encode_hex("17b8d").must_equal "MRWNE"

        h.encode_hex("1d7f21dd38").must_equal "4o6Z7KqxE"
        h.encode_hex("20015111d").must_equal "ooweQVNB"
      }
    end

    it "returns an empty string if passed non-hex string" do
      hashids.encode_hex("XYZ123").must_equal ""
    end
  end

  describe "decode" do
    it "decodes an encoded number" do
      hashids.decode("NkK9").must_equal [12345]
      hashids.decode("5O8yp5P").must_equal [666555444]
      hashids.decode("KVO9yy1oO5j").must_equal [666555444333222]

      hashids.tap { |h|
        h.decode("Wzo").must_equal [1337]
        h.decode("DbE").must_equal [808]
        h.decode("yj8").must_equal [303]
      }
    end

    it "decodes a list of encoded numbers" do
      hashids.decode("1gRYUwKxBgiVuX").must_equal [66655,5444333,2,22]
      hashids.decode('aBMswoO2UB3Sj').must_equal [683, 94108, 123, 5]

      hashids.tap { |h|
        h.decode('jYhp').must_equal [3, 4]
        h.decode('k9Ib').must_equal [6, 5]

        h.decode('EMhN').must_equal [31, 41]
        h.decode('glSgV').must_equal [13, 89]
      }
    end

    it "does not decode with a different salt" do
      peppers = Hashids.new('this is my pepper')

      hashids.decode('NkK9').must_equal [12345]
      peppers.decode('NkK9').must_equal []
    end

    it "can decode from a hash with a minimum length" do
      h = Hashids.new(salt, 8)
      h.decode("gB0NV05e").must_equal [1]

      h.decode("mxi8XH87").must_equal [25, 100, 950]
      h.decode("KQcmkIW8hX").must_equal [5,200,195, 1]
    end

    it "handles invalid input by raising InputError" do
      -> { hashids.decode('asdf-') }.must_raise Hashids::InputError
    end
  end

  describe "decode_hex" do
    it "decodes hex string" do
      hashids.decode_hex("lzY").must_equal "FA"
      hashids.decode_hex("eBMrb").must_equal "FF1A"
      hashids.decode_hex("D9NPE").must_equal "12ABC"
    end
  end

  describe "setup" do
    it "raises an exception if the alphabet has less than 16 unique chars" do
      -> { Hashids.new('salt', 0, 'abc') }.
        must_raise Hashids::AlphabetError
    end
  end

  describe "validation of attributes" do
    it "raises an ArgumentError unless the salt is a String" do
      -> { Hashids.new(:not_a_string) }.
        must_raise Hashids::SaltError
    end

    it "raises an ArgumentError unless the min_length is an Integer" do
      -> { Hashids.new('salt', :not_an_integer)}.
        must_raise Hashids::MinLengthError
    end

    it "raises an ArgumentError unless the alphabet is a String" do
      -> { Hashids.new('salt', 2, :not_a_string) }.
        must_raise Hashids::AlphabetError
    end
  end

  describe "protected methods" do

    describe "unhash" do
      it "unhashes" do
        hashids.send(:unhash, 'bb',     'abc').must_equal 4
        hashids.send(:unhash, 'aaa',    'abc').must_equal 0
        hashids.send(:unhash, 'cba',    'abc').must_equal 21
        hashids.send(:unhash, 'cbaabc', 'abc').must_equal 572
        hashids.send(:unhash, 'aX11b',  'abcXYZ123').must_equal 2728
      end
    end

    describe "internal_decode" do
      it "decodes" do
        hashids.send(:internal_decode, 'NV', alphabet).must_equal [1]
      end
    end

    describe "consistent_shuffle" do
      it "returns the alphabet if empty salt" do
        hashids.send(:consistent_shuffle, default_alphabet, '').
          must_equal default_alphabet
      end

      it "shuffles consistently" do
        hashids.send(:consistent_shuffle,    'ab', salt).must_equal 'ba'
        hashids.send(:consistent_shuffle,   'abc', salt).must_equal 'bca'
        hashids.send(:consistent_shuffle,  'abcd', salt).must_equal 'cadb'
        hashids.send(:consistent_shuffle, 'abcde', salt).must_equal 'dceba'

        hashids.send(:consistent_shuffle, default_alphabet, 'salt').
          must_equal "f17a8zvCwo0iuqYDXlJ4RmAS2end5gh" +
                     "TcpjbOWLK9GFyE6xUI3ZBMQtPsNHrkV"

        hashids.send(:consistent_shuffle, 'abcdefghijklmnopqrstuvwxyz', salt).
          must_equal 'fcaodykrgqvblxjwmtupzeisnh'
      end
    end

    describe "hash" do
      it "hashes" do
        hashids.send(:hash,      12, 'abcdefg').must_equal "bf"
        hashids.send(:hash,      42, 'abcdefg').must_equal "ga"
        hashids.send(:hash,     123, 'abcdefg').must_equal "cde"
        hashids.send(:hash,    1024, 'abcdefg').must_equal "cggc"
        hashids.send(:hash,  950000, 'abcdefg').must_equal "bbadeefc"
        hashids.send(:hash,  950000, 'åäö-ÅÄÖ').must_equal "ääå-ÅÅÄö"
        hashids.send(:hash, 3500000, 'abcdefg').must_equal "ebfbfaea"
        hashids.send(:hash, 3500000, 'Xyz01-å').must_equal "1y-y-X1X"
      end
    end

    describe "unhash" do
      it "unhashes" do
        hashids.send(:unhash, 'abbd', 'abcdefg').must_equal 59
        hashids.send(:unhash, 'abcd', 'abcdefg').must_equal 66
        hashids.send(:unhash, 'acac', 'abcdefg').must_equal 100
        hashids.send(:unhash, 'acfg', 'abcdefg').must_equal 139
        hashids.send(:unhash, 'x21y', 'xyz1234').must_equal 218
        hashids.send(:unhash, 'yy44', 'xyz1234').must_equal 440
        hashids.send(:unhash, '1xzz', 'xyz1234').must_equal 1045
      end
    end
  end
end
