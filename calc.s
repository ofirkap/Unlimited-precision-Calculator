section .rodata
    stackOverflow: db "Error, Operand Stack Overflow", 10, 0
    stackUnderflow: db "Error, Insuffeicient Number of Arguments on Stack", 0
	debugPush_err: db "Debug, number pushed is ", 0
	debugPop_err: db "Debug, number poped is ", 0
	prompt: db "calc: ", 0
	format_number: db "%02o", 0
	format_string: db "%s",10, 0
    format_newLine: db 10, 0

section .data
	operation_counter: dd 0
	_to_debug: db 0
	_stack_max_size: dd 5			;default stack size 5 * sizeof(int)
	_stack_cur_size: dd 0
	temp: dd 0

section .bss
	an: resb 80					; max possible length of input
	_stack_base: resb 4
	_stack_pointer: resb 4

section .text
	align 16
	global main
	extern printf
	extern fprintf 
	extern fflush
	extern malloc 
	extern calloc 
	extern free 
	;extern gets 
	extern getchar 
	extern fgets 
	extern stdout
	extern stdin
	extern stderr

main:

	push ebp
	mov ebp, esp
	pushad			
	mov ebx, dword [ebp+8]
	mov eax, [_stack_max_size]
	mov edx, 0

	parse_arg:
	cmp ebx, 1
	je no_args
	cmp ebx, 2
	je one_arg

	mov byte[_to_debug], 1
	
	one_arg:
	mov ecx, dword[ebp+12]
	mov ecx, [ecx+4]
	mov edx, 0
	mov dl, byte[ecx]
	cmp dl, '-'
	jne parse_stack_size

	mov byte[_to_debug], 1
	jmp no_args

	parse_stack_size:
	push ecx
	call atoi
	add esp, 4

	cmp eax, 2
	jle quit
	cmp eax, 64
	jg quit
	mov [_stack_max_size], eax

	no_args:
	pushad
	push dword 5
	call malloc
	add esp, 4
	mov dword[temp], eax
	popad
	mov eax, dword[temp]

	mov [_stack_base], eax
	mov [_stack_pointer], eax
	mov dword[eax], 0

calc:

	push prompt
	call printf
	add esp, 4

	mov eax, 0
	init_an:					; using eax, loop over an and set all values to 0
	mov		byte[an + eax], 0
	inc		eax
	cmp		byte[an + eax], 0
	jne		init_an

	push dword [stdin]
	push dword 80
	push an
	call fgets
	add esp, 12

	cmp byte [eax], 'q'
	je quit
	cmp byte [eax], '+'
	je adding
	cmp byte [eax], 'p'
	je pop_and_print
	cmp byte [eax], 'd'
	je duplicate
	cmp byte [eax], '&'
	je bitwise_and
	cmp byte [eax], 'n'
	je num_of_bytes
	
	mov edx, an

	find_last:
	cmp byte[edx+1], 10
	je make_first_link
	inc edx
	jmp find_last

	make_first_link:
		
		cmp edx, an
		jl calc

		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		movzx ebx, byte[edx]
		sub ebx, '0'
		dec edx

		cmp edx, an
		jl push_first_link
		movzx ecx, byte[edx]
		sub ecx, '0'
		shl ecx, 3
		add ebx, ecx
		dec edx

		push_first_link:

		mov byte[eax], bl
		mov dword[eax + 1], 0
		mov esi, eax
		mov eax, 0
		push esi
		call my_push
		add esp, 4

		cmp eax, 1
		jne parse_num
		push esi
		call free
		add esp, 4
		jmp calc

	parse_num:

		cmp edx, an
		jl calc

		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		movzx ebx, byte[edx]
		sub ebx, '0'
		dec edx

		cmp edx, an
		jl single_digit
		movzx ecx, byte[edx]
		sub ecx, '0'
		shl ecx, 3
		add ebx, ecx

		mov [eax], byte bl
		mov dword [eax + 1], 0
		mov dword[esi + 1], eax
		mov esi, eax
		dec edx
		jmp parse_num

		single_digit:
		mov [eax], byte bl
		mov dword [eax + 1], 0
		mov dword[esi + 1], eax
		jmp calc


;----------------------------------------pop and print-------------------------------
pop_and_print:

	inc dword [operation_counter]
	call my_pop
	cmp eax, 0
	je calc
	mov esi, eax

	push eax
	call print_list
	add esp, 4
	push format_newLine
	call printf
	add esp, 4

	push esi
	call free_list
	add esp, 4
	jmp calc
	
