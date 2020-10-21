import rationals, deques, math

type
    Sign = enum                     # Sign for each number
        Plus, Minus
    Long = ref object of RootObj    # Long numbers
        intPart: Deque[uint8]
        decPart: Deque[uint8]
        sign: Sign


####################  CONSTRUCTORS AND REFINERS  ####################


# Default constructor
proc newLong*(): Long =
    result = Long()
    result.sign = Plus
    result.intPart = initDeque[uint8]()
    result.decPart = initDeque[uint8]()


# Build a Long from an ordinary number
proc newLong*(num: SomeNumber): Long = # Numbers with more than three decimals are depricated
    result = newLong()

    if 0 > num :
        result.sign = Minus

    var
        remainder: Rational[int]
        positive = abs float num
        rat256 = 256.toRational
        rat10 = 10.toRational
        intPart = (floor positive).toRational
        tempDec = positive.toRational - intPart
        decPart : Rational[system.int]

    while (tempDec mod 1.toRational).toFloat > 0.0 :
        tempDec *= rat10
    decPart = tempDec

    while intPart.toInt > 255 :
        remainder = intPart mod rat256
        result.intPart.addFirst uint8 toInt remainder
        intPart = (intPart - remainder) / rat256
    result.intPart.addFirst uint8 toInt intPart

    while decPart.toInt > 255 :
        remainder = decPart mod rat256
        result.decPart.addFirst uint8 toInt remainder
        decPart = (decPart - remainder) / rat256
    result.decPart.addFirst uint8 toInt decPart


# Build an integer Long from an openArray
proc newLong*(arr: openArray[int], base = 10): Long =
    newLong 0


# Build a Long from a string
proc newLong*(str: string, base = 10): Long =
    newLong 0


# Build a Long from a base 10 string (short version)
proc _*(str: string): Long = newLong(str) # _"+5465.789"


# Remove unuseful 0s before and after a Long
proc clean*(num: var Long) =
    var
        intCuts = 0
        decCuts = 0

    for index in countup(0, num.intPart.len - 1):
        if num.intPart[index] == 0: intCuts += 1
        else: break

    for index in 1..intCuts: num.intPart.popfirst()

    for index in countdown(num.decPart.len - 1, 0):
        if num.decPart[index] == 0: decCuts += 1
        else: break

    for index in 1..decCuts: num.decPart.popLast()


# Add a certain number of 0s at the begining and at the ending of a Long
proc longen*(num: var Long, intAdds = 0, decAdds = 0) =
    for index in 1..intAdds: num.intPart.addLast 0
    for index in 1..decAdds: num.decPart.addFirst 0


# Add as many 0s as necessary at the begining and the
# ending of two Longs to make them have the same size
proc fitNums*(num1, num2: var Long) =
    var
        n1i = 0
        n2i = 0
        n1d = 0
        n2d = 0
    if num1.intPart.len > num2.intPart.len: n2i = (num1.intPart.len - num2.intPart.len)
    else: n1i = (num2.intPart.len - num1.intPart.len)
    if num1.decPart.len > num2.decPart.len: n2d = (num1.decPart.len - num2.decPart.len)
    else: n1d = (num2.decPart.len - num1.decPart.len)

    num1.longen(n1i, n1d)
    num2.longen(n2i, n2d)


####################  COMPARAISON OPERATIONS  ####################


#-----  -----  Equality tests  -----  -----#


# Test of equality between two Longs
func `==`*(num1: Long, num2: Long): bool =
    var
        n1 = num1
        n2 = num2
    n1.clean
    n2.clean
    result = (
        (n1.sign == n2.sign) and (n1.intPart.len == n2.intPart.len) and (n1.decPart.len == n2.decPart.len)
    )

    if result:
        for index, digit in n1.intPart.pairs:
            result = (digit == n2.intPart[index])
            if not result: break

    if result:
        for index, digit in n1.decPart.pairs:
            result = (digit == n2.decPart[index])
            if not result: break


# Test of equality between a Long and an ordinary number
func `==`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 == n2


#-----  -----  Unequality tests  -----  -----#


# Test of unequality between two Longs
func `!=`*(num1: Long, num2: Long): bool = not(num1 == num2)


# Test of unequality between a Long and an ordinary number
func `!=`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 != n2


#-----  -----  Superiority tests  -----  -----#


