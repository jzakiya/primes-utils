# primes-utils

## Introduction

`primes-utils` is a Rubygem providing a suite of extremely fast methods for testing and generating primes.

For details on the Math and Code used to implement them see:

`PRIMES-UTILS HANDBOOK`

Available for `FREE` to read|download at:

https://www.academia.edu/19786419/PRIMES_UTILS_HANDBOOK

## Installation

Add this line to your application's Gemfile:

```
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

Determine if an integer value is prime, and return `true` or `false`.  
This replaces the `prime?` method  in the `prime.rb` standard library.  
Uses PGT residues tests, then Miller-Rabin test using `primemr?`.

```
101.prime? => true
100.prime? => false
-71.prime? => false
0.prime? => false
1.prime? => false
```

**primemr?(k=5)**

Optimized deterministic (over 64-bits) implementation of Miller-Rabin algorithm.      
Default non-deterministic reliability set at k = 5, set higher if desired for very large numbers > 64-bts.

```
n.prime?(6)
```

**factors or prime_division**

Determine the prime factorization of an +|- integer value.  
Uses Unix coreutils function `factor` if available.  
This replaces the `prime_division` method in the `prime.rb` standard library.  
Multiplying the factors back will produce original number.  
Output is array of tuples of factors and exponents elements: [[p1, e1], [p2, e2],..,[pn, en]].

```
1111111111111111111.prime_division => [[1111111111111111111, 1]]
11111111111111111111.prime_division => [[11, 1], [41, 1], [101, 1], [271, 1], [3541, 1], [9091, 1], [27961, 1]]
123456789.factors => [[3, 2], [3607, 1], [3803, 1]]
-12345678.factors => [[-1, 1], [2, 1], [3, 2], [47, 1], [14593, 1]]
0.factors => []
1.factors => []
```

**factors1**

Pure Ruby version equivalent of `factor`.  
Not as fast as `factor` for some values with multiple large prime factors.  
Always available if OS doesn't have `factor`

**primes(start=0), primesmr(start=0)**

Return an array of prime values within the inclusive integers range `[start_num - end_num]`.  
Input order doesn't matter if both given: `start_num.primes end_num  <=> end_num.prime start_num`.  
A single input is taken as `end_num`, and the primes <= to it are returned.   
`primes` is generally faster, and uses SoZ to compute the range primes.  
`primesmr` is slower, but isn't memory limited, especially for very large numbers|ranges.  
See `PRIMES-UTILS HANDBOOK` for details on best use practices.  
Also see `Error Handling`.

```
50.primes => [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47]
300.primesmr 250 => [251, 257, 263, 269, 271, 277, 281, 283, 293]
n=10**100; (n-250).primesmr(n+250) => []
541.primes.size => 100
1000.primes(5000).size => 501
(prms = 1000000.primes(1000100)).size => 6
prms.size => 6
prms => [1000003, 1000033, 1000037, 1000039, 1000081, 1000099]
101.primes 101 => [101]
1.primes   => []
0.primesmr => []
```

**primescnt(start=0), primescntmr(start=0)**

Provide count of primes within the inclusive integers range `[start_num - end_num]`.  
Input order doesn't matter if both given: `start_num.primes end_num  <=> end_num.prime start_num`.  
A single input is taken as `end_num`, and the primes count <= to it are returned.  
`primescnt` is faster; uses SoZ to identify|count primes from closest hashed value starting point.  
`primescntmr` is slower, but isn't memory limited, especially for very large numbers|ranges.  
See `PRIMES-UTILS HANDBOOK` for details on best use practices.
Also see `Error Handling`.

```
100001.primescnt => 9592
100002.primescnt => 9592
100003.primescnt => 9593
100000.primescntmr 100500 => 40
n=10**400; (n-500).primescntmr(n+500) => 1
n=10**8; (25*n).primescnt => 121443371
0.primescnt   => 0
1.primescntmr => 0
```

**primenth(p=0) or nthprime(p=0)**

Return value of the nth prime.  
Default Strictly Prime (SP) Prime Generator (PG) is adaptively selected.  
Can change SP PG used on input. Default is 7. (Usable are 5, 7, 11, but normally just use default.)   
Indexed nth primes now up to 7 billionth.  
With 16GB mem can compute up to about 35.7+ billionth prime (using `bitarray`).  
Returns `nil` for negative nth inputs. Also see `Error Handling`.

```
1000000.primenth => 15485863
1500000.nthprime => 23879519
2000000.nthprime(7) => 32452843
1122951705.nthprime => 25741879847
n = 10**11; n.primenth -> #<NoMemoryError: failed to allocate memory>
2_123_409_000.nthprime => 50092535639
4_762_719_305.nthprime => 116378528093
7_123_456_789.nthprime => 177058934933
1.primenth  => 2
0.nthprime  => nil
-1.nthprime => nil
```
**next_prime**

Return value of next prime > n. Returns `nil` for negative inputs.

```
100.next_prime => 101
101.next_prime => 103
0.next_prime   => 2
-1.next_prime  => nil
```

**prev_prime**

Return value of previous prime < n > 2. Returns `nil` for n < 2 (and negatives)

```
102.pref_prime => 101
101.prev_prime => 97
3.prev_prime   => 2
2.prev_prime   => nil
-1.prev_prime  => nil 
```

**primes_utils**

Displays a list of all the `primes-utils` methods available for a system.  
Use as eg: `0.primes_utils` where input n is any `class Integer` value.

Available methods for 3.0.0.

```
0.primes_utils => "prime? primes primesmr primescnt primescntmr primenth|nthprime factors|prime_division factors1 next_prime prev_prime primes_utils"
```

## Error Handling
With 3.0.0 the Rubygem `bitarray` is used to extend useable memory for `primes`, `primescnt`, and `nthprime`.
They use private method `sozcores2` to compute the SoZ over the ranges, and returns an array of prime residues positions.
If an input range exceeds system memory to create the array, it switches to using a `bitarray`.
This greatly extends the computable range sizes, at the expense of being slower than using system memory.

There is also the rare possibility you could get a `NoMemoryError: failed to allocate memory` for the methods 
`primes|primesmr` if their list of numerated primes is bigger than the amount of available system memory needed to store them. 
If those methods are used as designed these errors won't occur, so the extra code isn't justified for them.
If they occur you will know why now.

This behavior is referenced to MRI Ruby.

## Coding Implementations
The method `prime_division|factors` has 2 implementations. A pure ruby implementation, and a hybrid implementation 
using the Unix cli command `factor` [5], if available on the host OS. It's an extremely fast C coded factoring algorithm, 
part of the GNU Core Utilities package [4].

Upon loading, the gem tests if the command `factor` exists on the host OS.
If so, it performs a system call to it within `prime_division|factors`, and Ruby reformats its output.
If not, each method uses a fast pure ruby implementation based on the Sieve of Zakiya (SoZ)[1][2][3].

In 3.0.0, YJIT is enabled on install; and the methods coding is optimized for Ruby >= 3.3.

All the `primes-utils` methods are `instance_methods` for `Class Integer`.

## History
```
3.0.4 – YJIT enabled for Ruby >= 3.3, added new methods: next_prime, prev_prime.
        Uses 'bitarray' to extend memory use for methods 'nthprime', 'primes', and 'primescnt'.
