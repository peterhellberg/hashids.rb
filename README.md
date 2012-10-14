# Hashids

A small Ruby gem to generate YouTube-like hashes from one or many numbers.
Use hashids when you do not want to expose your database ids to the user.

[http://www.hashids.org/ruby/](http://www.hashids.org/ruby/)

[![Build Status](https://secure.travis-ci.org/peterhellberg/hashids.rb.png)](http://travis-ci.org/peterhellberg/hashids.rb)
(1.9.2, 1.9.3, jruby-19mode, rbx-19mode and ruby-head)

## What is it?

hashids (Hash ID's) creates short, unique, decryptable hashes from unsigned integers.

It was designed for websites to use in URL shortening, tracking stuff, or 
making pages private (or at least unguessable).

This algorithm tries to satisfy the following requirements:

1. Hashes must be unique and decryptable.
2. They should be able to contain more than one integer (so you can use them in complex or clustered systems).
3. You should be able to specify minimum hash length.
4. Hashes should not contain basic English curse words (since they are meant to appear in public places - like the URL).

Instead of showing items as `1`, `2`, or `3`, you could show them as `U6dc`, `u87U`, and `HMou`.
You don't have to store these hashes in the database, but can encrypt + decrypt on the fly.

All integers need to be greater than or equal to zero.

## Installation

Add this line to your application's Gemfile:

    gem 'hashids'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hashids

## Usage

#### Encrypting one number

You can pass a unique salt value so your hashes differ from everyone else's. I use "**this is my salt**" as an example.

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encrypt(12345)
```

`hash` is now going to be:

    ryBo

#### Decrypting

Notice during decryption, same salt value is used:

```ruby
hashids = Hashids.new("this is my salt")
numbers = hashids.decrypt("ryBo")
```

`numbers` is now going to be:

    [ 12345 ]

#### Decrypting with different salt

Decryption will not work if salt is changed:

```ruby
hashids = Hashids.new("this is my pepper")
numbers = hashids.decrypt("ryBo")
```

`numbers` is now going to be:

    []

#### Encrypting several numbers

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encrypt(683, 94108, 123, 5)
```

`hash` is now going to be:

    zBphL54nuMyu5
  
#### Decrypting is done the same way

```ruby
hashids = Hashids.new("this is my salt")
numbers = hashids.decrypt("zBphL54nuMyu5")
```

`numbers` is now going to be:

    [ 683, 94108, 123, 5 ]

#### Encrypting and specifying minimum hash length

Here we encrypt integer 1, and set the minimum hash length to **8** (by default it's **0** -- meaning hashes will be the shortest possible length).

```ruby
hashids = Hashids.new("this is my salt", 8)
hash = hashids.encrypt(1)
```

`hash` is now going to be:

    b9iLXiAa

#### Decrypting

```ruby
hashids = Hashids.new("this is my salt", 8)
numbers = hashids.decrypt("b9iLXiAa")
```

`numbers` is now going to be:

    [ 1 ]

#### Specifying custom hash alphabet

Here we set the alphabet to consist of only four letters: "abcd"

```ruby
hashids = Hashids.new("this is my salt", 0, "abcd")
hash = hashids.encrypt(1, 2, 3, 4, 5)
```

`hash` is now going to be:

    adcdacddcdaacdad

## Randomness

The primary purpose of hashids is to obfuscate ids. It's not meant or tested to be used for security purposes or compression.
Having said that, this algorithm does try to make these hashes unguessable and unpredictable:

#### Repeating numbers

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encrypt(5, 5, 5, 5)
```

You don't see any repeating patterns that might show there's 4 identical numbers in the hash:

    GLh5SMs9

Same with incremented numbers:

```ruby
hashids = Hashids.new("this is my salt")
hash = hashids.encrypt(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
```

`hash` will be :

    zEUzfySGIpuyhpF6HaC7

### Incrementing number hashes:

```ruby
hashids = Hashids.new("this is my salt")

hashids.encrypt 1 #=> LX
hashids.encrypt 2 #=> ed
hashids.encrypt 3 #=> o9
hashids.encrypt 4 #=> 4n
hashids.encrypt 5 #=> a5
```

## Changelog

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
