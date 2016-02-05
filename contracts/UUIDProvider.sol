contract UUIDProvider {
    function UUIDProvider() {
        seen[0x0] = true;
        min_entropy = 32;
        addEntropy();
    }

    bytes public entropy;
    uint public min_entropy;

    mapping (bytes32 => bool) used;

    // Actual cost is about 500,000 gas so we will only try to increase the
    // entropy when we've been provided enough gas.
    uint constant ADD_ENTROPY_GAS = 750000;

    function getByte() returns (byte b) {
        /*
         *  Entropy sources
         *  - now
         *  - block.hash(..) * 256 (ish)
         *  - tx.origin
         *  - msg.sender
         *  - block.gaslimit
         *  - msg.gas
         *  - tx.gasprice
         *  - address(this)
         */
        // both return a single byte as well as refilling entropy as needed.
        if (entropy.length < 2 || (entropy.length < min_entropy && msg.gas > ADD_ENTROPY_GAS)) {
            addEntropy();
            min_entropy += 1;
        }

        if (entropy.length > 0) {
            b = entropy[entropy.length - 1];
            entropy.length -= 1;
            return b;
        }
        throw;
    }

    function addEntropy() public returns (bool) {
        bytes32 key = getEntropy();
        if (key == 0x0) return false;
        for (uint i = 0; i < 32; i++) {
            entropy.push(byte(key));
            key = bytes32(uint(key) / 2**8);
        }
        return true;
    }

    function getEntropy() constant returns (bytes32 key) {
        for (uint i = 0; i < 256; i++) {
            key = block.blockhash(block.number - i);
            if (!used[key]) return key;
        }
        key = sha3(now);
        if (!used[key]) return key;

        key = sha3(msg.gas);
        if (!used[key]) return key;

        key = sha3(block.difficulty);
        if (!used[key]) return key;

        key = sha3(tx.origin);
        if (!used[key]) return key;

        key = sha3(msg.sender);
        if (!used[key]) return key;

        key = sha3(block.coinbase);
        if (!used[key]) return key;

        key = sha3(block.gaslimit);
        if (!used[key]) return key;

        key = sha3(tx.gasprice);
        if (!used[key]) return key;

        key = sha3(address(this));
        if (!used[key]) return key;

        return 0x0;
    }

    mapping (bytes16 => bool) seen;

    event UUID(bytes16 uuid);

    bytes16 public prev;
    bytes16 public next;

    bytes16[] public collisions;

    function collisionCount() constant returns (uint) {
        return collisions.length;
    }

    function UUID4() returns (bytes16 uuid) {
        while (seen[uuid]) {
            if (uuid != 0x0) {
                collisions.push(uuid);
            }

            if (next != 0x0) {
                uuid = next;
                next = 0x0;
            } else {
                var b = getByte();
                bytes32 buf = sha3(prev, b);
                uuid = setUUID4Bytes(bytes16(buf));
                next = setUUID4Bytes(bytes16(uint(buf) / 2 ** 128));
            }
        }
        seen[uuid] = true;
        UUID(uuid);
        prev = uuid;
        return uuid;
    }

    function setUUID4Bytes(bytes16 v) constant returns (bytes16) {
        byte byte_5 = byte(uint(v) * 2 ** (8 * 5));
        byte byte_7 = byte(uint(v) * 2 ** (8 * 7));

        if (byte_7 < 0x40 || byte_7 >= 0x50) {
            byte_7 = byte(uint8(byte_7) % 16 + 64);
            v &= 0xffffffffffffffff00ffffffffffffff;
            v |= bytes16(uint(byte_7) * 2 ** (8 * 7));
        }

        if (byte_5 < 0x80 || byte_5 > 0xb0) {
            byte_5 = byte(uint8(byte_5) % 64 + 128);
            v &= 0xffffffffffffffffffff00ffffffffff;
            v |= bytes16(uint(byte_5) * 2 ** (8 * 5));
        }

        return v;
    }
}
