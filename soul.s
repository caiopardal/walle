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

  # activating the GPT
  la t1, peripheral_gpt_1
  lw t1, 0(t1)
  lw t1, 0(t1)
  li t2, 1 # interrupt every 1 milisseconds
  sw t2, 0(t1) 

  # initializing timer with 0
  la t1, machine_time
  li t2, 0
  sw t2, 0(t1) 

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
  bgez a1, int_handler_exception # desvia se não for uma interrupção
  
  andi a1, a1, 0x3f # isola a causa de interrupção
  li a2, 7 # a2 = interrupção do timer
  bne a1, a2, int_handler_restore_context # desvia se não for interrupção do temporizador da máquina
  
  # handling the GPT interruption, incrementing the clock
  la t1, machine_stack
  lw t2, 0(t1)
  addi t2, t2, 1
  sw t2, 0(t1)
 
  # flagging that the GPT interruption has already been handled
  la t1, peripheral_gpt_2
  lw t1, 0(t1)
  li t2, 0 # interruption flag bit, set "false"
  sb t2, 0(t1) 
  
  # activating the GPT
  la t1, peripheral_gpt_1
  lw t1, 0(t1)
  li t2, 1 # interrupt every 1 milisseconds
  sw t2, 0(t1) 
  j int_handler_restore_context

  int_handler_exception: 
    # "switch case" until found the syscall code requested
    li t1, 17
    beq t1, a7, syscall_set_head_servo

    li t1, 18
    beq t1, a7, syscall_set_engine_torque

    li t1, 19
    beq t1, a7, syscall_read_gps

    li t1, 21
    beq t1, a7, syscall_get_time

    # not a syscall, return anyway
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

########### Syscalls implementation ###########

# args -> none
# return -> a0: tempo do sistema em milisegundos;
syscall_get_time:
  la t1, machine_time
  lw t1, 0(t1)
  mv a0, t1

  j int_handler_restore_context

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar as coordenadas (x, y, z);
# return -> void (the return is in the a0)
syscall_read_gps:
  # starting the position calculation in the peripheral
  la t1, peripheral_gps_status
  lw t1, 0(t1)
  li t2, 0
  sw t2, 0(t1)

  # loop until the peripheral_gps finish the calcucation of the current position 
  syscall_read_gps_status_loop:
    li t2, 1
    la t1, peripheral_gps_status
    lw t1, 0(t1)
    lw t1, 0(t1)
    bne t1, t2, syscall_read_gps_status_loop

  # grabs the x position
  la t1, peripheral_gps_x
  lw t1, 0(t1) # the reason that I `lw` two times is because 'peripheral_gps_x' stores the address of the peripheral, not the peripheral itself
  lw t1, 0(t1)
  sw t1, 0(a0)

  # grabs the y position
  la t1, peripheral_gps_y
  lw t1, 0(t1)
  lw t1, 0(t1)
  sw t1, 4(a0)

  # grabs the z position
  la t1, peripheral_gps_z
  lw t1, 0(t1)
  lw t1, 0(t1)
  sw t1, 8(a0)

  j int_handler_restore_context

# args -> a0: Valor do torque para a engrenagem 1, a1: Valor do torque para a engrenagem 2
# return -> -1 in case one or more values are out of range / 0 in case both values are in range (the return is in the a0)
syscall_set_torque:
  addi sp, sp, -20
  sw ra, 16(sp)
  sw s0, 12(sp)
  addi s0, sp, 32 # Create stack using s0 that will be the aux stack for this function
  sw a0, -4(s0) # Store a0 variable into s0 stack
  sw a1, -8(s0) # Store a1 variable into s0 stack
  lw a0, -4(s0) 
  addi a1, zero, 100 # Add 100 to a1 to compare with a0
  blt a1, a0, syscall_set_torque_lessThanOneHundred1 # If a0's value is less than 100, branch to check if a1's value is lower too
  j syscall_set_torque_compareWithMinusOneHundred1 

  syscall_set_torque_compareWithMinusOneHundred1: 
    lw a0, -4(s0)
    addi a1, zero, -101    # Check if a0's value is less than -100
    blt a1, a0, syscall_set_torque_returnZero # If it's then return 0
    j syscall_set_torque_lessThanOneHundred

  syscall_set_torque_lessThanOneHundred1:
    lw a0, -8(s0)
    addi a1, zero, 100   # Check if a1's value is less than 100
    blt a1, a0, syscall_set_torque_returnMinusOne # If it's then return -1
    j syscall_set_torque_compareWithMinusOneHundred2 

  syscall_set_torque_compareWithMinusOneHundred2:
    lw a0, -8(s0)
    addi a1, zero, -101 
    blt a1, a0, syscall_set_torque_returnZero # Check if a1's value is less than -100
    j syscall_set_torque_returnMinusOne

  syscall_set_torque_returnMinusOne:
    addi a0, zero, -1 # Set -1 as function return parameter
    sw a0, 0(s0)
    j syscall_set_torque_returnSetTorque # Call return method for this function

  syscall_set_torque_returnZero:
    mv a0, zero # Set 0 as function return parameter
    sw a0, 0(s0)
    j syscall_set_torque_returnSetTorque # Call return method for this function

  syscall_set_torque_returnSetTorque:
    lw a0, 0(s0)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    
    j int_handler_restore_context

