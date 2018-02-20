;This object provides functions to test perfmon
;facilities to count io events.
;
;to assemble:
;	nasm -f elf64 funcs.asm
;
;To view assembly of nasm output:
;	objdump -M intel-mnemonic -d funcs.o

section .text
global _dxtestpm1

;this routine sets up and counts an off-core io event
;arg1(rdi = address of dword array to store return information)
;array fields:
;0 [$+0]    = 4 bytes, local APIC id
;1 [$+4]    = 4 bytes, previous IA32_PERFEVTSEL0:eax val
;2 [$+8]    = 4 bytes, previous IA32_PERFEVTSEL0:edx val
;3 [$+c]    = 4 bytes, previous MSR_OFFCORE_RSP_0:eax val
;4 [$+10]   = 4 bytes, previous MSR_OFFCORE_RSP_0:edx val
;5 [$+14]   = 4 bytes, 1st IA32_PMC0 sampled value
;6 [$+18]	 = 4 bytes, 2nd IA32_PMC0 sampled value
;7 [$+1c]	 = 4 bytes, i/o read val to make sure its no bogus
_dxtestpm1:
push rbx
push rcx
push rdx
push rsi
push rbp

;clear the pmc0 value
xor eax,eax
xor edx,edx
mov ecx,0xc1	;select IA32_PMC0
mov ebp,ecx		;IA32_PCM0 addr
wrmsr

;configure MSR_OFFCORE_RSP_0 (but save the previous value first)
mov ecx,0x1a6
rdmsr
mov dword[rdi+0xc],eax ;save prev MSR_OFFCORE_RSP_0:eax val
mov dword[rdi+0x10],edx ;save prev MSR_OFFCORE_RSP_0:edx val
xor edx,edx
mov eax,0x18000	;select IO request/response type
mov ecx,0x1a6
wrmsr

;configure PERFEVTSEL0 enabling the perfmon counter
mov ecx,0x186
rdmsr
mov dword[rdi+0x4],eax	;
mov dword[rdi+0x8],edx	;save previous IA32_PERFEVTSEL0:edx:eax val
xor edx,edx			;new settings for IA32_PERFEVTSEL0 upper bits
;mov eax,0x004201b7	;new settings for IA32_PERFEVTSEL0 lower bits
;mov eax,0x0042003c	;(this is just to count unhalted core cycles)
;mov eax,0x024202a3	;(this is to count memory load pending cycles)
mov eax,0x1c202b1	;(this is for counted cycles with no uops being executed)
mov ecx,0x186
mov esi,ecx			;save the selection of IA32_PERFEVTSEL0 so it won't get clobbered later
wrmsr

mov ecx,ebp
rdmsr
mov dword[rdi+0x14],eax	;IA32_PMC0 val 1st read

xor eax,eax
cpuid

;do the thing to sample right here.
;try to read i/o off the integrated ethernet controller:
mov rcx,0xffffc90006640038
mov eax,dword[rcx] ;read a register on the integrated ethernet controller.
;xor eax,eax
mov dword[rdi+0x1c],eax
xor eax,eax
cpuid

mov ecx,ebp
rdmsr
mov dword[rdi+0x18],eax ;IA32_PMC0 val 2nd read

;insert a serializing instruction
xor eax,eax
cpuid

;turn off perfmon counter
xor eax,eax
xor edx,edx
mov ecx,0x186
wrmsr

;clear MSR_OFFCORE_RSP_0
xor eax,eax
xor edx,edx
mov ecx,0x1a6
wrmsr

;get local APIC ID
mov eax,0x0b
cpuid
mov dword[rdi],edx	;save local APIC id in arg1 array

pop rbp
pop rsi
pop rdx
pop rcx
pop rbx
ret
