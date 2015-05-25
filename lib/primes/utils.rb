require "primes/utils/version"
require "rational" if RUBY_VERSION =~ /^(1.8)/   # for 'gcd' method

module Primes
  module Utils
    # Upon loading, determine if platform has cli command 'factor'
    private
    os_has_factor = false
    begin
      if `factor 10`.split(' ') == ["10:", "2", "5"]
        os_has_factor = true
      end
    rescue
      os_has_factor = false
    end

    # Methods primes* and primescnt* use a number range: end_num - start_num
    # Use as: end_num.primes*(start_num) (or vice versa) or end_num.primes
    # If start_num omitted, the method will find all primes <= end_num
    # If start_num > self, values are switched to make end_num > start_num

    public
    if os_has_factor   # for platforms with cli 'factor' command

      def prime?
        `factor #{self.abs}`.split(' ').size == 2
      end

      def factors(p=0) # p is unused dummy variable for method consistency
        factors = `factor #{self.abs}`.split(' ')[1..-1].map {|i| i.to_i}
        h = Hash.new(0); factors.each {|f| h[f] +=1}; h.to_a.sort
      end

      def primesf(start_num=0)
        # Find primes within a number range: end_num - start_num
        # Uses 'prime?' to check primality of prime candidates in range
        sozdata = sozcore1(self, start_num, true) # true for primes
        return sozdata[1] if sozdata[0]
        pcs_in_range, r, mod, modk, rescnt, residues, primes = sozdata[1..-1]
        pcs_in_range.times do         # find primes from this num pcs in range
          prime = modk + residues[r]
	  primes << prime if prime.prime?
	  r +=1; if r > rescnt; r=1; modk +=mod end
        end
        primes
      end

      def primescntf(start_num=0)
        # Count primes within a number range: end_num - start_num
        # Uses 'prime?' to check primality of prime candidates in range
        sozdata = sozcore1(self, start_num, false) # false for primescnt
        return sozdata[1] if sozdata[0]
        pcs_in_range, r, mod, modk, rescnt, residues, primes = sozdata[1..-1]
        primescnt = primes.size
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
        return true  if [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43,
                       47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103,
                       107, 109, 113, 127, 131, 137, 139, 149, 151, 157,163,
                       167, 173, 179, 181, 191, 193, 197, 199, 211].include? n
        return false if !residues.include?(n%mod) or n == 1

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
        true
      end

      def factors(p=13)
        # Return prime factors of n in form [[p1,e1],[p2.e2]..[pn.en]]
        # Uses sozP13 Sieve of Zakiya (SoZ) as default Prime Generator
        seeds = [2, 3, 5, 7, 11, 13, 17, 19]
        p = 13 if !seeds.include? p

        primes = seeds[0..seeds.index(p)]
	mod = primes.reduce(:*)   # modulus: modPn = 2*3*5*7*..*Pn
        residues, rescnt = make_residues_rescnt(mod)

        n = self.abs              # number to factor
        factors = []              # init empty factors array

        return [] if n == 0
        return [[n,1]] if primes.include? n
        primes.each {|p| while n%p ==0; factors << p; n /= p end }

        sqrtN= Math.sqrt(n).to_i
        modk,r=0,1; p=residues[1] # first test prime pj
        while p <= sqrtN
          if n%p == 0
            factors << p; r -=1; n /= p; sqrtN = Math.sqrt(n).to_i
          end
          r +=1; if r > rescnt; r=1; modk +=mod end
          p = modk+residues[r]    # next (or current) prime candidate
        end
        factors << n if n > 1
        h=Hash.new(0); factors.each {|f| h[f] +=1}; h.to_a.sort
      end

      puts "Using pure ruby versions for all methods"
    end
  
    # Replace slow ruby library method prime_division with faster version
    alias  prime_division  factors

    def primenth(p=7)
      # Return value of nth prime
      # Uses sozP7 Sieve of Zakiya (SoZ) as default Prime Generator
      seeds = [2, 3, 5, 7, 11, 13]
      p = 7 if !seeds.include? p

      n = self.abs                  # the desired nth prime
      return n != 0 ? seeds[n-1] : 0  if n <= seeds.size
      
      start_num, nth, nthflag = set_start_value(n, nths)
      return start_num if nthflag   # output nthprime if nth ref value

      num = approximate_nth(n)      # close approx to nth >= real nth
      primes = seeds[0..seeds.index(p)]

      ks, mod, residues, maxprms, 
      max_range, prms, prms_range = sozcore2(num, start_num, primes)

      rescnt = residues[1..-1].size
      pcs2ks = rescnt*ks
      # starting at start_num's location, find nth prime within given range
      prms = prms_range if ks > 0
      prmcnt = n > nth ? nth-1 : primes.size
      m=0; r=1; modk = mod*ks       # find number of pcs, m, in ks < start_num
      while modk + residues[r] < start_num; r += 1; m +=1 end
      pcnt = prmcnt + prms[m..-1].count(1)  # number of primes upto nth approx
      return "#{pcnt} not enough primes, nth approx too small" if pcnt < n
      while prmcnt < n; prmcnt +=1 if prms[m] == 1; m +=1 end
      k, r = (m+pcs2ks).divmod rescnt
      mod*k + residues[r]
    end

    alias  nthprime  primenth       # to make life easier

    def primes(start_num=0)
      # Find primes between a number range: end_num - start_num
      # Uses the P5 Strictly Prime (SP) Prime Generator
      num = self.abs;  start_num = start_num.abs
      num, start_num = start_num, num  if start_num > num

      primes = [2,3,5]              # P5 excluded primes lists
      plast  = primes.last          # last prime in primes
      return primes.select {|p| p >= start_num && p <= num} if num <= plast

      ks, mod, residues, maxprms, 
      max_range, prms, prms_range = sozcore2(num, start_num, primes)
 
      rescnt = residues[1..-1].size
      # starting at start_num's location, extract primes within given range
      primes = start_num <= plast ? primes.drop_while {|p| p < start_num} : []
      if ks > 0; maxprms = max_range; prms = prms_range end
      m=0; r=1; modk = mod*ks;      # find number of pcs, m, in ks < start_num
      while modk + residues[r] < start_num; r +=1; m +=1 end
      (maxprms-m).times do          # find primes from this num pcs within range
	primes << modk + residues[r] if prms[m] == 1
        r +=1; if r > rescnt; r=1; modk +=mod end
	m +=1
      end
      primes
    end
    
    def primescnt(start_num=0)
      # Count primes between a number range: end_num - start_num
      # Uses the P5 Strictly Prime (SP) Prime Generator
      num = self.abs;  start_num = start_num.abs
      num, start_num = start_num, num  if start_num > num

      primes = [2,3,5]              # P5 excluded primes lists
      plast  = primes.last          # last prime in primes
      return primes.select {|p| p >= start_num && p <= num}.size if num <= plast

      ks, mod, residues, maxprms, 
      max_range, prms, prms_range = sozcore2(num, start_num, primes)

      # starting at start_num's location, count primes within given range
      primes = start_num <= plast ? primes.drop_while {|p| p < start_num} : []
      prms = prms_range if ks > 0
      m=0; r=1; modk = mod*ks       # find number of pcs, m, in ks < start_num
      while modk + residues[r] < start_num; r +=1; m +=1 end
      primecnt = primes.size + prms[m..-1].count(1)
    end

    # Miller-Rabin prime test in Ruby
    # From: http://en.wikipedia.org/wiki/Miller-Rabin_primality_test
    # Ruby Rosetta Code: http://rosettacode.org/wiki/Miller-Rabin_primality_test
    # I modified the Rosetta Code, as shown below

    require 'openssl'
    def primemr?(k=20)  # increase k for more reliability
      n = self.abs
      return true  if n == 2 or n == 3
      return false if n % 6 != 1 && n % 6 != 5 or n == 1

      d = n - 1
      s = 0
      (d >>= 1; s += 1) while d.even?
      k.times do
        a = 2 + rand(n-4)
        x = a.to_bn.mod_exp(d,n)      # x = (a**d) mod n
        next if x == 1 or x == n-1
        (s-1).times do
          x = x.mod_exp(2,n)          # x = (x**2) mod n
          return false if x == 1
          break if x == n-1
        end
        return false if x != n-1
      end
      true  # with high probability
    end

    def primesmr(start_num=0)
      # Find primes within a number range: end_num - start_num
      # Uses 'primemr' to check primality of prime candidates in range
      sozdata = sozcore1(self, start_num, true)  # true for primes
      return sozdata[1] if sozdata[0]
      pcs_in_range, r, mod, modk, rescnt, residues, primes = sozdata[1..-1]
      pcs_in_range.times do         # find primes from this num pcs in range
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
      return sozdata[1] if sozdata[0]
      pcs_in_range, r, mod, modk, rescnt, residues, primes = sozdata[1..-1]
      primescnt = primes.size
      pcs_in_range.times do         # count primes from this num pcs in range
	primescnt +=1 if (modk + residues[r]).primemr?
	r +=1; if r > rescnt; r=1; modk +=mod end
      end
      primescnt
    end

    def primes_utils
      "prime? primemr? primes primesmr primescnt primescntmr primenth|nthprime factors|prime_division"
    end

    if os_has_factor
      def primes_utils
        "prime? primemr? primes primesf primesmr primescnt primescntf primescntmr primenth|nthprime factors|prime_division"
      end
    end

    private
    def make_residues_rescnt(mod)
      residues=[1]; 3.step(mod,2) {|i| residues << i if mod.gcd(i) == 1}
      residues << mod+1
      [residues, residues.size-1]    # return residues array and rescnt
    end

    def pcs_to_num(num,mod,rescnt,residues) # find number of pcs upto num
      num = num-1 | 1                # if N even number then subtract 1
      k=num/mod; modk = mod*k; r=1 # kth residue group; base num value
      while num >= modk+residues[r]; r += 1 end # compute extra prms size
      k*rescnt + r-1                 # max number of pcs <= num
    end

    def pcs_to_start_num(start_num, mod, rescnt, residues)
      k = (start_num-2).abs/mod     # start_num's residue group value
      modk = mod*k                  # start_num's mod group value
      m = rescnt*k                  # number of pcs upto kth resgroup
      r = 1                         # find r,m for first pc >= start_num
      while modk + residues[r] < start_num; r +=1; m +=1 end
      [m, r, modk]                  # parameters for 1st pc >= start_num
    end

    def sozcore1(num, start_num, method_flag)
      # Uses the P13 Strictly Prime (SP) Prime Generator
      num = num.abs;  start_num = start_num.abs
      num, start_num = start_num, num  if start_num > num

      primes = [2,3,5,7,11,13]      # P13 excluded primes lists
      plast  = primes.last          # last prime in primes              
      if num <= plast
	primes = primes.select {|p| p >= start_num && p <= num}
	return [true, method_flag ? primes : primes.size]
      end
      mod = primes.reduce(:*)       # P13 modulus: 2*3*5*7*11*13 = 30030
      residues, rescnt = make_residues_rescnt(mod)
      maxpcs = pcs_to_num(num,mod,rescnt,residues) # num of pcs <= end_num

      # compute parameters for start location and number of pcs within range
      primes = start_num <= plast ? primes.drop_while {|p| p < start_num} : []
      m, r, modk = pcs_to_start_num(start_num, mod, rescnt, residues)
      [false, maxpcs-m, r, mod, modk, rescnt, residues, primes]
    end

    def sozcore2(num, start_num, primes)
      mod = primes.reduce(:*)       # modulus: modPn = 2*3*5*7*..*Pn
      residues, rescnt = make_residues_rescnt(mod)
      maxprms = pcs_to_num(num,mod,rescnt,residues) # num of pcs <= end_num

      sqrtN = Math.sqrt(num).to_i   # sqrt of end_num (end of range)
      pcs2sqrtN = pcs_to_num(sqrtN,mod,rescnt,residues) # num of pcs <= sqrtN

      ks = (start_num-2).abs/mod    # start_num's resgroup value
      maxpcs = maxprms              # if ks = 0 use this for prms array
      if ks > 0                     # if start_num > mod+1
	maxpcs = pcs2sqrtN          # find primes in pcs upto sqrtN
        pcs2ks = rescnt*ks          # number of pcs upto ks resgroup
        max_range  = maxprms-pcs2ks # number of pcs from ks resgroup to end_num
        prms_range = Array.new(max_range,1) # pc array to generate range primes
      end
      prms=Array.new(maxpcs,1)      # for primes upto sqrtN and end_num if ks=0

      # hash of residues offsets to compute nonprimes positions in prms
      pos =[]; rescnt.times {|i| pos[residues[i]] = i-1}

      # Sieve of Zakiya (SoZ) to eliminate nonprimes from prms and prms_range
      modk,r,k=0,0,0
      pcs2sqrtN.times do |i|        # sieve primes from pcs upto sqrt(end_num)
        r +=1; if r > rescnt; r=1; modk +=mod; k +=1 end
	next unless prms[i]==1
        res_r = residues[r]
        prime = modk + res_r
        prmstep = prime * rescnt
        residues[1..-1].each do |ri|
          # compute (prime * (modk + ri)) position index in prms
          kk,rr  = (res_r * ri).divmod mod  # residues product res[group|track]
          nonprm = (k*(prime + ri) + kk)*rescnt + pos[rr] # 1st prime multiple
          while nonprm < maxpcs; prms[nonprm]=0; nonprm +=prmstep end
	  if ks > 0
	    nonprm = (pcs2ks - nonprm)%prmstep
	    nonprm = prmstep - nonprm if nonprm != 0
	    while nonprm < max_range; prms_range[nonprm]=0; nonprm += prmstep end
	  end
        end
      end
      [ks, mod, residues, maxprms, max_range, prms, prms_range]
    end

    def approximate_nth(n, b=0.686) # approximate nthprime value >= real value
      b=0.6863 if n > 1064000000    # good upto nth <= 1122951705
      a = b*(Math.log(Math.log(n)))
      (n*(Math.log(n)+a)+1).to_i
    end

    def set_start_value(n, nths)    # find closest nth|nthprime val <= requested 
      nthkeys = nths.keys.sort
      return [nths[n], 0, true] if nthkeys.include? n   # if nth in nths table
      start_num, nth = 0, nthkeys[0]
      nthkeys.each {|i| start_num, nth = nths[i], i if n > i}
      [start_num, nth, false]
    end

    def nths                        # hash table index of reference nth primes
      nths={1000000 => 15485863,   5000000 =>   86028121,   7500000 =>  132276691,
         10000000 =>  179424673,  12500000 =>  227254201,  25000000 =>  472882027,
         37500000 =>  725420401,  50000000 =>  982451653,  62500000 => 1242809749,
         75000000 => 1505776939,  87500000 => 1770989609, 100000000 => 2038074743,
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
        1087500000=>24892587403, 1100000000=>25191867719, 1112500000=>25491361037
      }
    end
  end
end

class Integer; include Primes::Utils end
  
puts "Available methods are: #{0.primes_utils}"  # display methods upon loading