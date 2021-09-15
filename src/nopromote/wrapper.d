module nopromote.wrapper;

import std.traits;
import std.format;
import std.conv: to;
import nopromote.llvmir;


export:
/// Encapsulate a basic type. This wrapper will never return a value larger than the values operated on.
/// Otherwise it behaves like the underlying integer using a simple `alias this`.
struct NoPromote(T) /* if (isIntegral!T) */ {
    enum string SIZE = (){
        return (T.sizeof*8).to!string;
    }();

    // static assert (isIntegral!T);
    T base;
    alias base this;
    

    this(TT)(TT value) {
        base = cast(typeof(base)) value;
    }
    
    auto opAssign(R)(R value) {
        base = cast(typeof(base)) value;
        return this;
    }


    NoPromote opBinary(string op, TT)(const NoPromote!TT rhs) {
        /// Non commutative operations one might consider prioritizing the left hand side. 
        /// I decided that this should absolutely be the case for shifts.
        /// The jury is still out on / and %.
        static if (op == "<<" || op == ">>" || op == ">>>") {
            return NoPromote(opBinaryLLVM!(op)(this.base, cast(T) rhs.base));
        }

        /// The next two ensure that the largest type that the operands already share is used.
        /// It prefers the signed/unsignedness of the left hand side.
        else static if(typeof(this).sizeof >= typeof(rhs).sizeof) {
            return NoPromote(opBinaryLLVM!(op)(this.base, cast(T) rhs.base));
        }
        else static if(typeof(this).sizeof < typeof(rhs).sizeof) {
            return NoPromote(opBinaryLLVM!(op)(cast(T) this.base, rhs.base));
        }
        
        else
        return NoPromote(opBinaryLLVM!(op)(this.base, rhs.base));
    }


    auto opBinaryRight(string op, U)(const NoPromote!U lhs) {
        return lhs.opBinary!(op)(this);
    }

    
    auto opBinary(string op, R)(const R rhs) {
        static if (isIntegral!R) {
            return this.opBinary!(op)(cast(NoPromote!R) rhs);
        }
    }


    auto opBinaryRight(string op, L)(const L lhs) {
        static if (isIntegral!L) {
            return (cast(NoPromote!L) lhs).opBinary!(op)(this);
        }
    }


    NoPromote!T opUnary(string op)() {
        static if (op == "+") {
            return this;
        }
        static if (op == "-") {
            static if (isIntegral!T) {
                return NoPromote(opNegLLVM(this.base));
            } 
            static if (isFloatingPoint!T) {
                return NoPromote(-base);
            }
        }
        static if (op == "~") {
            return NoPromote(opCompLLVM(this.base));
        }
    }
}


