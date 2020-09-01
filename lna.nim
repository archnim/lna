import deques, math

type
    Sign = enum
        Plus = true, Minus
    Long = ref object of RootObj
        intPart: Deque[uint8]
        decPart: Deque[uint8]
        sign: Sign

func newLong*(): Long =
    result = Long()
    result.sign = Plus
    result.intPart = initDeque[uint8]()
    result.decPart = initDeque[uint8]()

proc newLong*[N](n: N): Long = # Only for numbers
    result = newLong()
    var
        eq: uint8
        nl = n

    if 0 > n :
        result.sign = Minus
        nl = -nl

    var
        intPart = int floor nl
        tempDecPart = (float nl) - (float intPart)
    echo tempDecPart
    var decPart = int tempDecPart
    echo result.sign, intPart, ".", decPart

    while intPart > 255 :
        eq = uint8(intPart mod 255)
        result.intPart.addFirst(eq)
        intPart = int floor (intPart / 10)
        echo typeof intPart, " | \n"
#    result.intPart.addFirst(intPart)

    while decPart > 255 :
        eq = uint8(decPart mod 255)
        result.decPart.addFirst(eq)
        decPart = int floor (decPart / 10)
#    result.decPart.addFirst(decPart)

func `+`*[N](l: Long, n: N): Long =
    l + newLong(n)

proc echo*(l: Long) =
    var sign = "+"
    if l.sign == Minus :
        sign = "-"
    echo sign, l.intPart, ".", l.decpart