# args -> a0: Valor do Servo ID , a1: Valor do ângulo do Servo 
# return -> -1 in case the torque value is invalid (out of range) / -2 in case the engine_id is invalid / 0 in case both values are valid (the return is in the a0)
syscall_set_engine_torque:
  addi sp, sp, -20
  sw ra, 16(sp)
  sw s0, 12(sp)
  addi s0, sp, 20 # Create stack using s0 that will be the aux stack for this function
  sw a0, -4(s0) # Store a0 variable into s0 stack
  sw a1, -8(s0) # Store a1 variable into s0 stack
  lw a0, -8(s0)
  addi a1, zero, 100 # Add 100 to a1 to compare with a0
  blt a1, a0, syscall_set_engine_torque_lessThanOneHundred # If a0's value is less than 100, branch to check if a1's value is lower too
  j syscall_set_engine_torque_compareWithMinusOneHundred

  syscall_set_engine_torque_compareWithMinusOneHundred:
    lw a0, -8(s0)
    addi a1, zero, -101 # Check if a0's value is less than -100
    blt a1, a0, syscall_set_engine_torque_lessThanMinusOneHundred # If it's than return -1
    j syscall_set_engine_torque_lessThanOneHundred

  syscall_set_engine_torque_lessThanOneHundred:
    addi a0, zero, -1
    sw a0, 0(s0)
    j syscall_set_engine_torque_returnSetEngineTorque # Call return method for this function

  syscall_set_engine_torque_lessThanMinusOneHundred:
    lw a0, -4(s0)
    addi a1, zero, 1 # Check if engine_id is 1
    bne a0, a1, syscall_set_engine_torque_notEqualToOne # If it's not equal to one, return -2
    j syscall_set_engine_torque_equalsZero

  syscall_set_engine_torque_equalsZero:
    lw a0, -4(s0)
    mv a1, zero
    beq a0, a1, syscall_set_engine_torque_returnFromEqualsZero # If it's equal to zero, return 0
    j syscall_set_engine_torque_notEqualToOne

  syscall_set_engine_torque_notEqualToOne:
    addi a0, zero, -2 # Set -2 as function return parameter
    sw a0, 0(s0)
    j syscall_set_engine_torque_returnSetEngineTorque # Call return method for this function

  syscall_set_engine_torque_returnFromEqualsZero:
    mv a0, zero # Set 0 as function return parameter
    sw a0, 0(s0)
    j syscall_set_engine_torque_returnSetEngineTorque # Call return method for this function

  syscall_set_engine_torque_returnSetEngineTorque:
    lw a0, 0(s0)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    
    j int_handler_restore_context

