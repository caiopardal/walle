.globl _start

# description: machine boot/reboot
_start:
	# Configura o tratador de interrupções
	la t0, int_handler # Grava o endereço do rótulo int_handler
	csrw mtvec, t0 # no registrador mtvec
	
	# Habilita Interrupções Global
	csrr t1, mstatus # Seta o bit 7 (MPIE)
	ori t1, t1, 0x80 # do registrador mstatus
	csrw mstatus, t1
	
	# Habilita Interrupções Externas
	csrr t1, mie # Seta o bit 11 (MEIE)
	li t2, 0x800 # do registrador mie
	or t1, t1, t2
	csrw mie, t1
	
	# Ajusta o mscratch
	la t1, machine_stack # Coloca o endereço do buffer para salvar
	csrw mscratch, t1 # registradores em mscratch
	
	# Muda para o Modo de usuário
	csrr t1, mstatus # Seta os bits 11 e 12 (MPP)
	li t2, ~0x1800 # do registrador mstatus
	and t1, t1, t2 # com o valor 00
	csrw mstatus, t1

	la t0, boot # Grava o endereço do rótulo user
	csrw mepc, t0 # no registrador mepc
	mret # PC <= MEPC; MIE <= MPIE; Muda modo para MPP
	
# description: execute user code, "main" in LoCo
boot:
  call main

# description: interruption handler
int_handler:
  # store context
  csrrw a0, mscratch, a0
  sw a1, 0(a0)
  sw a2, 4(a0) 
  sw a3, 8(a0) 
  sw a4, 12(a0) 
  sw a5, 16(a0)
  sw a6, 20(a0)
  sw a7, 24(a0)
  sw fp, 28(a0) 
  sw s1, 32(a0)
  sw s2, 36(a0)
  sw s3, 40(a0)
  sw s4, 44(a0)
  sw s5, 48(a0)
  sw s6, 52(a0)
  sw s7, 56(a0)
  sw s8, 60(a0)
  sw s9, 64(a0)
  sw s10, 68(a0)
  sw s11, 72(a0)
  sw t0, 76(a0)
  sw t1, 80(a0)
  sw t2, 84(a0)
  sw t3, 88(a0)
  sw t4, 92(a0)
  sw t5, 96(a0)
  sw t6, 100(a0)
  sw tp, 104(a0) 
  sw gp, 108(a0)
  sw sp, 112(a0)
  sw ra, 116(a0)
  csrrw a0, mscratch, a0
  
  # decode the interruption cause
  csrr a1, mcause # lê a causa da exceção
  bgez a1, exception # desvia se não for uma interrupção
  
  andi a1, a1, 0x3f # isola a causa de interrupção
  li a2, 7 # a2 = interrupção do timer
  bne a1, a2, int_handler_restore_context # desvia se não for interrupção do temporizador da máquina
  # TODO: configurar o GPT aqui

  int_handler_exception: 
    # TODO: implementar o tratamento das SysCallss
    j int_handler_restore_context

  int_handler_restore_context:
    csrrw a0, mscratch, a0
    lw a1, 0(a0)
    lw a2, 4(a0) 
    lw a3, 8(a0) 
    lw a4, 12(a0) 
    lw a5, 16(a0)
    lw a6, 20(a0)
    lw a7, 24(a0)
    lw fp, 28(a0) 
    lw s1, 32(a0)
    lw s2, 36(a0)
    lw s3, 40(a0)
    lw s4, 44(a0)
    lw s5, 48(a0)
    lw s6, 52(a0)
    lw s7, 56(a0)
    lw s8, 60(a0)
    lw s9, 64(a0)
    lw s10, 68(a0)
    lw s11, 72(a0)
    lw t0, 76(a0)
    lw t1, 80(a0)
    lw t2, 84(a0)
    lw t3, 88(a0)
    lw t4, 92(a0)
    lw t5, 96(a0)
    lw t6, 100(a0)
    lw tp, 104(a0) 
    lw gp, 108(a0)
    lw sp, 112(a0)
    lw ra, 116(a0)
    csrrw a0, mscratch, a0

    mret 

machine_stack:
