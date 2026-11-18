"""Rebuild the checked-in Phase 3 per-node programs and independent expected memories."""
from pathlib import Path
from shutil import copyfile

HERE = Path(__file__).resolve().parent
NODES = range(16)
RX = 64
IB, IS, OB, OS = range(0xC000, 0xC004)


class Program:
    """Small emitter for the instructions used by the communication programs."""

    def __init__(self):
        self.code = []
        self.data = {}
        self.results = {}

    def emit(self, word, asm):
        self.code.append(f"{word:08X}  // PC {4 * len(self.code):03X}  {asm}")

    def mem(self, op, reg, addr):
        opcode = {"vld": 32, "vsd": 33, "vbez": 34, "vbnez": 35}[op]
        self.emit((opcode << 26) | (reg << 21) | addr, f"{op} r{reg}, 0x{addr:04X}")

    def poll(self, addr, branch):
        target = len(self.code) * 4
        self.mem("vld", 1, addr)
        self.mem(branch, 1, target)

    def send(self, slot, status=OS, buf=OB):
        self.mem("vld", 2, slot)
        self.poll(status, "vbnez")
        self.mem("vsd", 2, buf)

    def receive(self, slot, status=IS, buf=IB):
        self.poll(status, "vbez")
        self.mem("vld", 3, buf)
        self.mem("vsd", 3, slot)

    def save_load(self, addr, slot, expected):
        self.mem("vld", 4, addr)
        self.mem("vsd", 4, slot)
        self.results[slot] = expected

    def delay(self):
        self.mem("vld", 1, 30)  # trip count
        self.mem("vld", 2, 31)  # one
        target = 4 * len(self.code)
        self.emit(0xA82110C7, "vsubad r1, r1, r2")
        self.mem("vbnez", 1, target)

    def save(self, name, node):
        self.emit(0xF0000000, "vnop")
        self.emit(0xF0000000, "vnop")
        self.emit(0, "end")
        assert len(self.code) <= 256
        (HERE / f"{name}.imem.{node}.fill").write_text("\n".join(self.code) + "\n")
        # Explicit @ addresses use the course bench's zero-initialization for gaps.
        data = "".join(f"@{addr:02X} {value:016X}\n" for addr, value in sorted(self.data.items()))
        (HERE / f"{name}.dmem.{node}.fill").write_text(data)
        memory = dict(self.data)
        memory.update(self.results)
        lines = []
        for addr in range(256):
            value = memory.get(addr, 0)
            value = value if isinstance(value, str) else f"{value:016x}"
            lines.append(f"Memory location # {addr} : {value}\n")
        (HERE / f"{name}_exp.{node}.dump").write_text("".join(lines))


def packet(src, dst, seq, vc):
    x, y = dst % 4, dst // 4
    hops = abs(src % 4 - x) + abs(src // 4 - y)
    # Reserved fields deliberately nonzero; the source field is opaque.
    header = (vc << 7) | 0x43 | (x << 4) | (y << 2)
    source = 0xB100 + 37 * src + seq
    payload = (0x9E3779B1 * (1 + src * 1024 + dst * 32 + seq)) & 0xFFFFFFFF
    return (header << 56) | (((1 << hops) - 1) << 48) | (source << 32) | payload


def received(word):
    value = f"{word:016x}"
    return value[:2] + "xx" + value[4:]  # Only the hop byte may change.


def routes(node, invert):
    p = Program()
    for offset in range(1, 16):
        peer = node ^ offset
        vc = (node + offset) % 2
        p.data[offset] = packet(node, peer, offset, vc ^ invert)
        p.send(offset)
        p.receive(RX + offset - 1)
    # Golden multiset enumerates sources at this destination, independent of arrival order.
    for index, src in enumerate(src for src in NODES if src != node):
        offset = src ^ node
        p.results[RX + index] = received(packet(src, node, offset, ((src + offset) % 2) ^ invert))
    return p


def burst(node, paced):
    p = Program()
    peer = node ^ 1
    if node % 2 == 0:
        for i in range(10):
            p.data[i] = packet(node, peer, i, 1)
            p.send(i)
    else:
        p.data.update({30: 90 if paced else 180, 31: 1})
        for i in range(10):
            if paced or i == 0:
                p.delay()
            p.receive(RX + i)
            p.results[RX + i] = received(packet(peer, node, i, 1))
    return p


def tight(node):
    p = Program()
    peer = node ^ 15
    # Complementary programs per pair; irregular bursts have distinct payloads.
    order = "SSRSRRRS" if node < peer else "RRSRSSSR"
    sends = receives = 0
    for action in order:
        if action == "S":
            p.data[sends] = packet(node, peer, sends, sends % 2)
            p.send(sends)
            sends += 1
        else:
            p.receive(RX + receives)
            p.results[RX + receives] = received(packet(peer, node, receives, receives % 2))
            receives += 1
    return p


def address_map(node):
    p = Program()
    peer = node ^ 1
    p.data.update({i: 0xBAD0000000000010 + 16 * node + i for i in range(4)})
    # Poison result slots so a skipped store cannot satisfy a zero expectation.
    for i in range(40, 48):
        p.data[i] = 0xFEEDFACE
    p.save_load(IS, 40, 0)
    p.save_load(OS, 41, 0)
    for index, prefix in enumerate((0x4000, 0x8000)):
        p.save_load(prefix + index, 42 + index, p.data[index])
        p.mem("vld", 2, index + 2)
        p.mem("vsd", 2, prefix + 24 + index)
        p.results[24 + index] = p.data[index + 2]
    # An alternate NIC address for every register. MEM[0:3] must survive.
    base = 0xF100
    p.data[8] = packet(node, peer, 0, node % 2)
    p.send(8, base + 3, base + 2)
    p.poll(base + 1, "vbez")
    p.mem("vld", 2, 2)  # bit 0 clear; must not clear occupied input status
    for addr in (base, base + 1):
        p.mem("vsd", 2, addr)
    p.save_load(base + 1, 44, 1)
    p.save_load(base, 45, received(packet(peer, node, 0, peer % 2)))
    p.save_load(base + 1, 46, 0)
    p.poll(base + 3, "vbnez")
    p.mem("vld", 2, 3)  # bit 0 set; must not set empty output status
    p.mem("vsd", 2, base + 3)
    p.save_load(base + 3, 47, 0)
    return p


def warm_reset(node):
    p = Program()
    # Each run starts with a zero register and empty NIC; leave both dirty at END.
    p.data[40] = p.data[41] = 0xDEAD
    p.mem("vsd", 17, 40)
    p.results[40] = 0
    p.save_load(IS, 41, 0)
    p.data[0] = packet(node, node ^ 1, 0, 0)
    p.mem("vld", 17, 0)
    p.send(0)
    p.poll(IS, "vbez")  # Leave the received packet unread across the reset.
    return p


def main():
    previous = HERE.parents[1] / "Phase2_for_student/tests/phase2/programs/backward_loop"
    for node in NODES:
        for source, target in (("imem.fill", f"processor.imem.{node}.fill"),
                               ("dmem.fill", f"processor.dmem.{node}.fill"),
                               ("expected.dump", f"processor_exp.{node}.dump")):
            copyfile(previous / source, HERE / target)
        for name, prog in (("routes", routes(node, 0)), ("routes_flip", routes(node, 1)),
                           ("map", address_map(node)), ("burst", burst(node, False)),
                           ("paced", burst(node, True)), ("tight", tight(node)),
                           ("warm_reset", warm_reset(node))):
            prog.save(name, node)


if __name__ == "__main__":
    main()
