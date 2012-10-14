# encoding: utf-8

require "minitest/spec"
require "minitest/pride"
require "minitest/autorun"

require_relative "../lib/hashids"

describe Hashids do
  let(:salt)              { 'this is my salt' }
  let(:hashids)           { Hashids.new(salt) }
  let(:alphabet)          { "xgzXjp48RaoeLdB6yrAMK9b5n7qEkG" }
  let(:shuffled_alphabet) { "xMGAE6gXkpBR785zLraqnj49doyKeb" }
  let(:default_alphabet)  { "xcS4F6h89aUbideAI7tkynuopqrXCgTE5GBKHLMjfRsz" }
  let(:seps) { ["S", "F", "h", "U", "I", "t", "u", "C", "H", "f", "s"] }
  let(:examples) {
    {
      'aa' => 155, 'ba' => 185, 'j9' => 814,
      'ky' => 342, 'Xg' => 559, 'GB' => 683,
      'B4' => 691, '9Xg' => 4159, 'jAz' => 24599
    }
  }

  describe "setup" do
    it "has a default salt" do
      Hashids.new.encrypt(1,2,3).must_equal "katKSA"
    end

    it "has a default alphabet" do
      Hashids::DEFAULT_ALPHABET.must_equal default_alphabet
    end

    it "has the correct salt" do
      hashids.instance_variable_get(:@salt).must_equal salt
    end

    it "defaults to a min_length of 0" do
      hashids.instance_variable_get(:@min_length).must_equal 0
    end

    it "generates the correct @seps" do
      hashids.instance_variable_get(:@seps).must_equal seps
    end

    it "generates the correct @guards" do
      hashids.instance_variable_get(:@guards).must_equal ["c", "i", "T"]
    end

    it "generates the correct alphabet" do
      hashids.instance_variable_get(:@alphabet).must_equal alphabet
    end
  end

  describe "encrypt" do
    it "encrypts a single number" do
      hashids.encrypt(12345).must_equal 'ryBo'

      hashids.tap { |h|
        h.encrypt(-1).must_equal   ''
        h.encrypt(1).must_equal    'LX'
        h.encrypt(22).must_equal   '5B'
        h.encrypt(333).must_equal  'o49'
        h.encrypt(9999).must_equal 'GKnB'
      }
    end

    it "can encrypt a list of numbers" do
      hashids.encrypt(683, 94108, 123, 5).must_equal 'zBphL54nuMyu5'

      hashids.tap { |h|
        h.encrypt(1,2,3).must_equal 'eGtrS8'
        h.encrypt(2,4,6).must_equal '9Kh7fz'
        h.encrypt(99,25).must_equal 'dAECX'
      }
    end

    it "returns an empty string if no numbers" do
      hashids.encrypt.must_equal ""
    end

    it "returns an empty string if any of the numbers are negative" do
      hashids.encrypt(-1).must_equal ""
      hashids.encrypt(10,-10).must_equal ""
    end

    it "can encrypt to a minumum length" do
      h = Hashids.new(salt, 8)
      h.encrypt(1).must_equal "b9iLXiAa"
    end

    it "can encrypt with a custom alphabet" do
      h = Hashids.new(salt, 0, "abcd")
      h.encrypt(1,2,3,4,5).must_equal 'adcdacddcdaacdad'
    end

    it "does not produce repeating patterns for identical numbers" do
      hashids.encrypt(5,5,5,5).must_equal 'GLh5SMs9'
    end

    it "does not produce repeating patterns for incremented numbers" do
      hashids.encrypt(*(1..10).to_a).must_equal 'zEUzfySGIpuyhpF6HaC7'
    end

    it "does not produce similarities between incrementing number hashes" do
      hashids.encrypt(1).must_equal 'LX'
      hashids.encrypt(2).must_equal 'ed'
      hashids.encrypt(3).must_equal 'o9'
      hashids.encrypt(4).must_equal '4n'
      hashids.encrypt(5).must_equal 'a5'
    end
  end

  describe "decrypt" do
    it "decrypts an encrypted number" do
      hashids.decrypt("ryBo").must_equal [12345]

      hashids.tap { |h|
        h.decrypt('qkpA').must_equal [1337]
        h.decrypt('6aX').must_equal [808]
        h.decrypt('gz9').must_equal [303]
      }
    end

    it "decrypts a list of encrypted numbers" do
      hashids.decrypt('zBphL54nuMyu5').must_equal [683, 94108, 123, 5]

      hashids.tap { |h|
        h.decrypt('kEFy').must_equal [1, 2]
        h.decrypt('Aztn').must_equal [6, 5]
      }
    end

    it "does not decrypt with a different salt" do
      peppers = Hashids.new('this is my pepper')
      hashids.decrypt('ryBo').must_equal [12345]
      peppers.decrypt('ryBo').must_equal []
    end

    it "can decrypt from a hash with a minimum length" do
      h = Hashids.new(salt, 8)
      h.decrypt("b9iLXiAa").must_equal [1]
    end
  end

  describe "setup" do
    it "raises an exception if the alphabet has less than 4 unique chars" do
      -> { Hashids.new('salt', 0, 'abc') }.
        must_raise Hashids::AlphabetError
    end
  end

  describe "validation of attributes" do
    it "raises an ArgumentError unless the salt is a String" do
      -> { Hashids.new(:not_a_string) }.
        must_raise Hashids::SaltError
    end

    it "raises an ArgumentError unless the min_length is a Fixnum" do
      -> { Hashids.new('salt', :not_a_fixnum)}.
        must_raise Hashids::MinLengthError
    end

    it "raises an ArgumentError unless the alphabet is a String" do
      -> { Hashids.new('salt', 2, :not_a_string) }.
        must_raise Hashids::AlphabetError
    end
  end
end