;------------------------------------------------------------------------------------

;------------------------------------------duplicate---------------------------------
duplicate:

	inc dword [operation_counter]
	mov eax, 0
	call my_pop

	cmp eax, 0
	je calc
	mov ebx, eax
	push eax
	call my_push
	add esp, 4

	pushad
	push dword 5
	call malloc
	add esp, 4
	mov dword[temp], eax
	popad
	mov eax, dword[temp]

	mov dl, byte [ebx]
	mov byte [eax], dl
	mov dword[eax + 1], 0

	mov esi, eax
	push eax
	call my_push
	add esp, 4
	cmp dword [ebx + 1], 0
	je finish_dup
	mov ebx, dword [ebx + 1]

	cmp eax, 1
	jne new_link
	push esi
	call free
	add esp, 4
	jmp calc

	new_link:

		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		mov dl, byte [ebx]
		mov byte [eax], dl
		mov dword [eax + 1], 0
		mov dword[esi + 1], eax

		mov esi, eax
		cmp dword [ebx + 1], 0
		je finish_dup
		mov ebx, dword [ebx + 1]
		jmp new_link

	finish_dup:
	mov dword [esi + 1], 0
	jmp calc
;------------------------------------------------------------------------------------

;-----------------------------------------bitwise and--------------------------------
bitwise_and:

	inc dword [operation_counter]

	call my_pop
	cmp eax, 0
	je calc
	mov ebx, eax

	call my_pop
	cmp eax, 0
	je push_back
	mov ecx, eax

	mov esi, ebx
	mov edi, ecx

	push ebx
	push ecx
	call make_and_num
	add esp, 8
	
	push esi
	call free_list
	add esp, 4
	push edi
	call free_list
	add esp, 4
	jmp calc

	push_back:

		push ebx
		call my_push
		add esp, 4
		jmp calc

;------------------------------------------------------------------------------------

;---------------------------------------number of bytes------------------------------
num_of_bytes:

	inc dword [operation_counter]
	call my_pop
	cmp eax, 0
	je calc
	mov ebx, 0
	mov esi, eax

	loop_count:
	add ebx, 3
	cmp byte [eax], 8
	jl remove_zeroes_one_byte
	add ebx, 3
	cmp dword [eax + 1], 0
	je remove_zeroes_two_bytes
	mov eax, dword[eax + 1]
	jmp loop_count

	remove_zeroes_two_bytes:

		cmp byte [eax], 32
		jge finish_count
		sub ebx, 1

		cmp byte [eax], 16
		jge finish_count
		sub ebx, 1
		jmp finish_count
	
	remove_zeroes_one_byte:

		cmp byte [eax], 4
		jge finish_count
		sub ebx, 1

		cmp byte [eax], 2
		jge finish_count
		sub ebx, 1
	
	finish_count:

		mov edi, 1
		and edi, ebx
		cmp edi, 1
		jne div_by_2
		add ebx, 1

		div_by_2:
		shr ebx, 1
		mov edi, 1
		and edi, ebx
		cmp edi, 1
		jne div_by_4
		add ebx, 1

		div_by_4:
		shr ebx, 1
		mov edi, 1
		and edi, ebx
		cmp edi, 1
		jne div_by_8
		add ebx, 1

		div_by_8:
		shr ebx, 1

		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		mov byte [eax], bl
		mov dword[eax + 1], 0
		
		push eax
		call my_push
		add esp, 4

		push esi
		call free_list
		add esp, 4
		jmp calc
;------------------------------------------------------------------------------------

;-------------------------------------------adding-----------------------------------
adding:
	inc dword [operation_counter]

	call my_pop		;get the first number
	cmp eax, 0
	je calc
	mov ebx, eax

	call my_pop		;get the second number
	cmp eax, 0
	je push_back
	mov ecx, eax

	mov edi, ebx
	mov esi, ecx

	push ecx
	push ebx
	call sum_num
	add esp, 8

	push edi
	call free_list
	add esp, 4
	push esi
	call free_list
	add esp, 4
	jmp calc
;------------------------------------------------------------------------------------

PopAndPrint:
	push ebp
	mov ebp, esp

	call my_pop
	push eax
	cmp eax, 0
	jz .finish
	call print_list
	call free_list
	add esp, 4
	.finish:
	mov esp, ebp
	pop ebp
	ret


