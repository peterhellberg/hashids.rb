# encoding: utf-8

class Hashids
  VERSION          = "0.0.2"
  DEFAULT_ALPHABET = "xcS4F6h89aUbideAI7tkynuopqrXCgTE5GBKHLMjfRsz"
  PRIMES           = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43]

  class SaltError      < ArgumentError; end
  class MinLengthError < ArgumentError; end
  class AlphabetError  < ArgumentError; end

  def initialize(salt = "", min_length = 0, alphabet = DEFAULT_ALPHABET)
    @salt       = salt
    @min_length = min_length
    @alphabet   = alphabet

    validate_attributes
    setup_alphabet
  end

  def encrypt(*numbers)
    return "" unless numbers.any?

    numbers.each do |number|
      return "" if !number.kind_of?(Fixnum) || number < 0
    end

    encode(numbers, @alphabet, @salt, @min_length)
  end

  def decrypt(hash)
    hash.empty? ? [] : decode(hash)
  end

  private

  def validate_attributes
    unless @salt.kind_of?(String)
      raise Hashids::SaltError, "The salt must be a String"
    end

    unless @min_length.kind_of?(Fixnum)
      raise Hashids::MinLengthError, "The min length must be a Fixnum"
    end

    unless @alphabet.kind_of?(String)
      raise Hashids::AlphabetError, "The alphabet must be a String"
    end
  end

  def setup_alphabet
    @seps   = []
    @guards = []

    @alphabet = @alphabet.split('').uniq.join

    if @alphabet.length < 4
      raise AlphabetError, "Alphabet must contain at least 4 unique characters."
    end

    PRIMES.each do |prime|
      char = @alphabet[prime - 1]

      break if char.nil?

      @seps.push char
      @alphabet.gsub!(char, ' ')
    end

    [0, 4, 8, 12].each do |index|
      separator = @seps[index]

      unless separator.nil?
        @guards.push(separator)
        @seps.delete_at(index)
      end
    end

    @alphabet.gsub!(' ', '')
    @alphabet = consistent_shuffle(@alphabet, @salt)
  end

  def encode(numbers, alphabet, salt, min_length = 0)
    ret = ""

    seps = consistent_shuffle(@seps, numbers).split("")
    lottery_char = ""

    numbers.each_with_index do |number, i|
      if i == 0
        lottery_salt = numbers.join('-')
        numbers.each { |n| lottery_salt += "-" + ((n.to_i + 1) * 2).to_s }

        lottery = consistent_shuffle(alphabet, lottery_salt)

        ret += lottery_char = lottery[0]

        alphabet = lottery_char + alphabet.gsub(lottery_char, '')
      end

      alphabet = consistent_shuffle(alphabet, "#{lottery_char.ord & 12345}#{salt}")
      ret += hash(number, alphabet)

      if (i + 1) < numbers.length
        seps_index = (number + i) % seps.length
        ret += seps[seps_index]
      end
    end

    if ret.length < min_length
      first_index = 0
      numbers.each_with_index do |number, i|
        first_index += (i + 1) * number
      end

      guard_index = first_index % @guards.length
      guard = @guards[guard_index]

      ret = guard + ret

      if ret.length < min_length
        guard_index = (guard_index + ret.length) % @guards.length
        guard = @guards[guard_index]

        ret += guard
      end
    end

    while ret.length < min_length
      pad_array = [alphabet[1].ord, alphabet[0].ord]
      pad_left = encode(pad_array, alphabet, salt)
      pad_right = encode(pad_array, alphabet, pad_array.join(''))

      ret = pad_left + ret + pad_right
      excess = ret.length - min_length

      ret = ret[(excess/2), min_length] if excess > 0
      alphabet = consistent_shuffle(alphabet, salt + ret)
    end

    ret
  end

  def decode(hash)
    ret = []

    if hash.length > 0
      original_hash = hash
      alphabet = ""
      lottery_char = ""

      @guards.each do |guard|
        hash = hash.gsub(guard, ' ')
      end

      hash_split = hash.split(' ')

      hash = hash_split[[3,2].include?(hash_split.length) ? 1 : 0]

      @seps.each do |sep|
        hash = hash.gsub(sep, ' ')
      end

      hash_array = hash.split(' ')

      hash_array.each_with_index do |sub_hash, i|
        if sub_hash.length > 0
          if i == 0
            lottery_char = hash[0]
            sub_hash = sub_hash[1..-1]
            alphabet = lottery_char + @alphabet.gsub(lottery_char, "")
          end

          if alphabet.length > 0 && lottery_char.length > 0
            alphabet = consistent_shuffle(alphabet, (lottery_char.ord & 12345).to_s + "" + @salt)
            ret.push unhash(sub_hash, alphabet)
          end
        end
      end

      ret = [] if encrypt(*ret) != original_hash
    end

    ret
  end

  def consistent_shuffle(alphabet, salt)
    ret = ""

    alphabet = alphabet.join "" if alphabet.respond_to? :join
    salt = salt.join "" if salt.respond_to? :join

    alphabet_array = alphabet.split('')
    salt_array = salt.split('')
    sorting_array = []

    salt_array.push "" unless salt_array.any?

    salt_array.each do |salt_char|
      sorting_array.push salt_char.ord || 0
    end

    sorting_array.each_with_index do |int,i|
      add = true
      k   = i

      while k != (sorting_array.length + i - 1)
        next_index = (k + 1) % sorting_array.length

        if add
          sorting_array[i] += sorting_array[next_index] + (k * i)
        else
          sorting_array[i] -= sorting_array[next_index]
        end

        add = !add
        k += 1
      end

      sorting_array[i] = sorting_array[i].abs
    end

    i = 0

    while alphabet_array.length > 0
      alphabet_size = alphabet_array.length
      pos = sorting_array[i]
      pos %= alphabet_size if pos >= alphabet_size
      ret += alphabet_array[pos]

      alphabet_array.delete_at(pos)
      i = (i+1) % sorting_array.length
    end

    ret
  end

  def hash(number, alphabet)
    hash = ""
    alphabet_length = alphabet.length

    while number > 0
      hash   = alphabet[number % alphabet_length] + hash
      number = number / alphabet_length
    end

    hash
  end

  def unhash(hash, alphabet)
    number = 0

    hash.split('').each_with_index { |char, i|
      pos = alphabet.index char

      return if pos.nil?

      number += pos * alphabet.length ** (hash.length - i - 1)
    }

    number
  end

end
