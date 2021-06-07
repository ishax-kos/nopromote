module nopromote;

import std.stdio;
import std.traits;
import std.format;


pragma(LDC_inline_ir)
    R inlineIR(string s, R, P...)(P);

struct NoPromote(T) {
    enum string SIZE = (){
        import std.conv: to;
        return (T.sizeof*8).to!string;
    }();

    static assert (isIntegral!T);
    T base;
    alias base this;
    

    this(R)(R value) {
        base = cast(typeof(base)) value;
    }
    
    auto opAssign(R)(R value) {
        base = cast(typeof(base)) value;
        return this;
    }


    auto opBinary(string op, TT)(const NoPromote!TT rhs) {
        /// Non commutative operations one might consider prioritizing the left hand side. 
        /// I decided that this should absolutely be the case for shifts.
        /// The jury is still out on / and %.
        static if (op == "<<" || op == ">>" || op == ">>>") {
            return opLLVM!(op)(this, cast(typeof(this)) rhs);
        }

        /// The next two ensure that the largest type that the operands already share is used.
        /// It prefers the signed/unsignedness of the left hand side.
        else static if(typeof(this).sizeof >= typeof(rhs).sizeof) {
            pragma(msg, "???");
            return opLLVM!(op)(this, cast(typeof(this)) rhs);
        }
        else static if(typeof(this).sizeof < typeof(rhs).sizeof) {
            return opLLVM!(op)(cast(typeof(rhs)) this, rhs);
        }
        
        else
        return opLLVM!(op)(this, rhs);
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

    
}


alias i8 = NoPromote!byte;
alias u8 = NoPromote!ubyte;
alias i16 = NoPromote!short;
alias u16 = NoPromote!ushort;
alias i32 = NoPromote!int;
alias u32 = NoPromote!uint;
alias i64 = NoPromote!long;
alias u64 = NoPromote!ulong;


unittest {
    i8 a = 115;
    int i = 10;
    writeln("byte ", typeof(a + 5).stringof);
    writeln("int ",  typeof(a + i).stringof);
}


private
auto opLLVM(string op, T)(NoPromote!T lhs, NoPromote!T rhs) {
            enum string OPERATION = (){
        static if (isIntegral!T) switch (op) {
            case "+": return "add";
            case "-": return "sub";
            case "*": return "mul";
            static if (isSigned!T) {
            case "/":  return "sdiv";
            case "%":  return "srem";
            }else{
            case "/":  return "udiv";
            case "%":  return "urem";
            }
            case "<<":  return "shl";
            case ">>":  return "lshr";
            case ">>>": return "ashr";
            case "&": return "and";
            case "|": return "or";
            case "^": return "xor";
            default: assert(0);
        }
        static if (isFloatingPoint!T) switch (op) {
            case "+": return "fadd";
            case "-": return "fsub";
            case "*": return "fmul";
            case "/": return "fdiv";
            case "%": return "frem";
            // case "==": 
            default: assert(0);
        }
    }();
    import std.conv: to;
    static if (isIntegral!T)
        enum string TYPE = (){
            return "i"~(T.sizeof*8).to!string;
        }();
    else
        enum string TYPE = (){
            return T.stringof;
        }();

    return inlineIR!(`
        %r = `~OPERATION~` `~TYPE~` %0, %1
        ret `~TYPE~` %r
    `, T)(lhs.base, rhs.base);
}