;--------------------------------------------quit------------------------------------
quit:
	mov ebx, [_stack_cur_size]
	cmp ebx, 0
	jle free_stack
	
	call my_pop
	push eax
	call free_list
	add esp, 4

	jmp quit

	free_stack:
	mov ecx, [_stack_base]
	push ecx
	call free
	add esp, 4

	mov eax, [operation_counter]
	push eax
	push format_number
	call printf
	add esp, 8
	push format_newLine
	call printf
	add esp, 4

	popad
	mov esp, ebp
	pop ebp
	ret
;------------------------------------------------------------------------------------
atoi:

	push ebp
	mov ebp, esp
	sub esp, 4
	pushad
	mov ebx, dword[ebp+8]
	mov eax, 0

	loop_atoi:

	cmp byte[ebx], 10
	je finish_atoi
	cmp byte[ebx], 0
	je finish_atoi

	movzx ecx, byte[ebx]
	sub ecx, '0'
	shl eax, 3
	add eax, ecx
	inc ebx
	jmp loop_atoi

	finish_atoi:
	mov [ebp-4], eax
	popad
	mov eax, [ebp-4]
	mov esp, ebp
	pop ebp
	ret

make_and_num:

	push ebp
	mov ebp, esp
	pushad

	mov ebx, dword[ebp + 8]
	mov ecx, dword[ebp + 12]

	pushad
	push dword 5
	call malloc
	add esp, 4
	mov dword[temp], eax
	popad
	mov eax, dword[temp]

	mov dl, 0xFF
	and dl, byte [ebx]
	and dl, byte [ecx]

	mov byte[eax], dl
	mov dword[eax + 1], 0
	mov esi, eax
	push eax
	call my_push
	add esp, 4

	cmp dword [ebx + 1], 0
	je finish_and
	cmp dword [ecx + 1], 0
	je finish_and
	mov ebx, dword [ebx + 1]
	mov ecx, dword [ecx + 1]

	link_and:

		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		mov dl, 0xFF
		and dl, byte [ebx]
		and dl, byte [ecx]

		mov byte[eax], dl
		mov dword [eax + 1], 0
		mov dword[esi + 1], eax

		mov esi, eax
		cmp dword [ebx + 1], 0
		je finish_and
		cmp dword [ecx + 1], 0
		je finish_and
		mov ebx, dword [ebx + 1]
		mov ecx, dword [ecx + 1]
		jmp link_and

	finish_and:

		popad
		mov esp, ebp
		pop ebp
		ret

sum_num:

	push ebp
	mov ebp, esp
	pushad

	mov edi, dword[ebp + 8]		;first number
	mov esi, dword[ebp + 12]	;second number

	pushad
	push dword 5
	call malloc
	add esp, 4
	mov dword[temp], eax
	popad
	mov eax, dword[temp]


	mov ebx, 0 ;--
	mov edx, 0
	add dl, byte [edi]
	add dl, byte [esi]

	cmp dl, 63
	jle carry_zero1
	sub dl, 64 ;--
	mov ebx, 1

	carry_zero1:
	mov byte[eax], dl
	mov dword [eax + 1], 0
	;************
	mov ecx, eax
	;************
	push eax
	call my_push
	add esp, 4
	
	cmp dword [edi + 1], 0
	je add_single
	cmp dword [esi + 1], 0
	je add_single
	mov edi, dword [edi + 1]
	mov esi, dword [esi + 1]

	add_loop:
	
		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		mov edx, 0
		mov dl, bl ;--
		add dl, byte [edi]
		add dl, byte [esi]


		cmp dl, 63 ;--
		jle carry_zero2
		sub dl, 64 ;--
		mov ebx, 1
		jmp carry_one1 ;--

		carry_zero2:
		mov ebx, 0

		carry_one1: ;--
		mov byte[eax], dl
		mov dword [eax + 1], 0
		mov dword [ecx + 1], eax
		;************
		mov ecx, eax
		;************
		cmp dword [edi + 1], 0
		je add_single
		cmp dword [esi + 1], 0
		je add_single
		mov ebx, dword [edi + 1]
		mov ecx, dword [esi + 1]
		jmp add_loop

	add_single:

		cmp dword [edi + 1], 0
		jne loop_single
		cmp dword [esi + 1], 0 ;--
		je finish_add ;--
		mov edi, esi

	loop_single:

		mov edi, dword [edi + 1] ;--
		
		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]

		mov edx, 0
		mov dl, bl ;--
		add dl, byte [edi]
		cmp dl, 63 ;--
		jle carry_zero3

		sub dl, 64 ;--
		mov ebx, 1
		jmp carry_one2 ;--

		carry_zero3:
		mov ebx, 0

		carry_one2:
		mov byte[eax], dl
		mov dword [eax + 1], 0
		mov dword [ecx + 1], eax

		mov ecx, eax
		cmp dword [edi + 1], 0
		jne loop_single

	finish_add:

		cmp ebx, 0
		je finito
		pushad
		push dword 5
		call malloc
		add esp, 4
		mov dword[temp], eax
		popad
		mov eax, dword[temp]
		mov byte[eax], 1
		mov dword [eax + 1], 0
		mov dword [ecx + 1], eax

		finito:
		popad
		mov esp, ebp
		pop ebp
		ret