# args -> a0: Valor do Servo ID , a1: Valor do ângulo do Servo 
# return -> -1 in case the servo id is invalid / -2 in case the servo angle is invalid / 0 in case the servo id and the angle is valid (the return is in the a0)
syscall_set_head_servo:
  addi sp, sp, -20 
  sw ra, 16(sp) # Add ra into stack
  sw s0, 12(sp) # Create stack using s0 that will be the aux stack for this function
  addi s0, sp, 20
  sw a0, -4(s0)
  sw a1, -8(s0)
  lw a0, -4(s0)
  mv a1, zero
  beq a0, a1, syscall_set_head_servo_validServoId0 # Check if servo_id is 0
  j syscall_set_head_servo_checkIfServoIs1

  syscall_set_head_servo_checkIfServoIs1:
    lw a0, -4(s0)
    addi a1, zero, 1
    beq a0, a1, syscall_set_head_servo_validServoId0 # If it's then check angle's limit
    j syscall_set_head_servo_checkIfServoIs2

  syscall_set_head_servo_checkIfServoIs2:
    lw a0, -4(s0)
    addi a1, zero, 2 # Check if servo_id is 2
    bne a0, a1, syscall_set_head_servo_notValidServoId # If it's not 0, 1 or 2 then return -1
    j syscall_set_head_servo_validServoId0

  syscall_set_head_servo_validServoId0:
    lw a0, -4(s0)
    mv a1, zero
    bne a0, a1, syscall_set_head_servo_checkIfItIsServoId1 # Check if servo_id is 1
    j syscall_set_head_servo_checkGreaterLimitForBase

  syscall_set_head_servo_checkGreaterLimitForBase:
    lw a0, -8(s0)
    addi a1, zero, 116 # Check greater limit for Base
    blt a1, a0, syscall_set_head_servo_notValidAngleForBase # If it's not validAngle, return -2
    j syscall_set_head_servo_checkLowerLimitForBase

  syscall_set_head_servo_checkLowerLimitForBase:
    lw a0, -8(s0)
    addi a1, zero, 15 # Check lower limit for Base
    blt a1, a0, syscall_set_head_servo_validAngleForBase # If it's a validAngle, return 0
    j syscall_set_head_servo_notValidAngleForBase

  syscall_set_head_servo_notValidAngleForBase:
    addi a0, zero, -2 # Set -2 as function return parameter
    sw a0, 0(s0)
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_validAngleForBase:
    j syscall_set_head_servo_setZeroForReturn # Call method to set 0 as function return parameter

  syscall_set_head_servo_checkIfItIsServoId1:
    lw a0, -4(s0)
    addi a1, zero, 1
    bne a0, a1, syscall_set_head_servo_checkIfItIsServoId2
    j syscall_set_head_servo_checkGreaterLimitForMid

  syscall_set_head_servo_checkGreaterLimitForMid:
    lw a0, -8(s0)
    addi a1, zero, 90 # Check greater limit for Mid
    blt a1, a0, syscall_set_head_servo_notValidAngleForMid
    j syscall_set_head_servo_checkLowerLimitForMid
    
  syscall_set_head_servo_checkLowerLimitForMid:
    lw a0, -8(s0)
    addi a1, zero, 51 # Check lower limit for Mid
    blt a1, a0, syscall_set_head_servo_validAngleForTop # If it's a validAngle, return 0
    j syscall_set_head_servo_notValidAngleForMid

  syscall_set_head_servo_notValidAngleForMid:
    addi a0, zero, -2  # Set -2 as function return parameter
    sw a0, 0(s0)
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_validAngleForMid:
    j syscall_set_head_servo_setZeroForReturn # Call method to set 0 as function return parameter

  syscall_set_head_servo_checkIfItIsServoId2:
    lw a0, -4(s0)
    addi a1, zero, 2
    bne a0, a1, syscall_set_head_servo_notValidAngleForTop # If it's not validAngle, return -2
    j syscall_set_head_servo_checkGreaterLimitForMid

  syscall_set_head_servo_checkGreaterLimitForMid:
    lw a0, -8(s0)
    addi a1, zero, 156 # Check greater limit for Top
    blt a1, a0, syscall_set_head_servo_notValidAngleForTop # If it's not validAngle, return -2
    j syscall_set_head_servo_checkLowerLimitForTop

  syscall_set_head_servo_checkLowerLimitForTop:
    lw a0, -8(s0)
    addi a1, zero, -1 # Check lower limit for Top
    blt a1, a0, syscall_set_head_servo_validAngleForTop # If it's a validAngle, return 0
    j syscall_set_head_servo_notValidAngleForTop

  syscall_set_head_servo_notValidAngleForTop:
    addi a0, zero, -2 # Set -2 as function return parameter
    sw a0, 0(s0)
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_validAngleForTop:
    j syscall_set_head_servo_setZeroForReturn # Call method to set 0 as function return parameter

  syscall_set_head_servo_setZeroForReturn:
    mv a0, zero
    sw a0, 0(s0)
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_notValidServoId:
    addi a0, zero, -1
    sw a0, 0(s0)
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_returnSetHeadServo:
    lw a0, 0(s0)
    lw s0, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    
    j int_handler_restore_context

.data
peripheral_gps_status: .word 0xFFFF0004
peripheral_gps_x: .word 0xFFFF0008
peripheral_gps_y: .word 0xFFFF000C
peripheral_gps_z: .word 0xFFFF0010
peripheral_gpt_1: .word 0xFFFF0100 # GPT register responsible for interrupting every "x" milisseconds, size: word
peripheral_gpt_2: .word 0xFFFF0104 # GPT register that flags if the interruption is already resolved, size: byte
machine_time: .skip 4
machine_stack:
