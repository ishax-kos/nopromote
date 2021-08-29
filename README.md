# nopromote
A simple d library that provides integer types that don't promote to a signed 32 bit integer when operated on. 
Currently it only supports the ldc2 compiler.

## Specifics
Commutative operations (+, *, &, |) will always return a value that is the size and signedness of the larger operand. If the size is equal, or the operation is not commutative (/, >>, -) it maintains the size and signedness of the left hand side.