my_push:

	push ebp
	mov ebp, esp
	sub esp, 4
	pushad
	mov esi, dword [_stack_cur_size]
	mov edi, dword [_stack_max_size]
	mov edx, 0
	cmp esi, edi

	jge stack_full

	inc esi
	mov dword[_stack_cur_size], esi

	mov ebx, dword[ebp + 8]
	mov ecx, dword[_stack_pointer]
	mov dword[ecx], ebx
	add ecx, 4
	mov dword[_stack_pointer], ecx
		
	cmp byte[_to_debug], 1
	jne finish_push

	push debugPush_err
	push dword[stderr]
	call fprintf
	add esp, 8

	push ebx
	call debug_print_list
	add esp, 4

	push format_newLine
	push dword[stderr]
	call fprintf
	add esp, 8

	jmp finish_push

	stack_full:
        push stackOverflow
		push format_string
		call printf
		add esp, 8
		mov edx, 1
	
	finish_push:
	mov [ebp-4], edx
	popad
	mov eax, [ebp-4]
	mov esp, ebp
	pop ebp
	ret

my_pop:

	push ebp
	mov ebp, esp
	sub esp, 4
	pushad
	mov ebx, 0
	mov edx, [_stack_cur_size]
	cmp edx, 0
	je stack_empty

	dec edx
	mov [_stack_cur_size], edx

	mov esi, dword[_stack_pointer]
	sub esi, 4
	mov ebx, dword[esi]
	mov dword[esi], 0
	mov dword[_stack_pointer], esi

	cmp byte[_to_debug], 1
	jne finish_pop
	
	push debugPop_err
	push dword[stderr]
	call fprintf
	add esp, 8

	push ebx
	call debug_print_list
	add esp, 4
	
	push format_newLine
	push dword[stderr]
	call fprintf
	add esp, 8	
	
	jmp finish_pop
	
	stack_empty:

        push stackUnderflow
		push format_string
		call printf
		add esp, 8
		jmp finish_pop

	finish_pop:
	mov [ebp-4], ebx
	popad
	mov eax, [ebp-4]
	mov esp, ebp
	pop ebp
	ret

free_list:

	push ebp
	mov ebp, esp
	pushad

	mov ebx, dword[ebp + 8]
	cmp dword[ebx + 1], 0
	je finish_free_list

	mov ecx, [ebx + 1]
	push ecx
	call free_list
	add esp, 4

	finish_free_list:
	push ebx
	call free
	add esp, 4

	popad
	mov esp, ebp
	pop ebp
	ret

print_list:

	push ebp
	mov ebp, esp
	pushad

	mov ebx, dword[ebp + 8]
	cmp dword[ebx + 1], 0
	je finish_print_list

	mov ecx, [ebx + 1]
	push ecx
	call print_list
	add esp, 4

	finish_print_list:

	mov edx, 0
	movzx edx, byte[ebx]
	push edx
	push format_number
	call printf
	add esp, 8

	popad
	mov esp, ebp
	pop ebp
	ret

debug_print_list:

	push ebp
	mov ebp, esp
	pushad

	mov ebx, dword[ebp + 8]
	cmp dword[ebx + 1], 0
	je finish_debug_print_list

	mov ecx, [ebx + 1]
	push ecx
	call debug_print_list
	add esp, 4

	finish_debug_print_list:

	mov edx, 0
	movzx edx, byte[ebx]
	push edx
	push format_number
	push dword[stderr]
	call fprintf
	add esp, 12

	popad
	mov esp, ebp
	pop ebp
	ret