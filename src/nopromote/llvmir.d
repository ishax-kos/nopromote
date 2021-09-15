module nopromote.llvmir;

import std.traits;
import std.format;
import std.conv: to;

private
pragma(LDC_inline_ir)
    R inlineIR(string s, R, P...)(P);

package:

auto opBinaryLLVM(string op, T)(T lhs, T rhs) {
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
    enum string TYPE = (){
        static if (isIntegral!T)
            return "i"~(T.sizeof*8).to!string;
        else
            return T.stringof;
    }();

    return inlineIR!(`
        %r = `~OPERATION~` `~TYPE~` %0, %1
        ret `~TYPE~` %r
    `, T)(lhs, rhs);
}


// private
auto opNegLLVM(T)(T operand) 
    if (isIntegral!T) 
    {
    import std.conv: to;
    enum string TYPE = "i"~(T.sizeof*8).to!string;

    return inlineIR!(`
        %r = sub `~TYPE~` 0, %0
        ret `~TYPE~` %r
    `, T)(operand);
}


auto opCompLLVM(T)(T operand) 
    if (isIntegral!T) 
    {
    import std.conv: to;
    enum string TYPE = "i"~(T.sizeof*8).to!string;

    enum OTHER = cast(T) ulong.max;

    return inlineIR!(`
        %r = xor `~TYPE~` %0, %1
        ret `~TYPE~` %r
    `, T)(OTHER, operand);
}