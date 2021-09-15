module nopromote;

import std.stdio;
public import nopromote.wrapper;


/// 8 bit signed integer.
alias i8 = NoPromote!byte;
/// 8 bit unsigned integer.
alias u8 = NoPromote!ubyte;
/// 16 bit signed integer.
alias i16 = NoPromote!short;
/// 16 bit unsigned integer.
alias u16 = NoPromote!ushort;
/// 32 bit signed integer.
alias i32 = NoPromote!int;
/// 32 bit unsigned integer.
alias u32 = NoPromote!uint;
/// 64 bit signed integer.
alias i64 = NoPromote!long;
/// 64 bit unsigned integer.
alias u64 = NoPromote!ulong;
/// signed integer large enough to hold a pointer.
alias isize = NoPromote!sizediff_t;
/// unsigned integer large enough to hold a pointer.
alias usize = NoPromote!size_t;

// alias f32 = float;
// alias f64 = double;


unittest {
    static foreach (s; [8, 16, 32, 64]) {
        static foreach (pref; ["u", "i"]) {{
            import std.format;
            enum TYPE_NAME = format!`%s%s`(pref,s);
            mixin(`alias NP = `, TYPE_NAME, `;`);
            NP val = 4;
            
            static foreach (op; ["+", "-", "*", "/", "%", ">>", "<<", ">>>"]) {{
                mixin(format!`auto result = val %s val.base;`(op));
                assert(is(typeof(result) == NP), typeof(result).stringof~" is not "~TYPE_NAME);
            }}
            static foreach (op; ["~", "-", "+"]) {{
                mixin(format!`auto result = %sval;`(op));
                assert(is(typeof(result) == NP), typeof(result).stringof~" is not "~TYPE_NAME);
            }}
        }}
    }
}