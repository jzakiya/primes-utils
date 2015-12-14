# need rubygems to load gems, and rational for 'gcd' method for 1.8
%w/rubygems rational/.each{|r| require r} if RUBY_VERSION =~ /^(1.8)/

require "primes/utils/version"

module Primes
  module Utils
    # Upon loading, determine if platform has cli command 'factor'
    private
    @@os_has_factor = false
    begin
      if `factor 10`.split(' ') == ["10:", "2", "5"]
        @@os_has_factor = true
      end
    rescue
      @@os_has_factor = false
    end

    public
    if @@os_has_factor   # for platforms with cli 'factor' command

      def prime?
	`factor #{self.abs}`.split(' ').size == 2
      end

      def factors(p=0)   # p is unused dummy variable for method consistency
        factors = `factor #{self.abs}`.split(' ')[1..-1].map(&:to_i)
        h = Hash.new(0); factors.each {|f| h[f] +=1}; h.to_a.sort
      end

      def primesf(start_num=0)
        # List primes within a number range: end_num - start_num
        # Uses 'prime?' to check primality of prime candidates in range
        sozdata = sozcore1(self, start_num, true)  # true for primes list
        pcs_in_range, r, mod, modk, rescnt, residues, primes = sozdata

        pcs_in_range.times do         # list primes from this num pcs in range
          prime = modk + residues[r]
	  primes << prime if prime.prime?
	  r +=1; if r > rescnt; r=1; modk +=mod end
        end
        primes
      end

      def primescntf(start_num=0)
        # Count primes within a number range: end_num - start_num
        # Uses 'prime?' to check primality of prime candidates in range
        sozdata = sozcore1(self, start_num, false) # false for primes count
        pcs_in_range, r, mod, modk, rescnt, residues, primescnt = sozdata

        pcs_in_range.times do         # count primes from this num pcs in range
	  primescnt +=1 if (modk + residues[r]).prime?
	  r +=1; if r > rescnt; r=1; modk +=mod end
        end
        primescnt
      end

      puts "Using cli 'factor' for prime? primesf  primescntf  factors|prime_division"

    else  # use pure ruby versions for platforms without cli command 'factor'

      def prime?       # Uses P7 Strictly Prime Generator
        residues = [1,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,
          83,89,97,101,103,107,109,113,121,127,131,137,139,143,149,151,157,
          163,167,169,173,179,181,187,191,193,197,199,209,211]
        mod=210; # rescnt=48

        n = self.abs
        is_a_pc = residues.include?(n%mod)  # true if n is a prime candidate
        return false unless (n > 1 and is_a_pc) or [2,3,5,7].include? n
        return true  if n <= 211 and not [121,143,169,187,209].include? n

        sqrtN = Math.sqrt(n).to_i
        p=11          # first test prime pj
        while p <= sqrtN
          return false if
          n%(p)    == 0 or n%(p+2)  ==0 or n%(p+6)  == 0 or n%(p+8)  ==0 or
          n%(p+12) == 0 or n%(p+18) ==0 or n%(p+20) == 0 or n%(p+26) ==0 or
          n%(p+30) == 0 or n%(p+32) ==0 or n%(p+36) == 0 or n%(p+42) ==0 or
          n%(p+48) == 0 or n%(p+50) ==0 or n%(p+56) == 0 or n%(p+60) ==0 or
          n%(p+62) == 0 or n%(p+68) ==0 or n%(p+72) == 0 or n%(p+78) ==0 or
          n%(p+86) == 0 or n%(p+90) ==0 or n%(p+92) == 0 or n%(p+96) ==0 or
          n%(p+98) == 0 or n%(p+102)==0 or n%(p+110)== 0 or n%(p+116)==0 or
          n%(p+120)== 0 or n%(p+126)==0 or n%(p+128)== 0 or n%(p+132)==0 or
          n%(p+138)== 0 or n%(p+140)==0 or n%(p+146)== 0 or n%(p+152)==0 or
          n%(p+156)== 0 or n%(p+158)==0 or n%(p+162)== 0 or n%(p+168)==0 or
          n%(p+170)== 0 or n%(p+176)==0 or n%(p+180)== 0 or n%(p+182)==0 or
          n%(p+186)== 0 or n%(p+188)==0 or n%(p+198)== 0 or n%(p+200)==0
          p += mod    # first prime candidate for next kth residues group
        end
        true          # n is prime (100%|deterministically)
      end

      def factors(p=13)
        # Return prime factors of n in form [[p1,e1],[p2,e2]..[pn,en]]
        # Uses P13 SP PG as default Prime Generator
        seeds = [2, 3, 5, 7, 11, 13, 17, 19]
        p = 13 unless seeds.include? p

        primes = seeds[0..seeds.index(p)]
        mod = primes.reduce(:*)   # modulus: modPn = 2*3*5*7*..*Pn
        residues, rescnt = make_residues_rescnt(mod)

        n = self.abs              # number to factor
        factors = []              # init empty factors array

        return [] if n < 2
        return [[n,1]] if primes.include? n
        primes.each {|p| while n%p == 0; factors << p; n /= p end }

        sqrtN = Math.sqrt(n).to_i
        modk,r=0,1
        while (p = modk+residues[r]) <= sqrtN
          if n%p == 0
            factors << p; r -=1; n /= p; sqrtN = Math.sqrt(n).to_i
          end
          r +=1; if r > rescnt; r=1; modk +=mod end
        end
        factors << n if n > 1
        h=Hash.new(0); factors.each {|f| h[f] +=1}; h.to_a.sort
      end

      puts "Using pure ruby versions for all methods"
    end

    # Replace slow ruby library method prime_division with faster version
    alias  prime_division  factors

    def primenth(p=0)
      # Return value of nth prime
      # Adaptively selects best SP PG, unless valid input PG given at runtime
      seeds = [2, 3, 5, 7, 11, 13]
      (primes=seeds[0..seeds.index(p)]; mod=primes.reduce(:*)) if seeds.include? p

      n = self.abs                  # the desired nth prime
      return n > 0 ? seeds[n-1] : 0  if n <= seeds.size

      start_num, nth, nthflag = set_start_value(n,true)
      return start_num if nthflag   # output nthprime value if n a ref prime key

      num = approximate_nth(n)      # close approx to nth >= real nth
      primes, mod = select_pg(num, start_num) unless primes
      prms, m, modk, residues, rescnt, pcs2start, * = sozcore2(num, start_num, mod)
      return unless prms            # exit gracefully if sozcore2 mem error

      # starting at start_num's location, find nth prime within given range
      prmcnt = n > nth ? nth-1 : primes.size
      pcnt = prmcnt + prms[m..-1].count(1)  # number of primes upto nth approx
      return puts "#{pcnt} not enough primes, approx nth too small." if pcnt < n
      while prmcnt < n; prmcnt +=1 if prms[m] == 1; m +=1 end
      k, r = (m + pcs2start).divmod rescnt
      mod*k + residues[r]
    end

    alias  nthprime  primenth       # to make life easier

    def primes(start_num=0)
      # List primes between a number range: end_num - start_num
      # Adaptively selects Strictly Prime (SP) Prime Generator
      num = self.abs;  start_num = start_num.abs
      num, start_num = start_num, num  if start_num > num

      primes, mod = select_pg(num, start_num) # adaptively select PG
      prms, m, modk, residues, rescnt, x, maxprms, r = sozcore2(num, start_num, mod)
      return unless prms            # exit gracefully if sozcore2 mem error

      # init 'primes' w/any excluded primes in range then extract primes from prms
      primes.select! {|p| p >= start_num && p <= num}
      while m < maxprms             # list primes from sieved pcs in prms for range
        begin
          primes << modk + residues[r] if prms[m] == 1
        rescue Exception
          return puts "ERROR3: not enough memory to store all primes in output array."
        end
        r +=1; if r > rescnt; r=1; modk +=mod end
        m +=1
      end
      primes
    end

    def primescnt(start_num=0)
      # Count primes between a number range: end_num - start_num
      # Adaptively selects Strictly Prime (SP) Prime Generator
      num = self.abs;  start_num = start_num.abs
      num, start_num = start_num, num  if start_num > num

      if start_num < 3              # for all primes upto num
        start_num, nth, nthflag = set_start_value(num,false)
        return nth unless nthflag   # output num's key|count if a ref nth value
      end

      primes,mod = select_pg(num, start_num)  # adaptively select PG
      prms, m, * = sozcore2(num, start_num, mod)
      return unless prms            # exit gracefully if sozcore2 mem error

      # init prmcnt for any excluded primes in range then count primes in prms
      prmcnt = primes.count {|p| p >= start_num && p <= num}
      prmcnt = nth-1 if nthflag && nth > 0    # start count for small range
      prmcnt + prms[m..-1].count(1)
    end

    # Miller-Rabin prime test in Ruby
    # From: http://en.wikipedia.org/wiki/Miller-Rabin_primality_test
    # Ruby Rosetta Code: http://rosettacode.org/wiki/Miller-Rabin_primality_test
    # I modified the Rosetta Code, as shown below

    require 'openssl'
    def primemr?(k=20)  # increase k for more reliability
      n = self.abs
      return true  if [2,3].include? n
      return false unless [1,5].include?(n%6) and n > 1

      d = n - 1
      s = 0
      (d >>= 1; s += 1) while d.even?
      k.times do
        a = 2 + rand(n-4)
        x = a.to_bn.mod_exp(d,n)    # x = (a**d) mod n
        next if x == 1 or x == n-1
        (s-1).times do
          x = x.mod_exp(2,n)        # x = (x**2) mod n
          return false if x == 1
          break if x == n-1
        end
        return false if x != n-1
      end
      true  # n is prime (with high probability)
    end

    def primesmr(start_num=0)
      # List primes within a number range: end_num - start_num
      # Uses 'primemr' to check primality of prime candidates in range
      sozdata = sozcore1(self, start_num, true)  # true for primes
      pcs_in_range, r, mod, modk, rescnt, residues, primes = sozdata

      pcs_in_range.times do         # list primes from this num pcs in range
        prime = modk + residues[r]
	primes << prime if prime.primemr?
	r +=1; if r > rescnt; r=1; modk +=mod end
      end
      primes
    end

    def primescntmr(start_num=0)
      # Count primes within a number range: end_num - start_num
      # Uses 'primemr' to check primality of prime candidates in range
      sozdata = sozcore1(self, start_num, false) # false for primescnt
      pcs_in_range, r, mod, modk, rescnt, residues, primescnt = sozdata

      pcs_in_range.times do         # count primes from this num pcs in range
	primescnt +=1 if (modk + residues[r]).primemr?
	r +=1; if r > rescnt; r=1; modk +=mod end
      end
      primescnt
    end

    def primes_utils                # display list of available methods
      methods = %w/prime? primemr? primes primesf primesmr primescnt
                   primescntf primescntmr primenth|nthprime factors|prime_division primes_utils/
      (methods - (@@os_has_factor ? [] : %w/primesf primescntf/)).join(" ")
    end

    private
    def make_residues_rescnt(mod)
      residues=[1]; 3.step(mod,2) {|r| residues << r if mod.gcd(r) == 1}
      residues << mod+1
      [residues, residues.size-1]   # return residues array and rescnt
    end

    # lte= true: first output element is number of pcs <= num
    # lte=false: num pcs <, residue index, and resgroup value, for (start_)num pc
    def pcs_to_num(num,mod,rescnt,residues,lte)
      num -=1; lte ? (num |=1; k=num.abs/mod) : k = (num-1).abs/mod
      modk = mod*k; r=1
      r +=1 while num >= modk+residues[r]
      [rescnt*k + r-1, r, modk]     # [num pcs, r index, num modulus]
    end

    # Use default SP Prime Generator to parametize the pcs within a range
    # inputs:  end_num|start_num of range; method_flag to numerate|count primes
    # outputs: maxpcs-m - number of pcs in the range
    #          r        - residue index value for start_num pc of range
    #          mod      - mod value for PG
    #          modk     - base value for start_num's resgroup
    #          rescnt   - number of residues for PG
    #          residues - array of residues plus mod+1 for PG
    #          primes array|primes.size - primes array or size based on method_flag
    def sozcore1(num, start_num, method_flag)
      num = num.abs;   start_num = start_num.abs
      num, start_num = start_num, num  if start_num > num

      primes = [2,3,5,7,11,13]      # excluded primes for P13 default SP PG          
      mod = primes.reduce(:*)       # P13 modulus: 2*3*5*7*11*13 = 30030
      residues, rescnt = make_residues_rescnt(mod)
      maxpcs,* = pcs_to_num(num,mod,rescnt,residues,true) # num pcs <= end_num

      # init 'primes' w/any excluded primes in the range, or [] if none
      primes.select! {|p| p >= start_num && p <= num}

      # compute parameters for start_num pc, then create output parameters array
      m, r, modk = pcs_to_num(start_num, mod, rescnt, residues, false)
      [maxpcs-m, r, mod, modk, rescnt, residues, method_flag ? primes : primes.size]
    end

    # Perform SoZ with given Prime Generator and return array of parameters
    # inputs:  end_num and start_num of range and mod value for PG
    # outputs: prms - binary (0,1) array of pcs within a range or to end_num
    #          m    - num of pcs in prms < start_num; so prms[m] = start_num
    #          modks    - mod value for start_num's resgroup
    #          residues - array of residues plus mod+1 for PG
    #          rescnt   - number of residues for PG
    #          pcs2start- number of pcs < start_num pc
    #          maxprms  - number of pcs to find primes from; prms array size
    #          rs   - residue index location for first pc >= start_num
    def sozcore2(num, start_num, mod)
      residues, rescnt = make_residues_rescnt(mod)  # parameters for the PG
      maxprms,* = pcs_to_num(num,mod,rescnt,residues,true) # num pcs <= end_num

      # for start_num pc, find num pcs <, residue index, and resgroup mod value
      pcs2start, rs, modks = pcs_to_num(start_num, mod, rescnt, residues, false)

      sqrtN = Math.sqrt(num).to_i   # sqrt of end_num (end of range)
      pcs2sqrtN,* = pcs_to_num(sqrtN,mod,rescnt,residues,true) # num pcs <= sqrtN

      split_arrays = start_num > sqrtN # flag, true if two arrays used for sieve
      maxpcs = maxprms              # init array size for all pcs to end_num
      if split_arrays               # if start_num > sqrtN create two arrays
        maxpcs = pcs2sqrtN          # number of pcs|array size, for pcs <= sqrtN
        max_range = maxprms-pcs2start # number of pcs in range start_num to end_num
	prms_range = array_check(max_range,1) # array to represent pcs in range
        return puts "ERROR1: range size too big for available memory." unless prms_range
      end
      prms = array_check(maxpcs,1)  # array for pcs upto sqrtN, or end_num
      return puts "ERROR2: end_num too big for available memory." unless prms

      # residues offsets to compute a pcs address in its resgroup in prms
      pos =[]; rescnt.times {|i| pos[residues[i]] = i-1}

      # Sieve of Zakiya (SoZ) to eliminate nonprimes from prms and prms_range
      modk,r,k=0,0,0
      pcs2sqrtN.times do |i|        # sieve primes from pcs upto sqrt(end_num)
        r +=1; if r > rescnt; r=1; modk +=mod; k +=1 end
        next unless prms[i] == 1    # when a prime location found
        prm_r = residues[r]         # its residue value is saved
        prime = modk + prm_r        # its value is numerated
        prmstep = prime * rescnt    # its primestep computed
        kcon = k * prmstep          # its inner loop constant computed
        residues[1..-1].each do |ri|# now perform sieve with it
          # convert (prime * (modk + ri)) pc value to its address in prms
	  # computed as nonprm = (k*(prime + ri) + kn)*rescnt + pos[rr]
          kn,rr  = (prm_r * ri).divmod mod            # residues product res[group|track]
	  nonprm = kcon + (k*ri + kn)*rescnt + pos[rr]# 1st prime multiple address with ri
          while nonprm < maxpcs; prms[nonprm]=0; nonprm +=prmstep end
          if split_arrays                             # when start_num > sqrtN
            nonprm = (pcs2start - nonprm)%prmstep     # (start_num - last multiple) pcs
            nonprm = prmstep - nonprm if nonprm != 0  # location in range, or beyond
            while nonprm < max_range; prms_range[nonprm]=0; nonprm += prmstep end
          end
        end
      end
      # determine prms array parameters and starting location value m for start_num
      split_arrays ? (prms = prms_range; maxprms = max_range; m=0) : m = pcs2start
      [prms, m, modks, residues, rescnt, pcs2start, maxprms, rs] # parameters output
    end

    def approximate_nth(n)          # approximate nthprime value >= real value
      b = 0.5722*n**0.0088          # derived equation to compute close nth values
      a = b*(Math.log(Math.log(n)))
      (n*(Math.log(n)+a)+3).to_i    # use nth approximation as end_num of range
    end

    def set_start_value(n, hshflag) # find largest index nthprime|val <= n
      if hshflag
        return [nths[n], 0, true] if nths.has_key? n       # if n is key in nths table
        nth = nths.keys.sort.reverse.detect {|k| k < n}    # find largest indexed key < n
        [nth ? nths[nth] : 0, nth ||= n+1, false]          # [start_num, nth, false]
      else
        return [0,nths.key(n),false] if nths.has_value? n  # if n is value in nths table
        v=val= nths.values.sort.reverse.detect {|v| v < n} # find largest indexed val < n
        [v ||= 0, val ? nths.key(val) : 0, true]           # [start_num, nth, true]
      end
    end

    def nths                        # hash table index of reference nth primes
      nths={1000000 => 15485863,   5000000 =>   86028121,   7500000 =>  132276691,
         10000000 =>  179424673,  12500000 =>  227254201,  15000000 =>  275604541,
         18500000 =>  344032387,  25000000 =>  472882027,  31000000 =>  593441843,     
         37500000 =>  725420401,  43500000 =>  848321917,  50000000 =>  982451653,  
         56000000 => 1107029837,  62500000 => 1242809749,  68500000 => 1368724829,     
         75000000 => 1505776939,  81500000 => 1643429659,  87500000 => 1770989609,  
         93500000 => 1898979367, 100000000 => 2038074743, 106500000 => 2177624377,
        112500000 => 2306797469, 125000000 => 2576983867, 137500000 => 2848518523,
        150000000 => 3121238909, 162500000 => 3395057291, 175000000 => 3669829403,
        187500000 => 3945592087, 200000000 => 4222234741, 212500000 => 4499683009,
        225000000 => 4777890881, 237500000 => 5056862311, 250000000 => 5336500537,
        262500000 => 5616787769, 275000000 => 5897707297, 287500000 => 6179208157,
        300000000 => 6461335109, 312500000 => 6743943629, 325000000 => 7027107881,
        337500000 => 7310793337, 350000000 => 7594955549, 362500000 => 7879581839,
        375000000 => 8164628191, 387500000 => 8450100349, 400000000 => 8736028057,
        412500000 => 9022375487, 425000000 => 9309109471, 437500000 => 9596238593,
        450000000 => 9883692017, 462500000 =>10171564687, 475000000 =>10459805417,
        487500000 =>10748372137, 500000000 =>11037271757, 512500000 =>11326513039,
        525000000 =>11616020609, 537500000 =>11905863799, 550000000 =>12196034771,
        562500000 =>12486465863, 575000000 =>12777222833, 587500000 =>13068237251,
        600000000 =>13359555403, 612500000 =>13651119389, 625000000 =>13942985677,
        637500000 =>14235122851, 650000000 =>14527476781, 662500000 =>14820071503,
        675000000 =>15112928683, 687500000 =>15406031899, 700000000 =>15699342107,
        712500000 =>15992957251, 725000000 =>16286768243, 737500000 =>16580801137,
        750000000 =>16875026921, 762500000 =>17169527171, 775000000 =>17464243799,
        787500000 =>17759139259, 800000000 =>18054236957, 812500000 =>18349591409,
        825000000 =>18645104897, 837500000 =>18940846207, 850000000 =>19236701629,
        862500000 =>19532780327, 875000000 =>19829092147, 887500000 =>20125592731,
        900000000 =>20422213579, 912500000 =>20719050323, 925000000 =>21016060633,
        937500000 =>21313231963, 950000000 =>21610588367, 962500000 =>21908128993,
        975000000 =>22205818561, 987500000 =>22503733657, 1000000000=>22801763489,
        1012500000=>23099993743, 1025000000=>23398391231, 1037500000=>23696858797,
        1050000000=>23995554823, 1062500000=>24294392179, 1075000000=>24593421187,
        1087500000=>24892587403, 1100000000=>25191867719, 1112500000=>25491361037,
        1125000000=>25790970053, 1137500000=>26090709563, 1150000000=>26390560513,
        1162500000=>26690560601, 1175000000=>26990744987, 1187500000=>27291009337,
        1200000000=>27591444869, 1212500000=>27892051267, 1225000000=>28192760279,
        1237500000=>28493648629, 1250000000=>28794583627, 1262500000=>29095694269,
        1275000000=>29396966971, 1287500000=>29698366099, 1300000000=>29999858327,
        1312500000=>30301430881, 1325000000=>30603183581, 1337500000=>30905024497,
        1350000000=>31207047449, 1362500000=>31509131153, 1375000000=>31811397571,
        1387500000=>32113702069, 1400000000=>32416190071, 1412500000=>32718790873,
        1425000000=>33021414143, 1437500000=>33324275711, 1450000000=>33627220709,
        1462500000=>33930284893, 1475000000=>34233442279, 1487500000=>34536683891,
        1500000000=>34840062373, 1512500000=>35143545889, 1525000000=>35447088559,
        1537500000=>35750747297, 1550000000=>36054501641, 1562500000=>36358440731,
        1575000000=>36662430631, 1587500000=>36966563321, 1600000000=>37270791697,
        1612500000=>37575137933, 1625000000=>37879532671, 1637500000=>38184009763,
        1650000000=>38488677419, 1662500000=>38793413899, 1675000000=>39098225629,
        1687500000=>39403174463, 1700000000=>39708229123, 1712500000=>40013309359,
        1725000000=>40318523009, 1737500000=>40623800311, 1750000000=>40929166261,
        1762500000=>41234743751, 1775000000=>41540289619, 1787500000=>41845958971,
        1800000000=>42151671491, 1812500000=>42457500313, 1825000000=>42763499629,
        1837500000=>43069571603, 1850000000=>43375710643, 1862500000=>43681898699,
        1875000000=>43988172667, 1887500000=>44294549347, 1900000000=>44601021791,
        1912500000=>44907564593, 1925000000=>45214177441, 1937500000=>45520935011,
        1950000000=>45827700419, 1962500000=>46134655219, 1975000000=>46441643177,
        1987500000=>46748693981, 2000000000=>47055833459, 2012500000=>47363059687
      }
    end

    def select_pg(num, start_num)   # adaptively select PG
      range = num - start_num
      pg = 5
      if start_num <= Math.sqrt(num).to_i     # for one array of primes upto N
        pg =  7 if num >  50*10**4
        pg = 11 if num > 305*10**5
      else                                    # for split array cases
        pg =  7 if ((10**6...10**7).cover? range and start_num < 10**8)  or
                   ((10**7...10**8).cover? range and start_num < 10**10) or
                   ((10**8...10**9).cover? range and start_num < 10**12) or
                   (range >= 10**9 and start_num < 10**14)
        pg = 11 if ((10**8...10**9).cover? range and start_num < 10**10) or
                   (range >= 10**9 and start_num < 10**11)
      end
      primes = [2,3,5,7,11,13].select! {|p| p <= pg}
      [primes, primes.reduce(:*)]   # [excluded primes, mod] for PG
    end

    def array_check(n,v)  # catch out-of-memory errors on array creation
      Array.new(n,v) rescue return            # return an array or nil
    end

  end
end

class Integer; include Primes::Utils end

puts "Available methods are: #{0.primes_utils}"  # display methods upon loading