# Test of superiority between two Longs
func `>`*(num1: Long, num2: Long): bool =
    var
        n1 = num1
        n2 = num2
    n1.clean
    n2.clean

    if (
        (n1.intPart == toDeque [0u8]) and
        (n1.decPart == toDeque [0u8])
    ): return false

    #We insure that the sign of n2 don't make it bigger than n1
    if ((n1.sign == Plus) and (n2.sign == Minus)) : return false

    #We check if the sign of n1 make it bigger than n2
    if ((n1.sign == Plus) and (n2.sign == Minus)) : return true

    # If the integer part of n2 is Longer than n1's, then n1 is necessarily smaller than n2
    if (n1.intPart.len < n2.intPart.len): return false

    # If the integer part of n1 is Longer than n2's, then n2 is necessarily smaller than n1
    if (n1.intPart.len > n2.intPart.len): return true

    #The two numbers aren't null, they've the same sign, and their int parts have the same length
    # It's now time to test the superiority digit by digit
    for index, digit in n1.intPart.pairs:
        if (digit > n2.intPart[index]): return true
        if (n2.intPart[index] > digit): return false

    #If the int parts are equal, then let's check which dec part is the biggest
    var
        n1IsShorter = (n1.decPart.len < n2.decPart.len)
        n2IsShorter = (n1.decPart.len > n2.decPart.len)
        shortest: int
    if n1Isshorter: shortest = n1.decPart.len
    else: shortest = n2.decPart.len
    for index in 0..<shortest:
        if (n1.decPart[index] > n2.decPart[index]): return true
        if (n2.decPart[index] > n1.decPart[index]): return false
    if n2IsShorter: return true
    return false


# Test of superiority between a Long and an ordinary number
func `>`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 > n2


#-----  -----  Inferiority tests  -----  -----#


# Test of inferiority between two Longs
func `<`*(num1: Long, num2: Long): bool = (not (num1 == num2)) and (not (num1 > num2))


# Test of inferiority between a Long and an ordinary number
func `<`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 < n2


#-----  -----  Superiority or equality tests  -----  -----#


# Test of superiority or equality between two Longs
func `>=`*(num1: Long, num2: Long): bool = (num1 == num2) or (num1 > num2)


# Test of superiority or equality between a Long and an ordinary number
func `>=`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 >= n2


#-----  -----  Inferiority or equality tests  -----  -----#


# Test of inferiority or equality between two Longs
func `<=`*(num1: Long, num2: Long): bool = not (num1 > num2)


# Test of inferiority or equality between a Long and an ordinary number
func `<=`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 <= n2


####################  BASIC ARITHMETIC OPS  ####################


#-----  -----  Additive operations  -----  -----#


# Addition of two Longs
func `+`*(num1: Long, num2: Long): Long =
    var
        n1 = num1
        n2 = num2
    fitNums(n1, n2)


# Addition of a Long and an ordinary number
func `+`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): Long =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 + n2


#-----  -----  Substractive operations  -----  -----#


# Substraction of a Long from a Long
func `-`*(num1: Long, num2: Long): Long = _""


# Substraction of a Long from an ordinary number
func `-`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): Long =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 - n2


#-----  -----  Multiplicative operations  -----  -----#


# Multiplication of two Longs
func `*`*(num1: Long, num2: Long): Long = _""


# Multiplication of a Long and an ordinary number
func `*`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): Long =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 * n2


#-----  -----  Divisive operations  -----  -----#


# Division of a Long by a Long
func `/`*(num1: Long, num2: Long): Long = _""


# Division of a Long by an ordinary number
func `/`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): Long =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 / n2


# Integer division of a Long by a Long
func `div`*(num1: Long, num2: Long): Long = _""


# Integer division of an ordinary number
func `div`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): Long =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 div n2


# Integer division of a Long by a Long
func `mod`*(num1: Long, num2: Long): Long = _""


# Division of a Long by a Long
func `mod`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): Long =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 mod n2


####################  INTERFACE BETWEEN lONGS  ####################
####################   AND EXTERNAL MODULES    ####################


#-----  Exportation of a Long  ----#


# Generate a string from a Long
func getStr*(l: Long, base = 10): string = ""


# Generate a string from the integer part a Long
func getIntStr*(l: Long, base = 10): string = ""


# Generate a sequence from the integer part a Long
func getIntSeq*(l: Long, base = 10): seq[uint8] = @[]


# Generate a string from the decimal part a Long
func getDecStr*(l: Long, base = 10): string = ""


# Generate a sequence from the decimal part a Long
func getDecSeq*(l: Long, base = 10): seq[uint8] = @[]


# Generate a base 10 string from a Long (Mostly for echo)
func `$`*(l: Long): string =
    var sign = "+"
    if l.sign == Minus :
        sign = "-"
    return $sign & $(l.intPart) & "." & $(l.decpart)
