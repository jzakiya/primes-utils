# primes-utils

## Introduction

`primes-utils` is a Rubygem which provides a suite of extremely fast (relative to Ruby's standard library) utility methods for testing and generating primes.

For details on best use practices and implementation details see:

`PRIMES-UTILS HANDBOOK`

https://www.scribd.com/doc/266461408/Primes-Utils-Handbook

Periodically check for updates.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'primes-utils'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install primes-utils
    
Then require as:

    require 'primes/utils'

## Methods

**prime?**

Determine if the absolute value of an integer is prime.  Return 'true' or 'false'.
This replaces the `prime?` method  in the `prime.rb` standard library.

```
101.prime? => true
100.prime? => false
-71.prime? => true
0.prime? => false
1.prime? => false
```

**primemr?(k=20)**

Using Miller-Rabin primality test for integers, return 'true' or 'false'.
Miller-Rabin [6] is super fast, but probabilistic (not deterministic), primality test.
The reliability can be increased by increasing the default input parameter of k=20.

```
1111111111111111111.primemr? => true
1111111111111111111.primemr? 50  => true
1111111111111111111.primemr?(50) => true
11111111111111111111.primemr? => false
-3333333333333333333.primemr? => false
0.prime? => false
1.prime? => false
```

**factors(p=13) or prime_division(p=13)**

Determine the prime factorization of the absolute value of an integer.
This replaces the `prime division` method in the `prime.rb` standard library.
Output is array of arrays of factors and exponents: [[p1,e1],[p2,e2]..[pn,en]]
Default Strictly Prime (SP) Prime Generator (PG) used here is P13.
Can change SP PG used on input. Acceptable primes range: [3 - 19].

```
1111111111111111111.prime_division => [[1111111111111111111, 1]]
11111111111111111111.prime_division  => [[11, 1], [41, 1], [101, 1], [271, 1], [3541, 1], [9091, 1], [27961, 1]]
123456789.factors => [[3, 2], [3607, 1], [3803, 1]]
123456789.factors 17 => [[3, 2], [3607, 1], [3803, 1]]
123456789.factors(17) => [[3, 2], [3607, 1], [3803, 1]]
-12345678.factors => [[2, 1], [3, 2], [47, 1], [14593, 1]]
0.factors => []
1.factors => []
```

**primes(start=0), primesf(start=0), primesmr(start=0)**

Return an array of primes within the absolute value range `(|start| - |end|)`.
The order of the range doesn't matter if both given: `start.primes end  <=> end.prime start`
If only one parameter used, then all the primes upto that number will be returned.
See `PRIMES-UTILS HANDBOOK` for details on best use practices.

```
50.primes => [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
50.primesf 125 => [53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113]
300.primes 250 => [251, 257, 263, 269, 271, 277, 281, 283, 293]
n=10**100; (n-250).primesmr(n+250) => []
541.primes.size => 100
1000.primes(5000).size => 501
(prms = 1000000.primes(1000100)).size => 6
prms.size => 6
prms => [1000003, 1000033, 1000037, 1000039, 1000081, 1000099]
-10.primes -50  => [11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
0.primesf  => []
1.primesmr => []
```

**primescnt(start=0), primescntf(start=0), primescntmr(start=0)**

Provide count of primes within the absolute value range `(|start| - |end|)`.
The order of the range doesn't matter if both given: `start.primes end  <=> end.prime start`
If only one parameter used, the count of all the primes upto that number will be returned.
See `PRIMES-UTILS HANDBOOK` for details on best use practices.

```
100000.primescnt => 9592
100000.primescntf 100500 => 40
n=10**400; (n-500).primescntmr(n+500) => 1
-10.primescnt -50  => 11
0.primescntf  => 0
1.primescntmr => 0
```

**primenth(p=7) or nthprime(p=7)**

Return the value of the (absolute value of) nth prime.
Default Strictly Prime (SP) Prime Generator (PG) used here is P7.
Can change SP PG used on input. Acceptable primes range: [3 - 13].
Currently, parameters are set so that the 1122951705th prime is max.
An error message will be given if requested nth prime is > than max.

```
1000000.primenth => 15485863
1500000.nthprime => 23879519
2000000.nthprime 11 => 32452843
-500000.nthprime => 7368787
1122951705.nthprime => 25741879847
1122951706.primenth => "1122951705 not enough primes, nth approx too small"
0.nthprime => 0
```

**primes_utils**

Displays a list of all the `primes-utils` methods available for your system. 
Use as `x.primes_utils` where x is any `class Integer` value.

```
0.primes_utils => "prime? primemr? primes primesf primesmr primescnt primescntf primescntmr primenth|nthprime factors|prime_division"
```

## Coding Implementations
The methods `primemr?`, `nthprime/primenth`, `primes`, `primescnt`, `primesmr`, and `primescnt` are coded in pure ruby.
The methods `prime?` and `prime_division|factors` have two implementations.
Each has a pure ruby implementation, and a hybrid implementation using the Unix cli command `factor` if its available on the host OS. 
The methods `primesf` and `primescntf` use the `factor` version of `prime?` and are created if it exits.
`factor` [5] is an extremely fast C coded factoring algorithm, part of the GNU Core Utilities package [4].
 
Upon loading, the gem tests if the command `factor` exists on the host OS.
If so, it performs a system call to it within `prime?` and `prime_division/factors`, which uses its output. 
If not, each method uses a fast pure ruby implementation based on the Sieve of Zakiya (SoZ)[1][2][3].

All the `primes-utils` methods are `instance_methods` for `class Integer`.

## Author
Jabari Zakiya

## References
[1]https://www.scribd.com/doc/150217723/Improved-Primality-Testing-and-Factorization-in-Ruby-revised
[2]https://www.scribd.com/doc/228155369/The-Segmented-Sieve-of-Zakiya-SSoZ
[3]https://www.scribd.com/doc/73385696/The-Sieve-of-Zakiya
[4]https://en.wikipedia.org/wiki/GNU_Core_Utilities
[5]https://en.wikipedia.org/wiki/Factor_(Unix)
[6]https://en.wikipedia.org/wiki/Miller-Rabin_primality_test


## License
GPLv2+
