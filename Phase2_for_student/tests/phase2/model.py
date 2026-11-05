"""Architectural Cardinal reference model. No RTL or pipeline implementation is used.

Big-endian lane/byte numbering; arithmetic is unsigned except VSRA. Invalid
opcode/function, reserved PPP, and MUL/SQ WW=11 act as NOP. Reserved zero
fields are ignored (one of the two behaviors accepted by Piazza @48).
"""
import math

MASK = (1 << 64) - 1
NOP = 0xF0000000
NAMES = ['', 'VAND', 'VOR', 'VXOR', 'VNOT', 'VMOV', 'VADD', 'VSUB',
         'VMULEU', 'VMULOU', 'VSLL', 'VSRL', 'VSRA', 'VRTTH', 'VDIV',
         'VMOD', 'VSQEU', 'VSQOU', 'VSQRT']
UNARY = {4, 5, 13, 16, 17, 18}
WIDEN = {8, 9, 16, 17}
BYTE_MASKS = [0xFF, 0xF0, 0x0F, 0xAA, 0x55]


def lanes(value, width):
    mask = (1 << width) - 1
    return [(value >> shift) & mask for shift in range(64-width, -1, -width)]


def pack(values, width):
    value = 0
    for lane in values:
        value = (value << width) | (lane & ((1 << width)-1))
    return value & MASK


def calculate(func, ww, a, b):
    width = 8 << ww
    limit = (1 << width) - 1
    left, right = lanes(a, width), lanes(b, width)
    if func in WIDEN:
        if ww == 3:
            return None
        odd = func in (9, 17)
        return pack([left[i] * (right[i] if func in (8,9) else left[i])
                     for i in range(int(odd), len(left), 2)], 2*width)
    answer = []
    for x, y in zip(left, right):
        shift = y & (width-1)
        if func == 1: value = x & y
        elif func == 2: value = x | y
        elif func == 3: value = x ^ y
        elif func == 4: value = ~x
        elif func == 5: value = x
        elif func == 6: value = x + y
        elif func == 7: value = x - y
        elif func == 10: value = x << shift
        elif func == 11: value = x >> shift
        elif func == 12:
            signed = x - (1 << width) if x & (1 << (width-1)) else x
            value = signed >> shift
        elif func == 13: value = (x >> (width//2)) | (x << (width//2))
        elif func == 14: value = limit if y == 0 else x // y
        elif func == 15: value = x if y == 0 else x % y
        elif func == 18: value = math.isqrt(x)
        else: return None
        answer.append(value & limit)
    return pack(answer, width)


def merge(old, new, ppp):
    byte_mask = BYTE_MASKS[ppp]
    mask = sum(0xFF << (8*(7-i)) for i in range(8) if byte_mask & (1 << (7-i)))
    return (old & (MASK ^ mask)) | (new & mask)


def execute(words, initial_memory, limit=5000):
    """Return final memory, ordered (full address,data) stores and end PC."""
    memory, registers = list(initial_memory), [0]*32
    pc, retired, stores = 0, 0, []
    while retired < limit:
        inst = words[(pc >> 2) & 255]
        if inst == 0:
            return memory, stores, pc, retired
        opcode = inst >> 26
        rd, ra, rb = (inst >> 21)&31, (inst >> 16)&31, (inst >> 11)&31
        ppp, ww, func = (inst >> 8)&7, (inst >> 6)&3, inst&63
        immediate = inst & 65535
        next_pc = (pc + 4) & 0xFFFFFFFF
        if opcode == 42 and ppp < 5:
            value = calculate(func, ww, registers[ra], registers[rb])
            if value is not None and rd:
                registers[rd] = merge(registers[rd], value, ppp)
        elif opcode == 32:
            if rd: registers[rd] = memory[immediate & 255]
        elif opcode == 33:
            memory[immediate & 255] = registers[rd]
            stores.append((immediate, registers[rd]))
        elif opcode in (34, 35):
            taken = registers[rd] == 0 if opcode == 34 else registers[rd] != 0
            if taken: next_pc = immediate
        registers[0] = 0
        pc, retired = next_pc, retired + 1
    raise ValueError('Reference program did not terminate within %d instructions' % limit)


def self_test():
    # Hand-derived anchors independent of the program generator and RTL.
    assert calculate(6,0,MASK,0x0101010101010101) == 0
    assert calculate(7,0,0,0x0101010101010101) == MASK
    assert calculate(8,0,0x0203040506070809,0x0A0B0C0D0E0F1011) == 0x0014003000540080
    assert calculate(9,0,0x0203040506070809,0x0A0B0C0D0E0F1011) == 0x0021004100690099
    assert calculate(12,0,0x807FFF0100807F80,0x0101010101010101) == 0xC03FFF0000C03FC0
    assert calculate(13,1,0x123456789ABCDEF0,0) == 0x34127856BC9AF0DE
    assert calculate(18,0,0x00010203040F10FF,0) == 0x000101010203040F
    assert calculate(14,0,0x80FF7F0100FF8001,0x0000000300000000) == 0xFFFFFF00FFFFFFFF
    assert calculate(15,0,0x80FF7F0100FF8001,0x0000000300000000) == 0x80FF7F0100FF8001
    assert merge(0x1122334455667788,0,3) == 0x0022004400660088
    assert merge(0x1122334455667788,MASK,4) == 0x11FF33FF55FF77FF
    assert calculate(8,3,1,2) is None

if __name__ == '__main__':
    self_test()
    print('Reference model anchor checks passed')
