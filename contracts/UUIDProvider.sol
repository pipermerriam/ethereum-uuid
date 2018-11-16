pragma solidity ^0.4.25;


contract UUIDProvider {

    bytes public entropy;
    uint public min_entropy;

    bytes16 public prev;
    bytes16 public next;

    bytes16[] public collisions;

    mapping (bytes32 => bool) internal usedEntropies;
    mapping (bytes16 => bool) internal usedUUIDs;

    // Actual cost is about 500,000 gas so we will only try to increase the
    // entropy when we've been provided enough gas.
    uint constant ADD_ENTROPY_GAS = 750000;

    event UUID(bytes16 uuid);


    constructor() public {
        usedUUIDs[0x0] = true;
        min_entropy = 32;
        addEntropy();
    }

    function UUID4() public returns (bytes16 uuid) {
        while (usedUUIDs[uuid]) {
            if (uuid != 0x0) {
                collisions.push(uuid);
            }

            if (next != 0x0) {
                uuid = next;
                next = 0x0;
            } else {
                byte b = getByte();
                bytes32 buf = keccak256(abi.encodePacked(prev, b));
                bytes16[2] memory half = [bytes16(0), 0];
                assembly {
                    mstore(half, buf)
                    mstore(add(half, 16), buf)
                }
                uuid = setUUID4Bytes(half[0]);
                next = setUUID4Bytes(half[1]);
            }
        }
        usedUUIDs[uuid] = true;
        emit UUID(uuid);
        prev = uuid;
        return uuid;
    }

    function collisionCount() public view returns (uint) {
        return collisions.length;
    }

    function getByte() internal returns (byte b) {
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
        if (entropy.length < 2 || (entropy.length < min_entropy && gasleft() > ADD_ENTROPY_GAS)) {
            addEntropy();
            min_entropy += 1;
        }

        if (entropy.length > 0) {
            b = entropy[entropy.length - 1];
            entropy.length -= 1;
            return b;
        }
        revert();
    }

    function addEntropy() internal returns (bool) {
        bytes32 key = getEntropy();
        if (key == 0x0) return false;
        for (uint i = 0; i < 32; i++) {
            entropy.push(key[i]);
        }
        return true;
    }
    
    function getEntropy() internal view returns (bytes32 key) {
        for (uint i = 1; i < 256; i++) {
            key = blockhash(block.number - i);
            if (!usedEntropies[key]) return key;
        }
        key = keccak256(abi.encodePacked(now));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(gasleft()));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(block.difficulty));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(tx.origin));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(msg.sender));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(block.coinbase));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(block.gaslimit));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(tx.gasprice));
        if (!usedEntropies[key]) return key;

        key = keccak256(abi.encodePacked(address(this)));
        if (!usedEntropies[key]) return key;

        return 0x0;
    }

    function setUUID4Bytes(bytes16 v) internal pure returns (bytes16) {
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
