# Hashids

A small Ruby gem to generate YouTube-like ids from one or many numbers.
Use hashids when you do not want to expose your database ids to the user.

[http://hashids.org/ruby/](http://hashids.org/ruby/)

[![Build Status](https://travis-ci.org/peterhellberg/hashids.rb.svg?branch=master)](http://travis-ci.org/peterhellberg/hashids.rb)
(2.5.1, 2.4.5, 2.3.8, 2.2.10, 2.1.10, 2.0.0, jruby-9.1.17.0, jruby-1.7.27)

## What is it?

hashids (Hash ID's) creates short, unique, decodable hashes from unsigned integers.

_(NOTE: This is **NOT** a true cryptographic hash, since it is reversible)_

It was designed for websites to use in URL shortening, tracking stuff, or
making pages private (or at least unguessable).

This algorithm tries to satisfy the following requirements:

1. Hashes must be unique and decodable.
2. They should be able to contain more than one integer (so you can use them in complex or clustered systems).
3. You should be able to specify minimum hash length.
4. Hashes should not contain basic English curse words (since they are meant to appear in public places - like the URL).

Instead of showing items as `1`, `2`, or `3`, you could show them as `jR`, `k5`, and `l5`.
You don't have to store these hashes in the database, but can encode + decode on the fly.

All integers need to be greater than or equal to zero.

## Installation

Add this line to your application's Gemfile:

    gem 'hashids'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hashids

## Usage

### Encoding one number

You can pass a unique salt value so your hashes differ from everyone else's.
I use **this is my salt** as an example.

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encode(12345)
```

`hash` is now going to be:

    NkK9

### Decoding

Notice during decoding, same salt value is used:

```ruby
hashids = Hashids.new("this is my salt")
numbers = hashids.decode("NkK9")
```

`numbers` is now going to be:

    [ 12345 ]

### Decoding with different salt

Decoding will not work if salt is changed:

```ruby
hashids = Hashids.new("this is my pepper")
numbers = hashids.decode("NkK9")
```

`numbers` is now going to be:

    []

### Encoding several numbers

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encode(683, 94108, 123, 5)
```

`hash` is now going to be:

    aBMswoO2UB3Sj

### Decoding is done the same way

```ruby
hashids = Hashids.new("this is my salt")
numbers = hashids.decode("aBMswoO2UB3Sj")
```

`numbers` is now going to be:

    [ 683, 94108, 123, 5 ]

### Encoding and specifying minimum hash length

Here we encode integer 1, and set the minimum hash length to **8**
(by default it's **0** -- meaning hashes will be the shortest possible length).

```ruby
hashids = Hashids.new("this is my salt", 8)
hash = hashids.encode(1)
```

`hash` is now going to be:

    gB0NV05e

### Decoding with minimum hash length

```ruby
hashids = Hashids.new("this is my salt", 8)
numbers = hashids.decode("gB0NV05e")
```

`numbers` is now going to be:

    [ 1 ]

### Specifying custom hash alphabet

Here we set the alphabet to consist of: "abcdefghijkABCDEFGHIJK12345"

```ruby
hashids = Hashids.new("this is my salt", 0, "abcdefghijkABCDEFGHIJK12345")
hash = hashids.encode(1, 2, 3, 4, 5)
```

`hash` is now going to be:

    dEc4iEHeF3

## Randomness

The primary purpose of hashids is to obfuscate ids. It's not meant or tested to be used for security purposes or compression.
Having said that, this algorithm does try to make these hashes unguessable and unpredictable:

### Repeating numbers

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encode(5, 5, 5, 5)
```

You don't see any repeating patterns that might show there's 4 identical numbers in the hash:

    1Wc8cwcE

Same with incremented numbers:

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encode(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
```

`hash` is now going to be:

    kRHnurhptKcjIDTWC3sx

### Incrementing number ids:

```ruby
hashids = Hashids.new("this is my salt")

hashids.encode 1 #=> NV
hashids.encode 2 #=> 6m
hashids.encode 3 #=> yD
hashids.encode 4 #=> 2l
hashids.encode 5 #=> rD
```

### Encoding using a HEX string

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encode_hex('DEADBEEF')
```

`hash` is now going to be:

    kRNrpKlJ

### Decoding to a HEX string

```ruby
hashids = Hashids.new("this is my salt")
hex_str = hashids.decode_hex("kRNrpKlJ")
```

`hex_str` is now going to be:

    DEADBEEF

## Changelog

**1.0.5**

 - Improve shuffle performance
 - Update rubies used by Travis-CI

**1.0.4**

 - Improved encode/decode performance

**1.0.3**

 - Support for Ruby 2.4.0

**1.0.2**

  - Handle invalid input by raising InputError

**1.0.1**

 - Final alphabet length can now be shorter than the minimum alphabet length
  - `validate_alphabet` now run before setting up seps & guards

**1.0.0**

 - Public functions renamed to be more appropriate:
  - `encrypt` changed to `encode`
  - `encrypt_hex` changed to `encode_hex`
  - `decrypt` changed to `decode`
  - `decrypt_hex` changed to `decode_hex`

**0.3.0**

 - Bumped the version number since hashids.rb now support the new algorithm
 - Support for `encrypt_hex` and `decrypt_hex`

**0.0.3**

 - Default salt (Allows for `Hashids.new.encrypt(91) #=> "kBy"`)
 - Further tweaking of the private methods (`tr/delete` over `gsub`, `scan` over `split`)

**0.0.2**

 - Minitest required if RUBY_VERSION < 1.9.3
 - Using scan over split where appropriate

**0.0.1**

- First commit (Heavily based on the [CoffeeScript version](https://github.com/ivanakimov/hashids.coffee))

## Contact

Follow me [@peterhellberg](http://twitter.com/peterhellberg)

Or [http://c7.se/](http://c7.se/)

## License

MIT License. See the `LICENSE.txt` file.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