2.7.0 – more tweaking adaptive pg selection ranges in select_pg; coded using between? instead of cover?
2.6.0 – much, much better adaptive pg selection algorithm used in select_pg
2.5.1 – corrected minor error in select_pg
2.5.0 – 9 more index primes under the 110-millionth in nths; fixed Ruby 1.8 incompatibility in primes;
        better|simpler technique for select_pg, significant speed increases for large ranges; used now
        in all sozcore2 client methods primes, primescnt and primenth|nthprime; more code cleanups
2.4.0 – fixed error in algorithm when ks resgroup ≤ sqrt(end_num) resgroup; algorithm now split
        arrays when start_num > sqrt(end_num) in sozcore2, whose code also signficantly optimized,
        with API change adding pcs2start value to output parameters to use in primenth, which changed
        to use it; ruby idiom code opt for set_start_value; consolidated pcs_to_num | pcs_to_start_num
        functions into one new pcs_to_num, with associated changes in sozcore1|2; primes|cnt also
        significantly faster resulting from sozcore2 changes; massive code cleanups all-arround; added
        private methods select_pg (to adaptively select the pg used in primes), and array_check (used in
        sozcore2 to catch array creation out-of-memory errors)
2.3.0 – primescnt now finds primes up to some integer much faster, and for much larger integers
        increased index nth primes to over 2 billionth; used in nthprime|primenth and primescnt
2.2.0 – for sozcore2: refactored to include more common code; changed output api; added memory
        error messages when prms and prms_range arrays creation fails; for primenth: used new
        function to compute parameter b and removed ceiling for it; increased number of index primes
        in nths; primes, primescnt, and primenth|nthprime also refactored, will use all available mem
2.1.0 – changed default PG in primes and primescnt from P13 to P5, significantly faster
2.0.0 – new methods primesf, primesmr, primescnt, primescntf, primescntmr, primes_utils
        also improved mem efficiency/speed and extended range for primes and primenth
        changed default PG in nthprime|primenth from P11 to P7, major refactoring of all methods
1.1.1 – more efficient/faster code to count up to nth prime in primenth
1.1.0 – new nth prime approximation method in primenth
1.0.6 – fixed n=1 check error for prime?
1.0.5 – minor bug fix
1.0.4 – fixed n=0 case for primenth; fixed subtle bug in primes, refactored to generalize code
1.0.3 – minor bug fix
1.0.2 – directly test for cli command factor on installed platform at start
1.0.1 – check if using Ruby 1.8 at start, if so, require 'rational' library for gcd method
1.0.0 – initial release April 1, 2015 with methods prime?, primemr?, primes, prime_division|factors, primenth|nthprime
```
## Author
Jabari Zakiya

## References
[1] https://www.scribd.com/doc/150217723/Improved-Primality-Testing-and-Factorization-in-Ruby-revised   
[2] https://www.scribd.com/doc/228155369/The-Segmented-Sieve-of-Zakiya-SSoZ   
[3] https://www.scribd.com/doc/73385696/The-Sieve-of-Zakiya   
[4] https://en.wikipedia.org/wiki/GNU_Core_Utilities   
[5] https://en.wikipedia.org/wiki/Factor_(Unix)   
[6] https://en.wikipedia.org/wiki/Miller-Rabin_primality_test   
[7] https://www.academia.edu/105821370/Twin_Primes_Segmented_Sieve_of_Zakiya_SSoZ_Explained_Review_Article

## License
LGPL-2.0-or-later
