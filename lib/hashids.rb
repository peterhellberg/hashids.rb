# encoding: utf-8

class Hashids
  VERSION  = "0.3.0"

  MIN_ALPHABET_LENGTH = 16
  SEP_DIV             = 3.5
  GUARD_DIV           = 12.0

  DEFAULT_ALPHABET    = "abcdefghijklmnopqrstuvwxyz" +
                        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                        "1234567890"

  attr_reader :salt, :min_hash_length, :alphabet, :seps, :guards

  def initialize(salt = "", min_hash_length = 0, alphabet = DEFAULT_ALPHABET)
    @salt             = salt
    @min_hash_length  = min_hash_length
    @alphabet         = alphabet

    setup_alphabet
  end

  def encrypt(*numbers)
    numbers.flatten! if numbers.length == 1

    if numbers.empty? || numbers.reject { |n| Integer(n) && n >= 0 }.any?
      ""
    else
      encode(numbers)
    end
  end

  def encrypt_hex(str)
    return "" unless str.to_s.match(/\A[0-9a-fA-F]+\Z/)

    numbers = str.scan(/[\w\W]{1,12}/).map do |num|
      "1#{num}".to_i(16)
    end

    encrypt(numbers)
  end

  def decrypt(hash)
    return [] if hash.nil? || hash.empty?

    decode(hash, @alphabet)
  end

  def decrypt_hex(hash)

    ret = ""
    numbers = decrypt(hash)

    numbers.length.times do |i|
      ret += numbers[i].to_s(16)[1 .. -1]
    end

    ret.upcase
  end

  protected

  def encode(numbers)
    ret = ""

    alphabet = @alphabet
    length   = numbers.length
    hash_int = 0

    length.times do |i|
      hash_int += (numbers[i] % (i + 100))
    end

    lottery = ret = alphabet[hash_int % alphabet.length]

    length.times do |i|
      num = numbers[i]
      buf = lottery + salt + alphabet

      alphabet = consistent_shuffle(alphabet, buf[0, alphabet.length])
      last     = hash(num, alphabet)

      ret += last

      if (i + 1) < length
        num %= (last.ord + i)
        ret += seps[num % seps.length]
      end
    end

    if ret.length < min_hash_length
      ret = guards[(hash_int + ret[0].ord) % guards.length] + ret

      if ret.length < min_hash_length
        ret += guards[(hash_int + ret[2].ord) % guards.length]
      end
    end

    half_length = alphabet.length.div(2)

    while(ret.length < min_hash_length)
      alphabet = consistent_shuffle(alphabet, alphabet)
      ret = alphabet[half_length .. -1] + ret + alphabet[0, half_length]

      excess = ret.length - min_hash_length
      ret = ret[excess / 2, min_hash_length] if excess > 0
    end

    ret
  end

  def decode(hash, alphabet)
    ret = []

    breakdown = hash.gsub(/[#{@guards}]/, " ")
    array     = breakdown.split(" ")

    i = [3,2].include?(array.length) ? 1 : 0

    if breakdown = array[i]
      lottery   = breakdown[0]
      breakdown = breakdown[1 .. -1].gsub(/[#{@seps}]/, " ")
      array     = breakdown.split(" ")

      array.length.times do |i|
        sub_hash = array[i]
        buffer   = lottery + salt + alphabet
        alphabet = consistent_shuffle(alphabet, buffer[0, alphabet.length])

        ret.push unhash(sub_hash, alphabet)
      end

      if encode(ret) != hash
        ret = []
      end
    end

    ret
  end

  def consistent_shuffle(alphabet, salt)
    return alphabet if salt.nil? || salt.empty?

    v = 0
    p = 0

    (alphabet.length-1).downto(1) do |i|
      v  = v % salt.length
      p += n = salt[v].ord
      j  = (n + v + p) % i

      tmp_char = alphabet[j]

      alphabet = alphabet[0, j] + alphabet[i] + alphabet[j + 1..-1]
      alphabet = alphabet[0, i] + tmp_char    + alphabet[i + 1..-1]

      v += 1
    end

    alphabet
  end

  def hash(input, alphabet)
    num = input.to_i
    len = alphabet.length
    res   = ""

    begin
      res = "#{alphabet[num % len]}#{res}"
      num = num.div(alphabet.length)
    end while num > 0

    res
  end

  def unhash(input, alphabet)
    num = 0

    input.length.times do |i|
      pos = alphabet.index(input[i])
      num += pos * alphabet.length ** (input.length - i - 1)
    end

    num
  end

  private

  def setup_alphabet
    validate_attributes

    @alphabet = alphabet.split('').uniq.join('')

    setup_seps
    setup_guards

    validate_alphabet
  end

  def setup_seps
    @seps = "cfhistuCFHISTU"

    # seps should contain only characters present in alphabet
    # alphabet should not contains seps

    seps.length.times do |i|
      j = @alphabet.index(seps[i])

      if j.nil?
        @seps = seps[0, i] + " " + seps[i + 1 .. -1]
      else
        @alphabet = alphabet[0, j] + " " + alphabet[j + 1 .. -1]
      end
    end

    alphabet.delete!(' ')
    seps.delete!(' ')

    @seps = consistent_shuffle(seps, salt)

    if seps.length == 0 || (alphabet.length / seps.length.to_f) > SEP_DIV
      seps_length = (alphabet.length / SEP_DIV).ceil
      seps_length = 2 if seps_length == 1

      if seps_length > seps.length
        diff = seps_length - seps.length;

        @seps    += alphabet[0, diff]
        @alphabet = alphabet[diff .. -1]
      else
        @seps = seps[0, seps_length]
      end
    end

    @alphabet = consistent_shuffle(alphabet, salt)
  end

  def setup_guards
    gc = (alphabet.length / GUARD_DIV).ceil

    if alphabet.length < 3
      @guards = seps[0, gc]
      @seps   = seps[gc .. -1]
    else
      @guards   = alphabet[0, gc]
      @alphabet = alphabet[gc .. -1]
    end
  end

  SaltError       = Class.new(ArgumentError)
  MinLengthError  = Class.new(ArgumentError)
  AlphabetError   = Class.new(ArgumentError)

  def validate_attributes
    unless salt.kind_of?(String)
      raise SaltError, "The salt must be a String"
    end

    unless min_hash_length.kind_of?(Fixnum)
      raise MinLengthError, "The min length must be a Fixnum"
    end

    unless min_hash_length >= 0
      raise MinLengthError, "The min length must be 0 or more"
    end

    unless alphabet.kind_of?(String)
      raise AlphabetError, "The alphabet must be a String"
    end

    if alphabet.include?(' ')
      raise AlphabetError, "The alphabet can’t include spaces"
    end
  end

  def validate_alphabet
    unless alphabet.length >= MIN_ALPHABET_LENGTH
      raise AlphabetError, "Alphabet must contain at least " +
                           "#{MIN_ALPHABET_LENGTH} unique characters."
    end
  end
end
