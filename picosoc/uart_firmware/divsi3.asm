#__divsi3
#a0 (x10) is dividend, a1 (x11) is divisor
.global __divsi3
__divsi3:
addi x5, x0, 32; # x5 = x0 + 32 // Set up number of bits
addi x6, x0, 0; # x6 =x0 + 0 //Set up Remainder (A) (x6)
loop:
beq x5, x0, finish # if x5 == 0 then finish
srli x28, x10, 31 # x28 = x10 >> 31
slli x6, x6, 1 # x6 = x6 << 1
beq x28, x0, zerbit # if x28 == 0 zerbit
or x6, x6, x28
j donebits
zerbit:
andi x6, x6, -2
donebits:
add x29, x0, x6; # x29 = x0 + x6 save x6 before subtraction
slli x10, x10, 1 #x10 = x10 << 1
sub x6, x6, x11 # x6 = x6 - x11
srli x7, x6, 31 # x7 = x6 >> 31
blt x6, x0, ltz # if t0 < t1 then ltz
continue:
addi x5, x5, -1 # Decrement n
beq x7, x0, zer; # if x7 == x0 then zer
andi x10, x10, -2 # set bit 0 of x10 to 0
j loop
zer:
ori x10, x10, 1 # set bit 0 of x10 to 1
j loop
finish:
ret
ltz:
add x6, x29, x0 #restore x6 value
j continue