library StringTools {
    struct Slice {
        uint _ptr;
        uint _len;
    }
    
    function memcpy(Slice dest, Slice src) private {
        var len = src._len;
        var destPtr = dest._ptr;
        var srcPtr = src._ptr;

        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(destPtr, mload(srcPtr))
            }
            destPtr += 32;
            srcPtr += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(srcPtr), bnot(mask))
            let destpart := and(mload(destPtr), mask)
            mstore(destPtr, or(destpart, srcpart))
        }
    }
    
    function getBounds(int a, uint strlen) private returns (uint start) {
        if (a < 0) {
            start = uint(int(strlen) + a);
            if (start < 0)
                throw;
        } else {
            start = uint(a);
            if (start > strlen)
                throw;
        }
    }
    
    function slice(string self) internal returns (Slice) {
        uint ptr;
        assembly { ptr := add(self, 0x20) }
        return Slice(ptr, bytes(self).length);
    }
    
    function toString(Slice self) internal returns (string ret) {
        ret = new string(self._len);
        memcpy(slice(ret), self);
    }
    
    /**
     * @dev Returns the length of a slice, in characters.
     * @param self The slice to return the length of.
     * @return The length of the slice, in characters.
     */
    function length(Slice self) internal returns (uint len) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (; ptr < end; len++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
    
    /**
     * @dev Compares two slices, returning a negative number if a is smaller,
     *      a positive number if a is larger, and zero if the slices are equal.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return An integer whose sign indicates the value of the comparison.
     */
    function compare(Slice self, Slice other) internal returns (int) {
        uint len = self._len;
        if (other._len < self._len)
            len = other._len;
        var selfptr = self._ptr;
        var otherptr = other._ptr;

        for (; len >= 0; len -= 32) {
            int diff;
            assembly {
                diff := sub(mload(selfptr), mload(otherptr))
            }
            if (diff != 0)
                return diff;
            selfptr += 32;
            otherptr += 32;
        }
        
        return int(self._len - other._len);
    }

    /**
     * @dev Finds the first occurrence of a subslice in a slice, returning its
     *      index, or -1 if the subslice is not found.
     * @param self The slice to search.
     * @param needle The slice to look for.
     * @param idx The slice index at which to start searching.
     * @return The index of the first character of the subslice, or -1 if not
     *         found.
     */
    function find(Slice self, Slice needle, uint idx) internal
        returns (int)
    {
        uint needleSize = needle._len;
        bytes32 hash;
        assembly {
            hash := sha3(mload(needle), needleSize)
        }
        for (; idx <= self._len - needleSize; idx++) {
            bytes32 testHash;
            assembly {
                testHash := sha3(add(mload(self), idx), needleSize)
            }
            if (hash == testHash)
                return int(idx);
        }
        return -1;
    }

    /**
     * @dev Finds the last occurrence of a subslice in a slice, returning its
     *      index, or -1 if the subslice is not found.
     * @param self The slice to search.
     * @param needle The slice to look for.
     * @param idx The slice index at which to start searching.
     * @return The index of the first character of the subslice, or -1 if not
     *         found.
     */
    function rfind(Slice self, Slice needle, uint idx) internal
        returns (int)
    {
        uint needleSize = needle._len;
        bytes32 hash;
        assembly {
            hash := sha3(mload(needle), needleSize)
        }
        for (int i = int(idx); i >= 0; i--) {
            bytes32 testHash;
            assembly {
                testHash := sha3(add(mload(self), i), needleSize)
            }
            if (hash == testHash)
                return i;
        }
        return -1;
    }
    
    /**
     * @dev Splits a string into two parts on a delimiter. The slice this is
     *      called on is modified to contain only the part of the string after
     *      the delimiter, while the returned string contains the part before
     *      the delimiter. If the delimiter is not found, the entire remainder
     *      of the string is returned, and the calling slice is set to the empty
     *      string.
     * @param self The string to split.
     * @param delim The delimiter to split on.
     * @return The part of the string up to the first occurence of delim, or
     *         the entire string if delim is not found.
     */
    function split(Slice self, Slice delim) internal returns (Slice ret) {
        ret._ptr = self._ptr;
        var pos = find(self, delim, 0);
        if (pos == -1) {
            ret._len = self._len;
            // Don't bother updating self._ptr, since it's an empty string.
            self._len = 0;
        } else {
            ret._len = uint(pos);
            self._ptr += uint(pos) + delim._len;
            self._len -= uint(pos) + delim._len;
        }
    }
    
    function sha3(Slice self) internal returns (bytes32 ret) {
        var ptr = self._ptr;
        var len = self._len;
        assembly {
            ret := sha3(ptr, len)
        }
    }
}

contract Test {
    using StringTools for *;
    
    function split(string a, string b) returns (string, string) {
        var rest = a.slice();
        var start = rest.split(b.slice());
        return (start.toString(), rest.toString());
    }
    
    function strlen(string a) returns (uint) {
        return a.slice().length();
    }
}