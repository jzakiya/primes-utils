# Enable YJIT if using CRuby >= 3.3"
RubyVM::YJIT.enable if RUBY_ENGINE == "ruby" and RUBY_VERSION.to_f >= 3.3

require "bitarray"

module Primes
  module Utils
    # Upon loading, determine if platform has cli command 'factor'

    @@os_has_factor = false
    begin
      if `factor 10`.split(' ') == ['10:', '2', '5']
        @@os_has_factor = true
      end
    rescue
      @@os_has_factor = false
    end

    begin RUBY = RUBY_ENGINE rescue RUBY = 'ruby'.freeze end

    if @@os_has_factor  # for platforms with cli 'factor' command

      # Return prime factors of n in form [[-1,1],[p1,e1],...[pn,en]]
      # Use Linux|Unix coreutils cli command 'factor' for speed and large numbers
      def factors
        factors = self < 0 ? [-1] : []
        factors += `factor #{abs}`.split(' ')[1..-1].map(&:to_i)
        factors.group_by { |prm| prm }.map { |prm, exp| [prm, exp.size] }
      end

      alias  prime_division  factors

      puts "Using cli 'factor' for factors|prime_division"

    end  # use pure ruby versions for platforms without cli command 'factor'

    # Return prime factors of n in form [[-1,1],[p1,e1],..[pn,en]]
    # Uses P7 as default PG to generate factoring primes
    def factors1
      modpg, rescnt = 210, (48 + 4)         # P7's modulus and residues count
      residues = [2,3,5,7, 11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,
                 97,101,103,107,109,113,121,127,131,137,139,143,149,151,157,163,
                167,169,173,179,181,187,191,193,197,199,209,211]

      factors = self < 0 ? [-1] : []        # returns [] for 0|1; [-1, 1] for negatives
      num = self.abs                        # factor only non-negative integers

      unless num.prime? || (num | 1) == 1   # skip factoring if num is prime, 0, or 1
        modk, r, r0 = 0, 0, 4               # r0 is index for P7's first residue 11
        until num.prime? || num == 1        # find factors until num is prime or 1
          while prime = modk + residues[r]
            (factors << prime; num /= prime; break) if (num % prime).zero?
            (r = r0; modk += modpg) if (r = r.succ) == rescnt
      end end end
      factors << num if num > 1
      factors.group_by{ |prm| prm}.map{ |prm, exp| [prm, exp.size] }
    end

    # Use pure Ruby version of `factor` if not in OS.
    alias prime_division factors1 unless @@os_has_factor

    # Return value of nth prime for self >= 1, or nil if self < 1
    # Adaptively selects best SP PG, unless valid input PG given at runtime
    def primenth(p = 0)
      return nil if (n = self) < 1
      seeds = PRIMES
      return seeds[n - 1] if n <= seeds.size

      start_num, nth, nthflag = set_start_value(n, true)
      return start_num if nthflag      # output nthprime value if n a ref prime key
      end_num = approx_nthprime(n)     # close approx to nth >= real nth

      (primes = seeds[0..seeds.index(p)]; modpg = primes.reduce(:*)) if seeds.include? p
      primes, modpg = select_pg(end_num, start_num) unless primes

      prms, m, _, residues, pcs_to_start, * = sozcore2(end_num, start_num, modpg)
      return unless prms               # exit gracefully if sozcore2 mem error

      # starting at start_num's location, find nth prime within given range
      pcnt = n > nth ? nth - 1 : primes.size

      while pcnt < n; pcnt = pcnt.succ if prms[m].zero?; m = m.succ end
      k, r = (m + pcs_to_start - 1).divmod residues.size
      modpg * k + residues[r]
    end

    alias  nthprime  primenth          # to make life easier

    # List of primes within inputs range: start_num - end_num
    # Adaptively selects Strictly Prime (SP) Prime Generator
    def primes(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)

      primes, modpg = select_pg(end_num, start_num)   # adaptively select PG
      prms, m, modk, residues, _, r = sozcore2(end_num, start_num, modpg)
      return unless prms               # exit gracefully if sozcore2 mem error
      rescnt, modpg, maxprms = residues.size, residues[-1] - 1, prms.size

      # init 'primes' w/any modulus primes in range, extract primes from prms
      primes.select! { |p| p.between?(start_num, end_num) }

      # Find, numerate, and store primes from sieved pcs in prms for range
      while m < maxprms
        primes << modk + residues[r] if prms[m].zero?; m = m.succ
        (r = 0; modk += modpg) if (r = r.succ) == rescnt
      end
      primes
    end

    # Count of primes within inputs range: start_num - end_num
    # Adaptively selects Strictly Prime (SP) Prime Generator
    def primescnt(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)

      nthflag, nth = nil, 0
      if start_num < 3                 # for all primes upto num
        start_num, nth, nthflag = set_start_value(end_num, false) # closest nth value
        return nth unless nthflag      # output num's key|count if ref nth value
      end

      primes, modpg = select_pg(end_num, start_num) # adaptively select PG
      prms, m, _ = sozcore2(end_num, start_num, modpg)
      return unless prms               # exit gracefully if sozcore2 mem error

      # init prmcnt for any modulus primes in range; count primes in prms
      prmcnt = primes.count { |p| p.between?(start_num, end_num) }
      prmcnt = nth - 1 if nthflag && (nth > 0)  # start count for small range
      max = prms.size
      while m < max; prmcnt = prmcnt.succ if prms[m].zero?; m = m.succ end
      prmcnt
    end

    # List of primes within inputs range: start_num - end_num
    # Uses 'primemr?' to check primality of prime candidates in range
    def primesmr(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)
      r, modk, residues, primes = sozcore1(end_num, start_num)
      rescnt, modpg = residues.size, residues[-1] - 1

      while end_num >= (pc = modk + residues[r])
        primes << pc if pc.primemr?
        (r = 0; modk += modpg) if (r = r.succ) == rescnt
      end
      primes
    end

    # Count of primes within inputs range: start_num - end_num
    # Uses 'primemr?' to check primality of prime candidates in range
    def primescntmr(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)

      nthflag, nth = nil, 0
      if start_num < 3                 # for all primes upto num
        start_num, nth, nthflag = set_start_value(end_num, false) # closest nth value
        return nth unless nthflag      # output num's key|count if ref nth value
      end

      r, modk, residues, mod_primes = sozcore1(end_num, start_num)
      rescnt, modpg, primescnt = residues.size, residues[-1] - 1, mod_primes.size
      primescnt = nth - 1 if nthflag && (nth > 0)  # set count for nth prime < num

      while end_num >= (pc = modk + residues[r])
        primescnt = primescnt.succ if pc.primemr?
        (r = 0; modk += modpg) if (r = r.succ) == rescnt
      end
      primescnt
    end

    # PGT and Miller-Rabin combined primality tests for random n
    def prime?(k = 5)        # Can change k up|down for primemr?
      # Use PGT residue checks for small values < PRIMES.last**2
      return PRIMES.include? self if self <= PRIMES.last
      return false if MODPN.gcd(self) != 1
      return true  if self < PRIMES_LAST_SQRD
      primemr?(k)
    end

    # Returns the next prime number for self >= 0, or nil if n < 0
    def next_prime
      return nil if (n = self) < 0                 # return nil if n negative
      return (n >> 1) + 2 if n <= 2                # return 2 or 3 if n is 0|1|2
      n = n + 1 | 1                                # 1st odd number > n
      until (res = n % 6) & 0b11 == 1; n += 2 end  # n first P3 pc >= n, w/residue 1 or 5
      inc = (res == 1) ? 4 : 2                     # set its P3 PGS value, inc by 2 and 4
      until n.primemr?; n += inc; inc ^= 0b110 end # find first prime P3 pc
      n
    end

    # Returns the previous prime number < self, or nil if self <= 2
    def prev_prime
      return nil if (n = self) <= 2                # no primes for n <= 2
      return (n >> 1) + 1 if n <= 5                # 5|4 -> 3, 3 -> 2
      n = n - 2 | 1                                # 1st odd number < n
      until (res = n % 6) & 0b11 == 1; n -= 2 end  # n first P3 pc <= n, w/residue 1 or 5
      dec = (res == 1) ? 2 : 4                     # set its P3 PGS value, dec by 2 and 4
      until n.primemr?; n -= dec; dec ^= 0b110 end # find first prime P3 pc
      n
    end

    def primes_utils
      # display list of available methods
      methods = %w[prime? primemr? primes primesmr primescnt
                   primescntmr primenth|nthprime factors|prime_division
                   factors1 next_prime prev_prime primes_utils].join(" ")
    end

    # Miller-Rabin primality test; uses deterministic witnesses for values upto 128-bits
    # Returns true if self is a prime number, else returns false.
    def primemr? (k = 5)               # k is default number of random bases
      return false if self < 2         # return false for 0|1 and negatives
      neg_one_mod = n = d = self - 1   # these are even as self is always odd
      d >>= 2 while (d & 0b11) == 0; d >>= (d & 1)^1  # make d odd number
      # wits = [range, [wit_prms]] or nil
      wits = WITNESS_RANGES.find { |range, wits| range > self }
      witnesses = wits ? wits[1] : k.times.map{ rand(self - 4) + 2 }
      witnesses.each do |b|
        next if (b % self).zero?       # **skip base if a multiple of input**
        y = b.pow(d, self)             # y = (b**d) mod self
        s = d                          # set s to odd d value
        until y == 1 || y == neg_one_mod || s == n
          y = y.pow(2, self)           # y = (y**2) mod self
          s <<= 1                      # multiply s by 2 until its n
        end
        return false unless y == neg_one_mod || s.odd?
      end
      true
    end

    private

    # Best known deterministic witnnesses for given range and set of bases
    # https://miller-rabin.appspot.com/
    # https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
    WITNESS_RANGES = {
      341_531 => [9345883071009581737],
      1_050_535_501 => [336781006125, 9639812373923155],
      350_269_456_337 => [4230279247111683200, 14694767155120705706, 16641139526367750375],
      55_245_642_489_451 => [2, 141889084524735, 1199124725622454117, 11096072698276303650],
      7_999_252_175_582_851 => [2, 4130806001517, 149795463772692060, 186635894390467037, 3967304179347715805],
      585_226_005_592_931_977 => [2, 123635709730000, 9233062284813009, 43835965440333360, 761179012939631437, 1263739024124850375],
      18_446_744_073_709_551_615 => [2, 325, 9375, 28178, 450775, 9780504, 1795265022],
      318_665_857_834_031_151_167_461   => [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37],
      3_317_044_064_679_887_385_961_981 => [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]
    }

    MODPN  = 232862364358497360900063316880507363070 # 101# (101 primorial) is largest for u128
    PRIMES = [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103]
    PRIMES_LAST_SQRD = PRIMES.last ** 2

    # Return correct order for inputs range values start_num|end_num
    # If either are negative then raise an error
    def check_inputs(end_num, start_num)
      raise "invalid negative input(s)" if end_num < 0 || start_num < 0
      end_num, start_num = start_num, end_num if start_num > end_num
      [end_num, start_num]
    end

    # Returns for SP PG mod value array of residues [r0, r1,..mod-1, mod+1]
    def make_residues(modpg)
      return [ 7, 11, 13, 17, 19, 23, 29, 31] if modpg == 30
      return [11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
             73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 121, 127, 131, 137,
             139, 143, 149, 151, 157, 163, 167, 169, 173, 179, 181, 187, 191,
             193, 197, 199, 209, 211] if modpg == 210
      residues = []
      rc, inc, midmod = 13, 4, modpg / 2
      while rc < midmod
        residues << rc << (modpg - rc) if modpg.gcd(rc) == 1
        rc += inc; inc ^= 0b110
      end
      residues.sort << (modpg - 1) << (modpg + 1)
    end

    # Determine number of pcs upto the effective start, end, and range width.
    # The effective start_num is first pc >= start_num, first pc <= end_num,
    # and effective range is number of pcs between them (inclusive).
    # inputs:  end_num and start_num of range, and PGs residues array
    # outputs: pcs_to_end   - number of pcs in <= end_num pc for PG
    #          pcs_to_start - number of pcs < effective start_num pc for range
    #          r1           - residue index for effective start_num pc
    #          modk1        - mod resgroup value for effective start_num pc
    #          pcs_in_range - total number of pcs in effective range
    def pcs_to_nums(end_num, start_num, residues)
      modpg, rescnt = residues[-1] - 1, residues.size
      end_num,   k2 = end_num   < residues[0] ? [1, 0] : [(end_num - 1)|1, ((end_num - 1)|1)/modpg]
      start_num, k1 = start_num < residues[0] ? [1, 0] : [start_num - 1,   (start_num - 2)/modpg]
      r1, r2, resk1, resk2  = 0, 0, start_num - (modk1 = k1 * modpg), end_num - (k2 * modpg)
      r1 = r1.succ while resk1 >= residues[r1]
      r2 = r2.succ while resk2 >= residues[r2]
      pcs_to_end, pcs_to_start = k2 * rescnt + r2, k1 * rescnt + r1
      [pcs_to_end, pcs_to_start, r1, modk1, (pcs_in_range = pcs_to_end - pcs_to_start)]
    end

    # Select SP Prime Generator to parametize the pcs within inputs range
    # inputs:  end_num and start_num of range
    # outputs: r        - residue index value for start_num of pc inputs range
    #          modk     - resgroup  base value for start_num
    #          residues - array of residues [r0...mod+1] for PG
    #          primes   - array of modulus primes in range, if any
    def sozcore1(end_num, start_num)
      range = end_num - start_num
      modpg = if    range <    100_001;       210  #  P7; Math.isqrt(10_000_200_001)
              elsif range <  7_071_267;    30_030  # P13; Math.isqrt(50_002_816_985_289)
              elsif range < 24_494_897;   510_510  # P17; Math.isqrt(600_000_000_000_000)
              else                      9_699_690  # P19
              end
      residues = make_residues(modpg)              # chosen PG residues
      primes = PRIMES.select { |p| p < residues[0] && p.between?(start_num, end_num) }
      start_num = start_num < residues[0] ? 1 : start_num - 1
      k = (start_num - 1) / modpg; modk = k * modpg; r = 0; resk = start_num - modk
      r = r.succ while resk >= residues[r]
      [r, modk, residues, primes]
    end

    # Perform SoZ with given Prime Generator and return array of parameters
    # inputs:  end_num and start_num of inputs range and modulus value for PG
    # outputs: prms - binary (0,1) array of pcs within a range or to end_num
    #          m    - num of pcs in prms < start_num; so prms[m] = start_num
    #          modks    - modulus value for start_num's resgroup
    #          residues - array of residues for PG: [r1..modpg-1, modpg+1]
    #          pcs2start- number of pcs < start_num pc
    #          rs       - residue index location for first pc >= start_num
    def sozcore2(end_num, start_num, modpg)
      residues = make_residues(modpg); rescnt = residues.size
      pcs_to_end, pcs_to_start, rs, modks, pcs_range = pcs_to_nums(end_num, start_num, residues)
      sqrtN, maxpcs, inputs_range = Integer.sqrt(end_num), pcs_to_end, end_num - start_num
      pcs_to_sqrtN, _ = pcs_to_nums(sqrtN, 0, residues) # num pcs <= sqrtN

      m = pcs_to_start                      # index to start retrieving primes in prms array
      split_arrays = (start_num > sqrtN)    # flag, true for split arrays
      if split_arrays                       # if start_num > sqrtN create two arrays
        maxpcs = pcs_to_sqrtN               # array size now for primary sieve array prms
        prms_range = array_check(pcs_range) # array for pcs in range
        raise 'ERROR1: range too big for free sys mem.' unless prms_range
        m = 0                               # address to start of split array
      end
      prms = array_check(maxpcs)            # array for pcs upto sqrtN, or end_num
      raise 'ERROR2: end_num too big for available sys mem.' unless prms

      # Sieve of Zakiya (SoZ) to eliminate nonprimes from prms, prms_range
      pcs_to_sqrtN.times do |i|             # sieve primes from pcs upto sqrt(end_num)
        next unless prms[i].zero?           # if pc not prime, get next one
        prm_r = residues[i % rescnt]        # save its residue value
        prime = modpg*(k=i/rescnt) + prm_r  # numerate its value; set k resgroup value
        rem   = start_num % prime           # prime's modular distance to start_num
        next unless (prime - rem <= inputs_range) || rem == 0 # skip prime if no multiple in range
        prmstep = prime * rescnt            # compute its primestep
        residues.each do |ri|               # find|mark its multiples
          # convert (prime * (modk + ri)) pc value to its address in prms
          kn, rr = (prm_r * ri - 2).divmod modpg
          prm_mult = (k*(prime + ri) + kn)*rescnt + residues.index(rr+2) # 1st prime mult
          while prm_mult < maxpcs; prms[prm_mult] = 1; prm_mult += prmstep end
          if split_arrays                                  # when start_num > sqrtN(pcs2sqrtN+1)
            prm_mult = (pcs_to_start - prm_mult) % prmstep # (start_num - last mult) pcs
            prm_mult = prmstep - prm_mult if prm_mult != 0 # location in range, or beyond
            while prm_mult < pcs_range; prms_range[prm_mult] = 1; prm_mult += prmstep end
      end end end
      # select prms array and start location val m for start_num in it
      [(split_arrays ? prms_range : prms), m, modks, residues, pcs_to_start, rs]
    end

    # Compute close approximate nthprime value >= real value
    def approx_nthprime(n)
      e = if    n <= 26_800_000;                                0.008702
          elsif n.between?(   26_800_001,     144_000_000 - 0); 0.0088
          elsif n.between?(  144_000_001,     250_000_000 - 1); 0.00881
          elsif n.between?(  250_000_000,     800_000_000 - 1); 0.008798
          elsif n.between?(  800_000_000,   1_000_000_000 - 1); 0.00875
          elsif n.between?(1_000_000_000,   2_000_000_000 - 1); 0.008732
          elsif n.between?(2_000_000_000,   3_000_000_000 - 1); 0.0086806
          elsif n.between?(3_000_000_000,   4_000_000_000 - 1); 0.0086448
          elsif n.between?(4_000_000_000,   5_000_000_000 - 1); 0.00862
          elsif n.between?(5_000_000_000,   5_500_000_000 - 0); 0.008596
          elsif n.between?(5_500_000_001,   6_500_000_000 - 0); 0.0085859
          elsif n.between?(6_500_000_001,   7_500_000_000 - 0); 0.0085687
          elsif n.between?(7_500_000_001,   8_500_000_000 - 0); 0.008554
          elsif n.between?(8_500_000_001,   9_500_000_000 - 0); 0.008541
          elsif n.between?(9_500_000_001, 100_000_000_000 - 0); 0.0085283
          else                                                  0.00825
          end
      b = 0.5722 * (n**e)
      a = b * Math.log(log_n = Math.log(n))
      (n * (log_n + a) + 3).to_i
    end

    # Adaptively select Strictly Prime (SP) Prime Generator
    def select_pg(end_num, start_num)       # adaptively select PG
      range = end_num - start_num
      pg = 5
      if start_num <= Integer.sqrt(end_num) # for one array of primes upto N
        pg =  7 if end_num >  50 * 10**4
        pg = 11 if end_num > 305 * 10**5
      else                                  # for split array cases
        pg =  7 if (range.between?(10**6, 10**7 - 1) && start_num < 10**8)       ||
                   (range.between?(10**7, 10**8 - 1) && start_num < 46 * 10**8)  ||
                   (range.between?(10**8, 10**9 - 1) && start_num < 16 * 10**10) ||
                   (range >= 10**9 && start_num < 26 * 10**12)
        pg = 11 if (range.between?(10**8, 10**9 - 1) && start_num < 55 * 10**7)  ||
                   (range >= 10**9 && start_num < 45 * 10**9)
      end
      primes = PRIMES.select { |p| p <= pg }
      [primes, primes.reduce(:*)]           # [base primes, mod] for PG
    end

    def array_check(len)                    # for out-of-memory errors on primes array creation
      begin
        Array.new(len, 0)                   # use Array when enough mem for given length
      rescue Exception
        return BitArray.new(len)            # use BitArray when memory-error for Array
      end
    end

    # Find largest index nthprime|val <= n; return [start_num, nth, f/t]
    def set_start_value(n, hshflag)
      if hshflag
        nth = nths.keys.sort.reverse.find { |k| k <= n }   # largest key <= n
        [nth ? nths[nth] : 0, nth || (n + 1), nth == n]
      else
        val = nths.values.sort.reverse.find { |v| v <= n } # largest val <= n
        [val || 0, val ? nths.key(val) : 0, val != n]
      end
    end

    def nths # hash table index of reference nth primes
       {     1_000_000 =>     15_485_863,     2_500_000 =>      41_161_739,
             5_000_000 =>     86_028_121,     7_500_000 =>     132_276_691,
            10_000_000 =>    179_424_673,    12_500_000 =>     227_254_201,
            15_000_000 =>    275_604_541,    17_500_000 =>     324_407_071,
            20_000_000 =>    373_587_883,    22_500_000 =>     423_087_251,
            25_000_000 =>    472_882_027,    27_500_000 =>     522_960_521,
            31_000_000 =>    593_441_843,    37_500_000 =>     725_420_401,
            43_500_000 =>    848_321_917,    50_000_000 =>     982_451_653,
            56_000_000 =>  1_107_029_837,    62_500_000 =>   1_242_809_749,
            68_500_000 =>  1_368_724_829,    75_000_000 =>   1_505_776_939,
            81_500_000 =>  1_643_429_659,    87_500_000 =>   1_770_989_609,
            91_000_000 =>  1_845_587_707,    95_500_000 =>   1_941_743_593,
           100_000_000 =>  2_038_074_743,   106_250_000 =>   2_172_252_527,
           112_500_000 =>  2_306_797_469,   118_750_000 =>   2_441_736_961,
           125_000_000 =>  2_576_983_867,   131_250_000 =>   2_712_589_223,
           137_500_000 =>  2_848_518_523,   143_750_000 =>   2_984_727_947,
           150_000_000 =>  3_121_238_909,   156_250_000 =>   3_258_002_933,
           162_500_000 =>  3_395_057_291,   168_750_000 =>   3_532_313_509,
           175_000_000 =>  3_669_829_403,   181_250_000 =>   3_807_579_749,
           187_500_000 =>  3_945_592_087,   193_750_000 =>   4_083_820_723,
           200_000_000 =>  4_222_234_741,   206_250_000 =>   4_360_844_731,
           212_500_000 =>  4_499_683_009,   218_750_000 =>   4_638_696_967,
           225_000_000 =>  4_777_890_881,   231_250_000 =>   4_917_286_597,
           237_500_000 =>  5_056_862_311,   243_750_000 =>   5_196_588_437,
           250_000_000 =>  5_336_500_537,   256_250_000 =>   5_476_565_287,
           262_500_000 =>  5_616_787_769,   268_750_000 =>   5_757_149_341,
           275_000_000 =>  5_897_707_297,   281_250_000 =>   6_038_399_501,
           287_500_000 =>  6_179_208_157,   293_750_000 =>   6_320_167_471,
           300_000_000 =>  6_461_335_109,   306_250_000 =>   6_602_538_337,
           312_500_000 =>  6_743_943_629,   318_750_000 =>   6_885_467_689,
           325_000_000 =>  7_027_107_881,   331_250_000 =>   7_168_869_523,
           337_500_000 =>  7_310_793_337,   343_750_000 =>   7_452_779_041,
           350_000_000 =>  7_594_955_549,   356_250_000 =>   7_737_220_201,
           362_500_000 =>  7_879_581_839,   368_750_000 =>   8_022_019_693,
           375_000_000 =>  8_164_628_191,   381_250_000 =>   8_307_284_749,
           387_500_000 =>  8_450_100_349,   393_750_000 =>   8_592_999_131,
           400_000_000 =>  8_736_028_057,   406_250_000 =>   8_879_163_259,
           412_500_000 =>  9_022_375_487,   418_750_000 =>   9_165_714_427,
           425_000_000 =>  9_309_109_471,   431_000_000 =>   9_446_878_729,
           437_500_000 =>  9_596_238_593,   443_750_000 =>   9_739_892_947,
           450_000_000 =>  9_883_692_017,   456_500_000 =>  10_033_327_459,
           462_500_000 => 10_171_564_687,   468_750_000 =>  10_315_624_537,
           475_000_000 => 10_459_805_417,   481_500_000 =>  10_609_826_303,
           487_500_000 => 10_748_372_137,   493_750_000 =>  10_892_768_429,
           500_000_000 => 11_037_271_757,   506_250_000 =>  11_181_815_213,
           512_500_000 => 11_326_513_039,   519_000_000 =>  11_477_051_947,
           525_000_000 => 11_616_020_609,   531_250_000 =>  11_760_892_211,
           537_500_000 => 11_905_863_799,   543_750_000 =>  12_050_939_503,
           550_000_000 => 12_196_034_771,   556_250_000 =>  12_341_214_203,
           562_500_000 => 12_486_465_863,   568_750_000 =>  12_631_810_823,
           575_000_000 => 12_777_222_833,   581_250_000 =>  12_922_677_437,
           587_500_000 => 13_068_237_251,   593_750_000 =>  13_213_860_971,
           600_000_000 => 13_359_555_403,   606_250_000 =>  13_505_300_407,
           612_500_000 => 13_651_119_389,   619_250_000 =>  13_808_675_917,
           625_000_000 => 13_942_985_677,   631_250_000 =>  14_089_055_291,
           637_500_000 => 14_235_122_851,   643_750_000 =>  14_381_273_323,
           650_000_000 => 14_527_476_781,   656_250_000 =>  14_673_746_567,
           662_500_000 => 14_820_071_503,   668_750_000 =>  14_966_474_821,
           675_000_000 => 15_112_928_683,   681_250_000 =>  15_259_429_589,
           687_500_000 => 15_406_031_899,   693_750_000 =>  15_552_667_763,
           700_000_000 => 15_699_342_107,   706_250_000 =>  15_846_115_699,
           712_500_000 => 15_992_957_251,   716_750_000 =>  16_092_830_933,
           725_000_000 => 16_286_768_243,   731_250_000 =>  16_433_777_953,
           737_500_000 => 16_580_801_137,   743_750_000 =>  16_727_906_893,
           750_000_000 => 16_875_026_921,   756_250_000 =>  17_022_234_041,
           762_500_000 => 17_169_527_171,   768_750_000 =>  17_316_837_781,
           775_000_000 => 17_464_243_799,   781_250_000 =>  17_611_642_327,
           787_500_000 => 17_759_139_259,   793_250_000 =>  17_894_866_747,
           800_000_000 => 18_054_236_957,   806_250_000 =>  18_201_899_809,
           812_500_000 => 18_349_591_409,   817_250_000 =>  18_461_848_099,
           825_000_000 => 18_645_104_897,   831_250_000 =>  18_792_939_317,
           837_500_000 => 18_940_846_207,   843_750_000 =>  19_088_754_313,
           850_000_000 => 19_236_701_629,   856_250_000 =>  19_384_721_509,
           862_500_000 => 19_532_780_327,   868_750_000 =>  19_680_906_451,
           875_000_000 => 19_829_092_147,   881_250_000 =>  19_977_299_393,
           887_500_000 => 20_125_592_731,   893_750_000 =>  20_273_868_583,
           900_000_000 => 20_422_213_579,   906_250_000 =>  20_570_597_317,
           912_500_000 => 20_719_050_323,   918_750_000 =>  20_867_520_769,
           925_000_000 => 21_016_060_633,   931_250_000 =>  21_164_606_423,
           937_500_000 => 21_313_231_963,   943_750_000 =>  21_461_910_023,
           950_000_000 => 21_610_588_367,   956_250_000 =>  21_759_307_211,
           962_500_000 => 21_908_128_993,   968_750_000 =>  22_056_948_833,
           975_000_000 => 22_205_818_561,   981_250_000 =>  22_354_799_491,
           987_500_000 => 22_503_733_657,   993_750_000 =>  22_652_687_809,
         1_000_000_000 => 22_801_763_489, 1_012_500_000 =>  23_099_993_743,
         1_025_000_000 => 23_398_391_231, 1_037_500_000 =>  23_696_858_797,
         1_050_000_000 => 23_995_554_823, 1_062_500_000 =>  24_294_392_179,
         1_075_000_000 => 24_593_421_187, 1_087_500_000 =>  24_892_587_403,
         1_100_000_000 => 25_191_867_719, 1_112_500_000 =>  25_491_361_037,
         1_125_000_000 => 25_790_970_053, 1_137_500_000 =>  26_090_709_563,
         1_150_000_000 => 26_390_560_513, 1_162_500_000 =>  26_690_560_601,
         1_175_000_000 => 26_990_744_987, 1_187_500_000 =>  27_291_009_337,
         1_200_000_000 => 27_591_444_869, 1_212_500_000 =>  27_892_051_267,
         1_225_000_000 => 28_192_760_279, 1_237_500_000 =>  28_493_648_629,
         1_250_000_000 => 28_794_583_627, 1_262_500_000 =>  29_095_694_269,
         1_275_000_000 => 29_396_966_971, 1_287_500_000 =>  29_698_366_099,
         1_300_000_000 => 29_999_858_327, 1_312_500_000 =>  30_301_430_881,
         1_325_000_000 => 30_603_183_581, 1_337_500_000 =>  30_905_024_497,
         1_350_000_000 => 31_207_047_449, 1_362_500_000 =>  31_509_131_153,
         1_375_000_000 => 31_811_397_571, 1_387_500_000 =>  32_113_702_069,
         1_400_000_000 => 32_416_190_071, 1_412_500_000 =>  32_718_790_873,
         1_425_000_000 => 33_021_414_143, 1_437_500_000 =>  33_324_275_711,
         1_450_000_000 => 33_627_220_709, 1_462_500_000 =>  33_930_284_893,
         1_475_000_000 => 34_233_442_279, 1_487_500_000 =>  34_536_683_891,
         1_500_000_000 => 34_840_062_373, 1_512_500_000 =>  35_143_545_889,
         1_525_000_000 => 35_447_088_559, 1_537_500_000 =>  35_750_747_297,
         1_550_000_000 => 36_054_501_641, 1_562_500_000 =>  36_358_440_731,
         1_575_000_000 => 36_662_430_631, 1_587_500_000 =>  36_966_563_321,
         1_600_000_000 => 37_270_791_697, 1_612_500_000 =>  37_575_137_933,
         1_625_000_000 => 37_879_532_671, 1_637_500_000 =>  38_184_009_763,
         1_650_000_000 => 38_488_677_419, 1_662_500_000 =>  38_793_413_899,
         1_675_000_000 => 39_098_225_629, 1_687_500_000 =>  39_403_174_463,
         1_700_000_000 => 39_708_229_123, 1_712_500_000 =>  40_013_309_359,
         1_725_000_000 => 40_318_523_009, 1_737_500_000 =>  40_623_800_311,
         1_750_000_000 => 40_929_166_261, 1_762_500_000 =>  41_234_743_751,
         1_775_000_000 => 41_540_289_619, 1_787_500_000 =>  41_845_958_971,
         1_800_000_000 => 42_151_671_491, 1_812_500_000 =>  42_457_500_313,
         1_825_000_000 => 42_763_499_629, 1_837_500_000 =>  43_069_571_603,
         1_850_000_000 => 43_375_710_643, 1_862_500_000 =>  43_681_898_699,
         1_875_000_000 => 43_988_172_667, 1_887_500_000 =>  44_294_549_347,
         1_900_000_000 => 44_601_021_791, 1_912_500_000 =>  44_907_564_593,
         1_925_000_000 => 45_214_177_441, 1_937_500_000 =>  45_520_935_011,
         1_950_000_000 => 45_827_700_419, 1_962_500_000 =>  46_134_655_219,
         1_975_000_000 => 46_441_643_177, 1_987_500_000 =>  46_748_693_081,
         2_000_000_000 => 47_055_833_459, 2_062_500_000 =>  48_592_822_043,
         2_125_000_000 => 50_131_763_837, 2_187_500_000 =>  51_672_463_541,
         2_250_000_000 => 53_215_141_519, 2_312_500_000 =>  54_759_617_681,
         2_375_000_000 => 56_305_859_821, 2_437_500_000 =>  57_853_856_521,
         2_500_000_000 => 59_403_556_879, 2_562_500_000 =>  60_954_821_429,
         2_625_000_000 => 62_507_768_977, 2_687_500_000 =>  64_062_179_743,
         2_750_000_000 => 65_618_159_808, 2_812_500_000 =>  67_175_627_957,
         2_875_000_000 => 68_734_481_527, 2_937_500_000 =>  70_294_765_447,
         3_000_000_000 => 71_856_445_751, 3_062_500_000 =>  73_419_453_619,
         3_125_000_000 => 74_983_924_661, 3_187_500_000 =>  76_549_505_951,
         3_250_000_000 => 78_116_541_127, 3_312_500_000 =>  79_684_708_483,
         3_375_000_000 => 81_254_172_953, 3_437_500_000 =>  82_824_830_279,
         3_500_000_000 => 84_396_675_733, 3_562_500_000 =>  85_969_638_697,
         3_625_000_000 => 87_543_835_147, 3_687_500_000 =>  89_119_062_301,
         3_750_000_000 => 90_695_492_941, 3_812_500_000 =>  92_272_943_291,
         3_875_000_000 => 93_851_412_433, 3_937_500_000 =>  95_431_061_423,
         4_000_000_000 => 97_011_687_217, 4_062_500_000 =>  98_593_232_273,
         4_125_000_000 =>100_175_917_301, 4_187_500_000 => 101_759_445_239,
         4_250_000_000 =>103_344_103_553, 4_312_500_000 => 104_929_660_237,
         4_375_000_000 =>106_516_393_597, 4_437_500_000 => 108_103_847_759,
         4_500_000_000 =>109_692_247_799, 4_562_500_000 => 111_281_475_367,
         4_625_000_000 =>112_871_634_437, 4_687_500_000 => 114_462_576_077,
         4_750_000_000 =>116_054_419_753, 4_812_500_000 => 117_647_215_579,
         4_875_000_000 =>119_240_825_947, 4_937_500_000 => 120_835_390_561,
         5_000_000_000 =>122_430_513_841, 5_062_500_000 => 124_026_505_511,
         5_125_000_000 =>125_623_420_333, 5_187_500_000 => 127_221_145_921,
         5_250_000_000 =>128_819_622_391, 5_312_500_000 => 130_418_741_759,
         5_375_000_000 =>132_018_808_321, 5_437_500_000 => 133_619_596_303,
         5_500_000_000 =>135_221_143_753, 5_562_500_000 => 136_823_413_933,
         5_625_000_000 =>138_426_461_137, 5_687_500_000 => 140_030_126_603,
         5_750_000_000 =>141_634_567_969, 5_812_500_000 => 143_239_738_403,
         5_875_000_000 =>144_845_535_431, 5_937_500_000 => 146_451_972_661,
         6_000_000_000 =>148_059_109_201, 6_062_500_000 => 149_667_050_623,
         6_125_000_000 =>151_275_700_969, 6_187_500_000 => 152_885_012_491,
         6_250_000_000 =>154_494_952_609, 6_312_500_000 => 156_105_425_747,
         6_375_000_000 =>157_716_628_943, 6_437_500_000 => 159_328_400_423,
         6_500_000_000 =>160_940_840_461, 6_562_500_000 => 162_554_018_383,
         6_625_000_000 =>164_167_763_329, 6_687_500_000 => 165_782_087_147,
         6_750_000_000 =>167_397_013_051, 6_812_500_000 => 169_012_493_731,
         6_875_000_000 =>170_628_613_009, 6_937_500_000 => 172_245_292_151,
         7_000_000_000 =>173_862_636_221, 7_062_500_000 => 175_480_437_941,
         7_125_000_000 =>177_098_901_853, 7_187_500_000 => 178_718_004_559,
         7_250_000_000 =>180_337_540_729, 7_312_500_000 => 181_957_736_671,
         7_375_000_000 =>183_578_464_339, 7_437_500_000 => 185_199_695_243,
         7_500_000_000 =>186_821_628_281, 7_562_500_000 => 188_443_933_631,
         7_625_000_000 =>190_066_857_349, 7_687_500_000 => 191_690_371_627,
         7_750_000_000 =>193_314_249_683, 7_812_500_000 => 194_938_683_917,
         7_875_000_000 =>196_563_769_217, 7_937_500_000 => 198_189_192_449,
         8_000_000_000 =>199_815_106_433, 8_062_500_000 => 201_441_616_073,
         8_125_000_000 =>203_068_844_123, 8_187_500_000 => 204_696_410_057,
         8_250_000_000 =>206_324_421_217, 8_312_500_000 => 207_952_872_601,
         8_375_000_000 =>209_581_922_889, 8_437_500_000 => 211_211_500_043,
         8_500_000_000 =>212_841_570_911, 8_562_500_000 => 214_472_070_151,
         8_625_000_000 =>216_102_910_559, 8_687_500_000 => 217_734_315_107,
         8_750_000_000 =>219_366_232_937, 8_812_500_000 => 220_998_618_619,
         8_875_000_000 =>222_631_402_171, 8_937_500_000 => 224_264_794_049,
         9_000_000_000 =>225_898_512_559, 9_062_500_000 => 227_532_648_853,
         9_125_000_000 =>229_167_269_077, 9_187_500_000 => 230_802_553_771,
         9_250_000_000 =>232_438_083_623, 9_312_500_000 => 234_073_993_121,
         9_375_000_000 =>235_710_242_393, 9_437_500_000 => 237_347_050_547,
         9_500_000_000 =>238_984_246_139, 9_562_500_000 => 240_621_857_459,
         9_625_000_000 =>242_259_972_943, 9_687_500_000 => 243_898_743_329,
         9_750_000_000 =>245_537_657_177, 9_812_500_000 => 247_176_989_299,
         9_875_000_000 =>248_816_855_407, 9_937_500_000 => 250_457_226_821,
        10_000_000_000 =>252_097_800_623,10_062_500_000 => 253_738_728_317 }
    end
  end
end

class Integer; include Primes::Utils end

puts "Available methods are: #{0.primes_utils}" # display methods upon loading

puts "Available methods are: #{0.primes_utils}" # display methods upon loading
