import deques

type
    Long = ref object of RootObj
        arr: Deque[uint8]

func newLong*(): Long =
    result = Long()
    result.arr = initDeque[uint8]()

func newLong*[N](n: N): Long =
    result = Long()
    var temp = n
    var eq: uint8
    while temp > 255:
        eq = uint8(temp mod 255)
        result.arr.add(eq)
        temp = N( (temp / 255) - float(eq) )
    result.arr.add( uint8(temp) )

#[func newLong*(str: string): Long =
    result = Long()
    ]#

func `+`*[N](l: Long, n: N): Long =
    l + newLong(n)

proc echo*(l: Long) =
    echo l.arr
