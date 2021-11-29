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
      _(Hashids::DEFAULT_ALPHABET).must_equal default_alphabet
    end

    it "has default separators" do
      _(Hashids::DEFAULT_SEPS).must_equal default_seps
    end

    it "has a default salt" do
      _(Hashids.new.encode(1,2,3)).must_equal "o2fXhV"
    end

    it "has the correct salt" do
      _(hashids.instance_variable_get(:@salt)).must_equal salt
    end

    it "defaults to a min_length of 0" do
      _(hashids.instance_variable_get(:@min_hash_length)).must_equal 0
    end

    it "generates the correct seps" do
      _(hashids.instance_variable_get(:@seps)).must_equal seps
    end

    it "generates the correct @guards" do
      _(hashids.instance_variable_get(:@guards)).must_equal guards
    end

    it "generates the correct alphabet" do
      _(hashids.instance_variable_get(:@alphabet)).must_equal alphabet
    end

    it "has a minimum alphabet length" do
      _(-> {
        Hashids.new("", 0, 'shortalphabet')
      }).must_raise Hashids::AlphabetError
    end

    it "has a final alphabet length that can be shorter than the minimum" do
      _(Hashids.new("this is my salt", 0, 'cfhistuCFHISTU01').
        alphabet).must_equal "10"
    end

    it "checks the alphabet for spaces" do
      _(-> {
        Hashids.new("", 0, 'abc odefghijklmnopqrstuv')
      }).must_raise Hashids::AlphabetError
    end
  end

  describe "encode" do
    it "encodes a single number" do
      _(hashids.encode(12345)).must_equal 'NkK9'

      hashids.tap do |h|
        _(h.encode(-1)).must_equal          ''
        _(h.encode(1)).must_equal           'NV'
        _(h.encode(22)).must_equal          'K4'
        _(h.encode(333)).must_equal         'OqM'
        _(h.encode(9999)).must_equal        'kQVg'
        _(h.encode(123_000)).must_equal     '58LzD'
        _(h.encode(456_000_000)).must_equal '5gn6mQP'
        _(h.encode(987_654_321)).must_equal 'oyjYvry'
      end
    end

    it "can encode a list of numbers" do
      hashids.tap do |h|
        _(h.encode(1,2,3)).must_equal "laHquq"
        _(h.encode(2,4,6)).must_equal "44uotN"
        _(h.encode(99,25)).must_equal "97Jun"

        _(h.encode(1337,42,314)).
          must_equal "7xKhrUxm"

        _(h.encode(683, 94108, 123, 5)).
          must_equal "aBMswoO2UB3Sj"

        _(h.encode(547, 31, 241271, 311, 31397, 1129, 71129)).
          must_equal "3RoSDhelEyhxRsyWpCx5t1ZK"

        _(h.encode(21979508, 35563591, 57543099, 93106690, 150649789)).
          must_equal "p2xkL3CK33JjcrrZ8vsw4YRZueZX9k"
      end
    end

    it "can encode a list of numbers passed in as an array" do
      _(hashids.encode([1,2,3])).must_equal "laHquq"
    end

    it "can encode  string encoded number" do
      _(hashids.encode('1')).must_equal "NV"
      _(hashids.encode('-1')).must_equal ""
    end

    it "raises exception if integer conversion fails" do
      _(-> { hashids.encode('-') }).must_raise ArgumentError
    end

    it "returns an empty string if no numbers" do
      _(hashids.encode).must_equal ""
    end

    it "returns an empty string if any of the numbers are negative" do
      _(hashids.encode(-1)).must_equal ""
      _(hashids.encode(10,-10)).must_equal ""
    end

    it "can encode to a minumum length" do
      h = Hashids.new(salt, 18)
      _(h.encode(1)).must_equal "aJEDngB0NV05ev1WwP"

      _(h.encode(4140, 21147, 115975, 678570, 4213597, 27644437)).
        must_equal "pLMlCWnJSXr1BSpKgqUwbJ7oimr7l6"
    end

    it "can encode with a custom alphabet" do
      h = Hashids.new(salt, 0, "ABCDEFGhijklmn34567890-:")
      _(h.encode(1,2,3,4,5)).must_equal "6nhmFDikA0"
    end

    it "does not produce repeating patterns for identical numbers" do
      _(hashids.encode(5,5,5,5)).must_equal "1Wc8cwcE"
    end

    it "does not produce repeating patterns for incremented numbers" do
      _(hashids.encode(*(1..10).to_a)).must_equal "kRHnurhptKcjIDTWC3sx"
    end

    it "does not produce similarities between incrementing number hashes" do
      _(hashids.encode(1)).must_equal 'NV'
      _(hashids.encode(2)).must_equal '6m'
      _(hashids.encode(3)).must_equal 'yD'
      _(hashids.encode(4)).must_equal '2l'
      _(hashids.encode(5)).must_equal 'rD'
    end
  end

  describe "encode_hex" do
    it "encodes hex string" do
      hashids.tap { |h|
        _(h.encode_hex("FA")).must_equal    "lzY"
        _(h.encode_hex("26dd")).must_equal  "MemE"
        _(h.encode_hex("FF1A")).must_equal  "eBMrb"
        _(h.encode_hex("12abC")).must_equal "D9NPE"
        _(h.encode_hex("185b0")).must_equal "9OyNW"
        _(h.encode_hex("17b8d")).must_equal "MRWNE"

        _(h.encode_hex("1d7f21dd38")).must_equal "4o6Z7KqxE"
        _(h.encode_hex("20015111d")).must_equal "ooweQVNB"
      }
    end

    it "returns an empty string if passed non-hex string" do
      _(hashids.encode_hex("XYZ123")).must_equal ""
    end
  end

  describe "decode" do
    it "decodes an encoded number" do
      _(hashids.decode("NkK9")).must_equal [12345]
      _(hashids.decode("5O8yp5P")).must_equal [666555444]
      _(hashids.decode("KVO9yy1oO5j")).must_equal [666555444333222]

      hashids.tap { |h|
        _(h.decode("Wzo")).must_equal [1337]
        _(h.decode("DbE")).must_equal [808]
        _(h.decode("yj8")).must_equal [303]
      }
    end

    it "decodes a list of encoded numbers" do
      _(hashids.decode("1gRYUwKxBgiVuX")).must_equal [66655,5444333,2,22]
      _(hashids.decode('aBMswoO2UB3Sj')).must_equal [683, 94108, 123, 5]

      hashids.tap { |h|
        _(h.decode('jYhp')).must_equal [3, 4]
        _(h.decode('k9Ib')).must_equal [6, 5]

        _(h.decode('EMhN')).must_equal [31, 41]
        _(h.decode('glSgV')).must_equal [13, 89]
      }
    end

    it "does not decode with a different salt" do
      peppers = Hashids.new('this is my pepper')

      _(hashids.decode('NkK9')).must_equal [12345]
      _(peppers.decode('NkK9')).must_equal []
    end

    it "can decode from a hash with a minimum length" do
      h = Hashids.new(salt, 8)
      _(h.decode("gB0NV05e")).must_equal [1]

      _(h.decode("mxi8XH87")).must_equal [25, 100, 950]
      _(h.decode("KQcmkIW8hX")).must_equal [5,200,195, 1]
    end

    it "handles invalid input by raising InputError" do
      _(-> { hashids.decode('asdf-') }).must_raise Hashids::InputError
    end
  end

  describe "decode_hex" do
    it "decodes hex string" do
      _(hashids.decode_hex("lzY")).must_equal "FA"
      _(hashids.decode_hex("eBMrb")).must_equal "FF1A"
      _(hashids.decode_hex("D9NPE")).must_equal "12ABC"
    end
  end

  describe "setup" do
    it "raises an exception if the alphabet has less than 16 unique chars" do
      _(-> { Hashids.new('salt', 0, 'abc') }).
        must_raise Hashids::AlphabetError
    end
  end

  describe "validation of attributes" do
    it "raises an ArgumentError unless the salt is a String" do
      _(-> { Hashids.new(:not_a_string) }).
        must_raise Hashids::SaltError
    end

    it "raises an ArgumentError unless the min_length is an Integer" do
      _(-> { Hashids.new('salt', :not_an_integer)}).
        must_raise Hashids::MinLengthError
    end

    it "raises an ArgumentError unless the alphabet is a String" do
      _(-> { Hashids.new('salt', 2, :not_a_string) }).
        must_raise Hashids::AlphabetError
    end
  end

  describe "protected methods" do
    describe "unhash" do
      it "unhashes" do
        _(hashids.send(:unhash, 'bb',     'abc')).must_equal 4
        _(hashids.send(:unhash, 'aaa',    'abc')).must_equal 0
        _(hashids.send(:unhash, 'cba',    'abc')).must_equal 21
        _(hashids.send(:unhash, 'cbaabc', 'abc')).must_equal 572
        _(hashids.send(:unhash, 'aX11b',  'abcXYZ123')).must_equal 2728
      end
    end

    describe "internal_decode" do
      it "decodes" do
        _(hashids.send(:internal_decode, 'NV', alphabet)).must_equal [1]
      end
    end

    describe "consistent_shuffle" do
      it "returns the alphabet if empty salt" do
        _(hashids.send(:consistent_shuffle, default_alphabet, '')).
          must_equal default_alphabet
      end

      it "shuffles consistently" do
        _(hashids.send(:consistent_shuffle,    'ab', salt)).must_equal 'ba'
        _(hashids.send(:consistent_shuffle,   'abc', salt)).must_equal 'bca'
        _(hashids.send(:consistent_shuffle,  'abcd', salt)).must_equal 'cadb'
        _(hashids.send(:consistent_shuffle, 'abcde', salt)).must_equal 'dceba'

        _(hashids.send(:consistent_shuffle, default_alphabet, 'salt')).
          must_equal "f17a8zvCwo0iuqYDXlJ4RmAS2end5gh" +
                     "TcpjbOWLK9GFyE6xUI3ZBMQtPsNHrkV"

        _(hashids.send(:consistent_shuffle, 'abcdefghijklmnopqrstuvwxyz', salt)).
          must_equal 'fcaodykrgqvblxjwmtupzeisnh'
      end
    end

    describe "hash" do
      it "hashes" do
        _(hashids.send(:hash,      12, 'abcdefg')).must_equal "bf"
        _(hashids.send(:hash,      42, 'abcdefg')).must_equal "ga"
        _(hashids.send(:hash,     123, 'abcdefg')).must_equal "cde"
        _(hashids.send(:hash,    1024, 'abcdefg')).must_equal "cggc"
        _(hashids.send(:hash,  950000, 'abcdefg')).must_equal "bbadeefc"
        _(hashids.send(:hash,  950000, 'åäö-ÅÄÖ')).must_equal "ääå-ÅÅÄö"
        _(hashids.send(:hash, 3500000, 'abcdefg')).must_equal "ebfbfaea"
        _(hashids.send(:hash, 3500000, 'Xyz01-å')).must_equal "1y-y-X1X"
      end
    end

    describe "unhash" do
      it "unhashes" do
        _(hashids.send(:unhash, 'abbd', 'abcdefg')).must_equal 59
        _(hashids.send(:unhash, 'abcd', 'abcdefg')).must_equal 66
        _(hashids.send(:unhash, 'acac', 'abcdefg')).must_equal 100
        _(hashids.send(:unhash, 'acfg', 'abcdefg')).must_equal 139
        _(hashids.send(:unhash, 'x21y', 'xyz1234')).must_equal 218
        _(hashids.send(:unhash, 'yy44', 'xyz1234')).must_equal 440
        _(hashids.send(:unhash, '1xzz', 'xyz1234')).must_equal 1045
      end
    end
  end
end
