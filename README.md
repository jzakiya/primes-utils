# primes-utils

primes-utils is a Rubygem which provides a suite of extremely fast (relative to Ruby's standard library) utility methods for testing and generating primes.

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

Determine if the absolute value of an integer is prime using Miller-Rabin test.  Return 'true' or 'false'.
Miller-Rabin here is super fast, but probabilistic (not deterministic), primality test.
https://en.wikipedia.org/wiki/Miller-Rabin_primality_test
The method's reliability can be increased by increasing the default input parameter of k=20.

```
1111111111111111111.primemr? => true
1111111111111111111.primemr? 50  => true
1111111111111111111.primemr?(50) => true
11111111111111111111.primemr? => false
-3333333333333333333.primemr? => false
0.prime? => false
1.prime? => false
```

<<<<<<< HEAD
**factors(p=13) or prime_division(p=13)**
=======
**factors(p=13) or prime division(p=13)**
>>>>>>> 905fe86436b63568c35a2a392936a19218ed08dd

Determine the prime factorization of the absolute value of an integer.
This replaces the `prime division` method in the `prime.rb` standard library.
Returns an array of arrays of factors and exponents: [[2,4],[3,2],[5,1]] => (2^4)(3^2)(5^1) = (16)(9)(5) = 720
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

**primes(start=0)**

Create an array of primes from the absolute value range (|start| - |end|).
The order of the range doesn't matter if both given: start.primes end  <=> end.prime start
If only one parameter used, then all the primes upto that number will be returned.

```
50.primes => [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
50.primes 125 => [53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113]
300.primes 250 => [251, 257, 263, 269, 271, 277, 281, 283, 293]
541.primes.size => 100
1000.primes(5000).size => 501
(prms = 1000000.primes(1000100)).size => 6
prms.size => 6
prms => [1000003, 1000033, 1000037, 1000039, 1000081, 1000099]
-10.primes -50  => [11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
0.primes => []
1.primes => []
```

**primenth(p=11) or nthprime(p=11)**

Return the value of the nth (absolute value) prime.
Default Strictly Prime (SP) Prime Generator (PG) used here is P11.
Can change SP PG used on input. Acceptable primes range: [3 - 19].

```
1000000.primenth => 15485863
1500000.nthprime => 23879519
2000000.nthprime 13 => 32452843
-500000.nthprime => 7368787
0.nthprime => 0
```

## Coding Implementations
The methods `primemr`, `nthprime/primenth`, and `primes` are coded in pure ruby.
The methods `prime?` and `prime_division/factors` have two implementations.
Each has a pure ruby implementation, and also a hybrid implementation which uses the
Unix cli command `factor` if its available on the host OS. `factor` [5] is an extremely fast
C coded factoring algorithm, part of the GNU Core Utilities package [4].

Upon loading, the gem tests if the desired `factor` command exists on the host OS.
If so, it wraps a system call to it and uses it for `prime?` and `prime_division/factors`. 
If not, it uses a fast pure ruby implementation for each method based on the Sieve of Zakiya (SoZ)[1][2][3].

## Author
Jabari Zakiya

## References
[1]https://www.scribd.com/doc/150217723/Improved-Primality-Testing-and-Factorization-in-Ruby-revised
[2]https://www.scribd.com/doc/228155369/The-Segmented-Sieve-of-Zakiya-SSoZ
<<<<<<< HEAD
[3]https://www.scribd.com/doc/73385696/The-Sieve-of-Zakiya  
[4]https://en.wikipedia.org/wiki/GNU_Core_Utilities  
[5]https://en.wikipedia.org/wiki/Factor_(Unix)

## License
GPL 2.0 or later.
=======
[3]https://www.scribd.com/doc/73385696/The-Sieve-of-Zakiya
[4]https://en.wikipedia.org/wiki/GNU_Core_Utilities
[5]https://en.wikipedia.org/wiki/Factor_(Unix)

## License
GPL 2.0 or later.
>>>>>>> 905fe86436b63568c35a2a392936a19218ed08dd
