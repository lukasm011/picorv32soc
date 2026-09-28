#__divsi3
#a0 (x10) is dividend, a1 (x11) is divisor
.global __divsi3
__divsi3:
addi x2, x2, -16 # Prepare to load next word
sw x12, 0(x2) # store register in memory
#x12 is now available for use
#get top bits of divisor and dividend
srli x30, x10, 31
srli x31, x11, 31
xor x12, x30, x31 #sign
bne x30, x0, neg_dividend # if x30 != x0 then neg_dividend
dividendbits:
bne x31, x0, neg_divisor # if x31 != x0 then neg_divisor
divisorbits:
addi x5, x0, 32; # x5 = x0 + 32 // Set up number of bits
addi x6, x0, 0; # x6 =x0 + 0 //Set up Remainder (A) (x6)
loop:
beq x5, x0, finish # if x5 == 0 then finish
srli x28, x10, 31 # x28 = x10 >> 31
slli x6, x6, 1 # x6 = x6 << 1
beq x28, x0, zerbit # if x28 == 0 zerbit
or x6, x6, x28 # Set bit 0 of A to 0
j donebits
zerbit:
andi x6, x6, -2 # Set bit 0 of A to 1
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
bne x12, x0, neg_res # if x12 != x0 then neg_res
done_res:
lw x12, 0(x2) #restore register value before returning
addi x2, x2, 16 #restore stack pointer value before returning
ret
ltz:
add x6, x29, x0 #restore x6 value
j continue
neg_dividend:
# Replace with two's complement
xori x10, x10, -1
addi x10, x10, 1
j dividendbits
neg_divisor:
# Replace with two's complement
xori x11, x11, -1
addi x11, x11, 1
j divisorbits
neg_res:
# Replace result with two's complement
xori x10, x10, -1
addi x10, x10, 1
j done_res