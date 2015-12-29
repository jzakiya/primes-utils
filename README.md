# primes-utils

## Introduction

`primes-utils` is a Rubygem which provides a suite of extremely fast utility methods for testing and generating primes.

For details on the Math and Code used to implement them see:

`PRIMES-UTILS HANDBOOK`

Now available and `FREE` to view and download at:

https://www.scribd.com/doc/266461408/Primes-Utils-Handbook


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
n=10**1700; (n+469).primemr? => true
0.primemr? => false
1.primemr? => false
```

**factors(p=13) or prime_division(p=13)**

Determine the prime factorization of the absolute value of an integer.
This replaces the `prime_division` method in the `prime.rb` standard library.
Output is array of arrays of factors and exponents: [[p1,e1],[p2,e2]..[pn,en]].
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
The order of the range doesn't matter if both given: `start.primes end  <=> end.prime start`.
If only one parameter used, then all the primes up to that number will be returned.
See `PRIMES-UTILS HANDBOOK` for details on best use practices.
Also see `Error Handling`.

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
n=10**20; n.primes n+n  -> ERROR1: range size too big for available memory. => nil
n=10**20; n.primes 100  -> ERROR2: end_num too big for available memory. => nil
n=10**8;  (25*n).primes -> ERROR3: not enough memory to store all primes in output array. => nil
0.primesf  => []
1.primesmr => []
```

**primescnt(start=0), primescntf(start=0), primescntmr(start=0)**

Provide count of primes within the absolute value range `(|start| - |end|)`.
The order of the range doesn't matter if both given: `start.primes end  <=> end.prime start`.
If only one parameter used, the count of all the primes up to that number will be returned.
See `PRIMES-UTILS HANDBOOK` for details on best use practices.
Also see `Error Handling`.

```
100001.primescnt => 9592
100002.primescnt => 9592
100003.primescnt => 9593
100000.primescntf 100500 => 40
n=10**400; (n-500).primescntmr(n+500) => 1
-10.primescnt -50  => 11
n=10**20; n.primescnt n+n -> ERROR1: range size too big for available memory. => nil
n=10**20; n.primescnt 100 -> ERROR2: end_num too big for available memory. => nil
n=10**8; (25*n).primescnt => 121443371
0.primescntf  => 0
1.primescntmr => 0
```

**primenth(p=7) or nthprime(p=7)**

Return the value of the (absolute value of) nth prime.
Default Strictly Prime (SP) Prime Generator (PG) is adaptively selected.
Can change SP PG used on input. Acceptable primes range: [3 - 13].
Indexed nth primes now upto 2.01 billionth.
Also see `Error Handling`.

```
1000000.primenth => 15485863
1500000.nthprime => 23879519
2000000.nthprime 11 => 32452843
-500000.nthprime => 7368787
1122951705.nthprime => 25741879847
n = 10**11; n.primenth -> ERROR1: range size too big for available memory. => nil
0.nthprime => 0
1.primenth => 2
```

**primes_utils**

Displays a list of all the `primes-utils` methods available for your system.
Use as `n.primes_utils` where n is any `class Integer` value.

```
0.primes_utils => "prime? primemr? primes primesf primesmr primescnt primescntf primescntmr primenth|nthprime factors|prime_division primes_utils"
```

## Error Handling
Starting with 2.2.0, error handling has been implemented to gracefully fail when array creation requires more memory than available.
This occurs when the range size, or end_num, need arrays greater than the amount of avalable memory. The first case shows the message
`ERROR1: range size too big for available memory.` and the second case `ERROR2: end_num too big for available memory.`
The affected methods are `primes`, `primescnt`, and `nthprime|primenth`.
`nthprime|primenth` also displays the error message `<pcnt> not enough primes, approx nth too small.` 
(`<pcnt>` is computed count of primes) when the computed approx_nth value is < nth value (though this should never happen by design).
With 2.4.0 error handling was added to `primes` that catches the error and displays message `ERROR3: not enough memory to store all primes in output array.`.
For all errors, the return value for each method is `nil`.

There is also the rare possibility you could get a `NoMemoryError: failed to allocate memory` for the methods 
`primesf` and `primesmr` if their list of numerated primes is bigger than the amount of available system memory needed to store them. 
If those methods are used as designed these errors won't occur, so the extra code isn't justified for them.
If they occur you will know why now.

This behavior is referenced to MRI Ruby.

## Coding Implementations
The methods `primemr?`, `nthprime|primenth`, `primes`, `primescnt`, `primesmr`, and `primescnt` are coded in pure ruby.
The methods `prime?` and `prime_division|factors` have two implementations.
Each has a pure ruby implementation, and a hybrid implementation using the Unix cli command `factor` if its available on the host OS. 
The methods `primesf` and `primescntf` use the `factor` version of `prime?` and are created if it exits.
`factor` [5] is an extremely fast C coded factoring algorithm, part of the GNU Core Utilities package [4].

Upon loading, the gem tests if the command `factor` exists on the host OS.
If so, it performs a system call to it within `prime?` and `prime_division|factors`, which uses its output.
If not, each method uses a fast pure ruby implementation based on the Sieve of Zakiya (SoZ)[1][2][3].
New in 2.2.0, upon loading with Ruby 1.8 `require 'rubygems'` is invoked to enable installing gems.

All the `primes-utils` methods are `instance_methods` for `class Integer`.

## History
```
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
2.3.0 – primescnt now finds primes upto some integer much faster, and for much larger integers
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
[1]https://www.scribd.com/doc/150217723/Improved-Primality-Testing-and-Factorization-in-Ruby-revised
[2]https://www.scribd.com/doc/228155369/The-Segmented-Sieve-of-Zakiya-SSoZ
[3]https://www.scribd.com/doc/73385696/The-Sieve-of-Zakiya
[4]https://en.wikipedia.org/wiki/GNU_Core_Utilities
[5]https://en.wikipedia.org/wiki/Factor_(Unix)
[6]https://en.wikipedia.org/wiki/Miller-Rabin_primality_test

## License
GPLv2+
