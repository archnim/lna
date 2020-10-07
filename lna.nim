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
proc newLong*(num: SomeNumber): Long =
    result = newLong()

    if 0 > num :
        result.sign = Minus

    var
        remainder: Rational[int]
        positive = abs float num
        rat256 = 256.toRational
        intPart = (floor positive).toRational
        tempDec = positive.toRational - intPart
        decPart : Rational[system.int]

    while (tempDec mod 1.toRational).toFloat > 0.0 :
        tempDec *= 10
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

    for i in countup(0, num.intPart.len - 1):
        if num.intPart[i] == 0: intCuts += 1
        else: break

    for i in 0..<intCuts: num.intPart.popfirst()

    for i in countdown(num.decPart.len - 1, 0):
        if num.decPart[i] == 0: decCuts += 1
        else: break

    for i in 0..<decCuts: num.decPart.popLast()


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


#-----  -----  Superiority tests  -----  -----#


# Test of superiority between two Longs
proc `>`*(num1: Long, num2: Long): bool =
    var
        n1 = num1
        n2 = num2
    n1.clean
    n2.clean

    if (
        (n1.intPart == toDeque [0u8])
    ): return true

    #We insure that the sign of n2 don't make it bigger than n1
    if ((n1.sign == Plus) and (n2.sign == Minus)) : return false

    # If the integer part of n2 is Longer than n1's, then n1 is necessarily smaller than n2
    result = (n1.intPart.len >= n2.intPart.len)

    if result:
        for index, digit in n1.intPart.pairs:
            result = (digit == n2.intPart[index])
            if not result: break

    if result:
        for index, digit in n1.decPart.pairs:
            result = (digit == n2.decPart[index])
            if not result: break


# Test of superiority between a Long and an ordinary number
proc `>`*[N1, N2: SomeNumber | Long](num1: N1, num2: N2): bool =
    var n1, n2: Long
    when num1 is Long : n1 = num1
    else : n1 = newLong(num1)
    when num2 is Long : n2 = num2
    else : n2 = newLong(num2)
    return n1 > n2


#-----  -----  Inferiority tests  -----  -----#


# Test of inferiority between two Longs
func `<`*(num1: Long, num2: Long): bool = true


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
func `<=`*(num1: Long, num2: Long): bool = (num1 == num2) or (num1 < num2)


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
func `+`*(num1: Long, num2: Long): Long = _""


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
