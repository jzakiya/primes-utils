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
    #RUBY =  `ruby -v`.split[0] # alternative old way

    if @@os_has_factor   # for platforms with cli 'factor' command

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
    # Adaptively selects optimum PG of reduced factored number, if possible
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

    # Return value of nth prime for self > 0, or nil if self < 1
    # Adaptively selects best SP PG, unless valid input PG given at runtime
    def primenth(p = 0)
      return nil if (n = self) < 1
      seeds = [2, 3, 5, 7, 11, 13]
      return n > 0 ? seeds[n - 1] : 0 if n <= seeds.size

      start_num, nth, nthflag = set_start_value(n, true)
      return start_num if nthflag      # output nthprime value if n a ref prime key
      end_num = approximate_nth(n)     # close approx to nth >= real nth

      (primes = seeds[0..seeds.index(p)]; modpg = primes.reduce(:*)) if seeds.include? p
      primes, modpg = select_pg(end_num, start_num) unless primes

      prms, m, _, residues, pcs2start, * = sozcore2(end_num, start_num, modpg)
      return unless prms               # exit gracefully if sozcore2 mem error

      # starting at start_num's location, find nth prime within given range
      pcnt = n > nth ? nth - 1 : primes.size
      max  = prms.size
      while pcnt < n && m < max; pcnt = pcnt.succ if prms[m].zero?; m = m.succ end
      return puts "#{pcnt} not enough primes, ~nth val too small." if pcnt < n
      k, r = (m + pcs2start - 1).divmod residues.size
      modpg * k + residues[r]
    end

    alias  nthprime  primenth          # to make life easier

    # List primes between a number range: end_num - start_num
    # Adaptively selects Strictly Prime (SP) Prime Generator
    def primes(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)

      primes, modpg = select_pg(end_num, start_num) # adaptively select PG
      prms, m, modk, residues, _, r = sozcore2(end_num, start_num, modpg)
      return unless prms               # exit gracefully if sozcore2 mem error
      rescnt, modpg, maxprms = residues.size, residues[-1] - 1, prms.size

      # init 'primes' w/any excluded primes in range, extract primes from prms
      primes.select! { |p| p >= start_num && p <= end_num }

      # Find, numerate, and store primes from sieved pcs in prms for range 
      while m < maxprms
        begin
          primes << modk + residues[r] if prms[m].zero?; m = m.succ
        rescue Exception
          return puts 'ERROR3: not enough sys memory for primes output array.'
        end
        (r = 0; modk += modpg) if (r = r.succ) == rescnt
      end
      primes
    end

    # Count primes between a number range: end_num - start_num
    # Adaptively selects Strictly Prime (SP) Prime Generator
    def primescnt(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)

      nthflag, nth = 0, 0
      if start_num < 3                 # for all primes upto num
        start_num, nth, nthflag = set_start_value(end_num, false) # closest nth value
        return nth unless nthflag      # output num's key|count if ref nth value
      end

      primes, modpg = select_pg(end_num, start_num) # adaptively select PG
      prms, m, _ = sozcore2(end_num, start_num, modpg)
      return unless prms               # exit gracefully if sozcore2 mem error

      # init prmcnt for any modulus primes in range; count primes in prms
      prmcnt = primes.count { |p| p >= start_num && p <= end_num }
      prmcnt = nth - 1 if nthflag && (nth > 0)  # start count for small range
      max = prms.size
      while m < max; prmcnt = prmcnt.succ if prms[m].zero?; m = m.succ end
      prmcnt
    end

    # List primes within a number range: end_num - start_num
    # Uses 'primemr' to check primality of prime candidates in range
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

    # Count primes within a number range: end_num - start_num
    # Uses 'primemr' to check primality of prime candidates in range
    def primescntmr(start_num = 0)
      end_num, start_num = check_inputs(self, start_num)

      nthflag, nth = 0, 0
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
    def prime? (k = 5)      # Can change k higher for mr_prime?
      #Use PGT residue checks for small values < PRIMES.last**2
      return PRIMES.include? self if self <= PRIMES.last
      return false if MODPN.gcd(self) != 1
      return true  if self < PRIMES_LAST_SQRD
      primemr?(k)
    end

    # Returns the next prime number for +self+ >= 0, or nil if n < 0
    def next_prime
      return nil if (n = self) < 0
      return (n >> 1) + 2 if n <= 2                # return 2 if n is 0|1
      n = n + 1 | 1                                # 1st odd number > n
      until (res = n % 6) & 0b11 == 1; n += 2 end  # n first P3 pc >= n, w/residue 1 or 5
      inc = (res == 1) ? 4 : 2                     # set its P3 PGS value, inc by 2 and 4
      until n.primemr?; n += inc; inc ^= 0b110 end # find first prime P3 pc
      n
    end

    # Returns the previous prime number < +self+, or nil if self <= 2
    def prev_prime
      return nil if (n = self) < 3
      return (n >> 1) + 1 if n <= 5
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

    # Returns true if +self+ is a prime number, else returns false.
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
        s = d
        until y == 1 || y == neg_one_mod || s == n
          y = y.pow(2, self)           # y = (y**2) mod self
          s <<= 1
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

    def check_inputs(end_num, start_num)
      raise "invalid negative input(s)" if end_num < 0 || start_num < 0
      end_num, start_num = start_num, end_num if start_num > end_num
      [end_num, start_num]
    end

    # Returns for SP PG mod value array of residues [r1, r2,..mod-1, mod+1]
    def make_residues(modpg)
      return [ 7, 11, 13, 17, 19, 23, 29, 31] if modpg == 30
      return [11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
             73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 121, 127, 131, 137,
             139, 143, 149, 151, 157, 163, 167, 169, 173, 179, 181, 187, 191,
             193, 197, 199, 209, 211] if modpg == 210
      residues = []
      pc, inc, midmod = 13, 4, modpg >> 1
      while pc < midmod
        residues << pc << (modpg - pc) if modpg.gcd(pc) == 1
        pc += inc; inc ^= 0b110
      end
      residues.sort << (modpg - 1) << (modpg + 1)
    end

    # lte =  true: first output element is number of pcs <= num
    # lte = false: num pcs <, residue index, resgroup val, for (start_)num pc
    def pcs_to_num(num, residues, lte)
      modpg, rescnt = residues[-1] - 1, residues.size
      num -= 1; lte ? (num |= 1; k = num.abs/modpg) : k = (num - 1).abs/modpg
      modk = modpg * k; r = 0
      r = r.succ while num >= modk + residues[r]
      [rescnt * k + r, r, modk]                # [num pcs, r index, num modulus]
    end

    def pcs_to_nums(end_num, start_num, residues)
      modpg, rescnt = residues[-1] - 1, residues.size
      end_num   = 2 if end_num   < residues[0]
      start_num = 2 if start_num < residues[0]
      start_num -= 1; k1 = (start_num - 1)/modpg; modk1 = modpg * k1
      end_num   -= 1; k2 = (end_num |= 1 )/modpg; modk2 = modpg * k2
      r1 = 0; r1 = r1.succ while start_num >= modk1 + residues[r1]
      r2 = 0; r2 = r2.succ while end_num   >= modk2 + residues[r2]
      pcs2end = k2 * rescnt + r2; pcs2start = k1 * rescnt + r1
      pcs_in_range = pcs2end - pcs2start
      [pcs2end, pcs2start, r1, modk1, pcs_in_range]
    end

    # Use default SP Prime Generator to parametize the pcs within range
    # inputs:  end_num|start_num of range
    # outputs: maxpcs-m - number of pcs in the range
    #          r        - residue index value for start_num pc of range
    #          modk     - base value for start_num's resgroup
    #          residues - array of residues for PG: [r1..modpg-1, modpg+1]
    #          primes array|primes.size - based on method_flag
    def sozcore1(end_num, start_num)
      range = end_num - start_num
      modpg = range < 10_000 ? 210 : 30030
      residues = make_residues(modpg)  # chosen PG residues
      primes = PRIMES.select { |p| p < residues[0] && (p >= start_num && p <= end_num) }
      start_num = 2 if start_num < residues[0]
      k = (start_num - 2) / modpg; modk = k * modpg; r = 0
      while (start_num - 1) >= modk + residues[r]; r = r.succ end
      [r, modk, residues, primes]
    end

    # Perform SoZ with given Prime Generator and return array of parameters
    # inputs:  end_num and start_num of range and modulus value for PG
    # outputs: prms - binary (0,1) array of pcs within a range or to end_num
    #          m    - num of pcs in prms < start_num; so prms[m] = start_num
    #          modks    - modulus value for start_num's resgroup
    #          residues - array of residues for PG: [r1..modpg-1, modpg+1]
    #          pcs2start- number of pcs < start_num pc
    #          rs       - residue index location for first pc >= start_num
    def sozcore2(end_num, start_num, modpg)
      residues = make_residues(modpg); rescnt = residues.size     
      maxpcs, pcs2start, rs, modks, pcs_range = pcs_to_nums(end_num, start_num, residues)
      sqrtN = Integer.sqrt(end_num)
      pcs2sqrtN, _ = pcs_to_nums(sqrtN, 0, residues) # num pcs <= sqrtN

      m = pcs2start        # index to start retrieving primes in prms array
      split_arrays = (start_num > sqrtN)    # flag, true for split arrays
      if split_arrays      # if start_num > sqrtN create two arrays
        maxpcs = pcs2sqrtN # array size now for primary sieve array prms
        prms_range = array_check(pcs_range) # array for pcs in range
        raise 'ERROR1: range too big for free sys mem.' unless prms_range
        m = 0              # index to start retrieving primes in split array
      end
      prms = array_check(maxpcs)            # array for pcs upto sqrtN, or end_num
      raise 'ERROR2: end_num too big for available sys mem.' unless prms

      # Sieve of Zakiya (SoZ) to eliminate nonprimes from prms, prms_range
      pcs2sqrtN.times do |i|                # sieve primes from pcs upto sqrt(end_num)
        next unless prms[i].zero?           # if pc not prime, get next one
        prm_r = residues[i % rescnt]        # save its residue value
        prime = modpg*(k=i/rescnt)+prm_r    # numerate its value; set k resgroup value
        rem = start_num % prime             # prime's distance to start_num
        next unless (prime - rem <= end_num - start_num) || rem == 0 # skip prime mults not in range
        prmstep = prime * rescnt            # compute its primestep
        residues.each do |ri|               # find|mark its multiples
          # convert (prime * (modk + ri)) pc value to its address in prms
          kn, rr = (prm_r * ri - 2).divmod modpg
          mult = mult1 = (k*(prime + ri) + kn)*rescnt + residues.index(rr+2) # 1st prime mult
          while mult < maxpcs; prms[mult] = 1; mult += prmstep end
          if split_arrays                   # when start_num > sqrtN(pcs2sqrtN+1)
            mult = (pcs2start - mult1) % prmstep # (start_num - last mult) pcs
            mult = prmstep - mult if mult != 0   # location in range, or beyond
            while mult < pcs_range; prms_range[mult] = 1; mult += prmstep end
      end end end
      # select prms array and start location val m for start_num in it
      [(split_arrays ? prms_range : prms), m, modks, residues, pcs2start, rs]
    end

    def approximate_nth(n)
      b = 0.5722 * n**0.0088
      a = b * Math.log(log_n = Math.log(n))
      (n * (log_n + a) + 3).to_i
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
       {     1_000_000 =>     15_485_863,     5_000_000 =>     86_028_121,
             7_500_000 =>    132_276_691,    10_000_000 =>    179_424_673,
            12_500_000 =>    227_254_201,    15_000_000 =>    275_604_541,
            18_500_000 =>    344_032_387,    25_000_000 =>    472_882_027,
            31_000_000 =>    593_441_843,    37_500_000 =>    725_420_401,
            43_500_000 =>    848_321_917,    50_000_000 =>    982_451_653,
            56_000_000 =>  1_107_029_837,    62_500_000 =>  1_242_809_749,
            68_500_000 =>  1_368_724_829,    75_000_000 =>  1_505_776_939,
            81_500_000 =>  1_643_429_659,    87_500_000 =>  1_770_989_609,
            93_500_000 =>  1_898_979_367,   100_000_000 =>  2_038_074_743,
           106_500_000 =>  2_177_624_377,   112_500_000 =>  2_306_797_469,
           125_000_000 =>  2_576_983_867,   137_500_000 =>  2_848_518_523,
           150_000_000 =>  3_121_238_909,   162_500_000 =>  3_395_057_291,
           175_000_000 =>  3_669_829_403,   187_500_000 =>  3_945_592_087,
           200_000_000 =>  4_222_234_741,   212_500_000 =>  4_499_683_009,
           225_000_000 =>  4_777_890_881,   237_500_000 =>  5_056_862_311,
           250_000_000 =>  5_336_500_537,   262_500_000 =>  5_616_787_769,
           275_000_000 =>  5_897_707_297,   287_500_000 =>  6_179_208_157,
           300_000_000 =>  6_461_335_109,   312_500_000 =>  6_743_943_629,
           325_000_000 =>  7_027_107_881,   337_500_000 =>  7_310_793_337,
           350_000_000 =>  7_594_955_549,   362_500_000 =>  7_879_581_839,
           375_000_000 =>  8_164_628_191,   387_500_000 =>  8_450_100_349,
           400_000_000 =>  8_736_028_057,   412_500_000 =>  9_022_375_487,
           425_000_000 =>  9_309_109_471,   437_500_000 =>  9_596_238_593,
           450_000_000 =>  9_883_692_017,   462_500_000 => 10_171_564_687,
           475_000_000 => 10_459_805_417,   487_500_000 => 10_748_372_137,
           500_000_000 => 11_037_271_757,   512_500_000 => 11_326_513_039,
           525_000_000 => 11_616_020_609,   537_500_000 => 11_905_863_799,
           550_000_000 => 12_196_034_771,   562_500_000 => 12_486_465_863,
           575_000_000 => 12_777_222_833,   587_500_000 => 13_068_237_251,
           600_000_000 => 13_359_555_403,   612_500_000 => 13_651_119_389,
           625_000_000 => 13_942_985_677,   637_500_000 => 14_235_122_851,
           650_000_000 => 14_527_476_781,   662_500_000 => 14_820_071_503,
           675_000_000 => 15_112_928_683,   687_500_000 => 15_406_031_899,
           700_000_000 => 15_699_342_107,   712_500_000 => 15_992_957_251,
           725_000_000 => 16_286_768_243,   737_500_000 => 16_580_801_137,
           750_000_000 => 16_875_026_921,   762_500_000 => 17_169_527_171,
           775_000_000 => 17_464_243_799,   787_500_000 => 17_759_139_259,
           800_000_000 => 18_054_236_957,   812_500_000 => 18_349_591_409,
           825_000_000 => 18_645_104_897,   837_500_000 => 18_940_846_207,
           850_000_000 => 19_236_701_629,   862_500_000 => 19_532_780_327,
           875_000_000 => 19_829_092_147,   887_500_000 => 20_125_592_731,
           900_000_000 => 20_422_213_579,   912_500_000 => 20_719_050_323,
           925_000_000 => 21_016_060_633,   937_500_000 => 21_313_231_963,
           950_000_000 => 21_610_588_367,   962_500_000 => 21_908_128_993,
           975_000_000 => 22_205_818_561,   987_500_000 => 22_503_733_657,
         1_000_000_000 => 22_801_763_489, 1_012_500_000 => 23_099_993_743,
         1_025_000_000 => 23_398_391_231, 1_037_500_000 => 23_696_858_797,
         1_050_000_000 => 23_995_554_823, 1_062_500_000 => 24_294_392_179,
         1_075_000_000 => 24_593_421_187, 1_087_500_000 => 24_892_587_403,
         1_100_000_000 => 25_191_867_719, 1_112_500_000 => 25_491_361_037,
         1_125_000_000 => 25_790_970_053, 1_137_500_000 => 26_090_709_563,
         1_150_000_000 => 26_390_560_513, 1_162_500_000 => 26_690_560_601,
         1_175_000_000 => 26_990_744_987, 1_187_500_000 => 27_291_009_337,
         1_200_000_000 => 27_591_444_869, 1_212_500_000 => 27_892_051_267,
         1_225_000_000 => 28_192_760_279, 1_237_500_000 => 28_493_648_629,
         1_250_000_000 => 28_794_583_627, 1_262_500_000 => 29_095_694_269,
         1_275_000_000 => 29_396_966_971, 1_287_500_000 => 29_698_366_099,
         1_300_000_000 => 29_999_858_327, 1_312_500_000 => 30_301_430_881,
         1_325_000_000 => 30_603_183_581, 1_337_500_000 => 30_905_024_497,
         1_350_000_000 => 31_207_047_449, 1_362_500_000 => 31_509_131_153,
         1_375_000_000 => 31_811_397_571, 1_387_500_000 => 32_113_702_069,
         1_400_000_000 => 32_416_190_071, 1_412_500_000 => 32_718_790_873,
         1_425_000_000 => 33_021_414_143, 1_437_500_000 => 33_324_275_711,
         1_450_000_000 => 33_627_220_709, 1_462_500_000 => 33_930_284_893,
         1_475_000_000 => 34_233_442_279, 1_487_500_000 => 34_536_683_891,
         1_500_000_000 => 34_840_062_373, 1_512_500_000 => 35_143_545_889,
         1_525_000_000 => 35_447_088_559, 1_537_500_000 => 35_750_747_297,
         1_550_000_000 => 36_054_501_641, 1_562_500_000 => 36_358_440_731,
         1_575_000_000 => 36_662_430_631, 1_587_500_000 => 36_966_563_321,
         1_600_000_000 => 37_270_791_697, 1_612_500_000 => 37_575_137_933,
         1_625_000_000 => 37_879_532_671, 1_637_500_000 => 38_184_009_763,
         1_650_000_000 => 38_488_677_419, 1_662_500_000 => 38_793_413_899,
         1_675_000_000 => 39_098_225_629, 1_687_500_000 => 39_403_174_463,
         1_700_000_000 => 39_708_229_123, 1_712_500_000 => 40_013_309_359,
         1_725_000_000 => 40_318_523_009, 1_737_500_000 => 40_623_800_311,
         1_750_000_000 => 40_929_166_261, 1_762_500_000 => 41_234_743_751,
         1_775_000_000 => 41_540_289_619, 1_787_500_000 => 41_845_958_971,
         1_800_000_000 => 42_151_671_491, 1_812_500_000 => 42_457_500_313,
         1_825_000_000 => 42_763_499_629, 1_837_500_000 => 43_069_571_603,
         1_850_000_000 => 43_375_710_643, 1_862_500_000 => 43_681_898_699,
         1_875_000_000 => 43_988_172_667, 1_887_500_000 => 44_294_549_347,
         1_900_000_000 => 44_601_021_791, 1_912_500_000 => 44_907_564_593,
         1_925_000_000 => 45_214_177_441, 1_937_500_000 => 45_520_935_011,
         1_950_000_000 => 45_827_700_419, 1_962_500_000 => 46_134_655_219,
         1_975_000_000 => 46_441_643_177, 1_987_500_000 => 46_748_693_981,
         2_000_000_000 => 47_055_833_459, 2_012_500_000 => 47_363_059_687,
         2_125_000_000 => 50_131_763_837, 2_250_000_000 => 53_215_141_519,
         2_375_000_000 => 56_305_859_821, 2_500_000_000 => 59_403_556_879,
         2_625_000_000 => 62_507_768_977, 2_750_000_000 => 65_618_159_808,
         2_875_000_000 => 68_734_481_527, 3_000_000_000 => 71_856_445_751,
         3_125_000_000 => 74_983_924_661, 3_250_000_000 => 78_116_541_127,
         3_375_000_000 => 81_254_172_953, 3_500_000_000 => 84_396_675_733,
         3_625_000_000 => 87_543_835_147, 3_750_000_000 => 90_695_492_941,
         3_875_000_000 => 93_851_412_433, 4_000_000_000 => 97_011_687_217,
         4_125_000_000 =>100_175_917_301, 4_250_000_000 => 103_344_103_553,
         4_375_000_000 =>106_516_393_597, 4_500_000_000 => 109_692_247_799,
         4_625_000_000 =>112_871_634_437, 4_750_000_000 => 116_054_419_753,
         4_875_000_000 =>119_240_825_947, 5_000_000_000 => 122_430_513_841,
         5_125_000_000 =>125_623_420_333, 5_250_000_000 => 128_819_622_391,
         5_375_000_000 =>132_018_808_321, 5_500_000_000 => 135_221_143_753,
         5_625_000_000 =>138_426_461_137, 5_750_000_000 => 141_634_567_969,
         5_875_000_000 =>144_845_535_431, 6_000_000_000 => 148_059_109_201,
         6_125_000_000 =>151_275_700_969, 6_250_000_000 => 154_494_952_609,
         6_375_000_000 =>157_716_628_943, 6_500_000_000 => 160_940_840_461,
         6_625_000_000 =>164_167_763_329, 6_750_000_000 => 167_397_013_051,
         6_875_000_000 =>170_628_613_009, 7_000_000_000 => 173_862_636_221 }
    end

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
      primes = [2, 3, 5, 7, 11, 13].select! { |p| p <= pg }
      [primes, primes.reduce(:*)]           # [base primes, mod] for PG
    end

    def array_check(len)                    # for out-of-memory errors on primes array creation
      begin
        Array.new(len, 0)                   # use Array when enough mem for given length
      rescue Exception
        return BitArray.new(len)            # use BitArray when memory-error for Array
    end end
  end
end

class Integer; include Primes::Utils end

puts "Available methods are: #{0.primes_utils}" # display methods upon loading
