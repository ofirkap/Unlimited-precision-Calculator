# Unlimited-precision-Calculator  

This program is a simple calculator for unlimited-precision unsigned integers.  
The code is written entirely in assembly language.  

Reverse Polish notation (RPN) is a mathematical notation in which every operator follows all its operands, for example "3 + 4" would be presented as "3 4 +".For simplicity, each operator will appear on a separate line of input. Input and output operands are in octal representation.

The prompts ‘calc: ‘ and wait for input. Each number or operator is entered in a separate line. For example, to do the calculation “0q172 + 0q11” a user should type:  
calc: 172  
calc: 11  
calc: +  

Operations are performed as is standard for an RPN calculator: any input number is pushed onto an operand stack. Each operation is performed on operands which are popped from the operand stack. The result, if any, is pushed onto the operand stack.  
Note: The program does not use the 80X86 machine stack (with the ESP stack pointer) as an operand stack, but rather implements a separate operand stack of size 5 by default. In order to change it to a different number, the user enters a command-line argument, the opereand stack size in octal digits.  
The program prints out "Error: Operand Stack Overflow" if the calculation attempts to push operands onto the operand stack and there is no free space on the operand stack.  
The program prints out "Error: Insufficient Number of Arguments on Stack" if an operation attempts to pop an empty stack. In any case of error, the program returns the stack to its previous state (as it was before the failed action). The program should also count the number of operations (both successful and unsuccessful) performed. This is the return value which returned to function main. The size of the operands is unbounded, except by the size of available heap space on your virtual memory.  

The operations supported by the calculator are:  
‘q’ – quit  
‘+’ – unsigned addition  
      pop two operands from operand stack, and push the result, their sum  
‘p’ – pop-and-print  
      pop one operand from the operand stack, and print its value to stdout  
‘d’ – duplicate  
       push a copy of the top of the operand stack onto the top of the operand stack  
‘&’ - bitwise AND, X&Y with X being the top of operand stack and Y the element next to x in the operand stack.  
      pop two operands from the operand stack, and push the result.  
‘n’ – number of bytes the number is taking  
      pop one operand from the operand stack, and push one result.  
