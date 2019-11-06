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
  li t1, peripheral_gpt_1
  li t2, 100 # interrupt every 100 milisseconds
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
  addi a0, a0, 120
  csrrw a0, mscratch, a0
  
  # decode the interruption cause
  csrr a1, mcause # lê a causa da exceção
  bgez a1, int_handler_exception # desvia se não for uma interrupção
  
  andi a1, a1, 0x3f # isola a causa de interrupção
  li a2, 7 # a2 = interrupção do timer
  bne a1, a2, int_handler_restore_context # desvia se não for interrupção do temporizador da máquina
  
  int_handler_clock:
    # handling the GPT interruption, incrementing the clock
    la t1, machine_time
    lw t2, 0(t1)
    addi t2, t2, 100
    sw t2, 0(t1)
  
    # flagging that the GPT interruption has already been handled
    li t1, peripheral_gpt_2
    lw t3, 0(t1)
    li t4, 0
    beq t3, t4, int_handler_restore_context # check if is a delay input problem 
    
    li t2, 0 # interruption flag bit, set "false"
    sb t2, 0(t1) 
    
    # activating the GPT
    li t1, peripheral_gpt_1
    li t2, 100 # interrupt every 100 milisseconds
    sw t2, 0(t1) 
    j int_handler_restore_context

  int_handler_exception: 
    # "switch case" until found the syscall code requested  
    li t1, 16
    beq t1, a7, syscall_get_us_distance

    li t1, 17
    beq t1, a7, syscall_set_head_servo

    li t1, 18
    beq t1, a7, syscall_set_engine_torque

    li t1, 19
    beq t1, a7, syscall_read_gps

    li t1, 20
    beq t1, a7, syscall_get_gyro_angles

    li t1, 21
    beq t1, a7, syscall_get_time

    li t1, 22
    beq t1, a7, syscall_set_time

    # not a syscall, return anyway
    j int_handler_restore_context

  int_handler_restore_context:
    csrrw a0, mscratch, a0
    lw ra, 0(a0)
    lw sp, 4(a0)
    lw gp, 8(a0)
    lw tp, 12(a0) 
    lw t6, 16(a0)
    lw t5, 20(a0)
    lw t4, 24(a0)
    lw t3, 28(a0)
    lw t2, 32(a0)
    lw t1, 36(a0)
    lw t0, 40(a0)
    lw s11, 44(a0)
    lw s10, 48(a0)
    lw s9, 52(a0)
    lw s8, 56(a0)
    lw s7, 60(a0)
    lw s6, 64(a0)
    lw s5, 68(a0)
    lw s4, 72(a0)
    lw s3, 76(a0)
    lw s2, 80(a0)
    lw s1, 84(a0)
    lw fp, 88(a0) 
    lw a7, 92(a0)
    lw a6, 96(a0)
    lw a5, 100(a0)
    lw a4, 104(a0) 
    lw a3, 108(a0) 
    lw a2, 112(a0) 
    lw a1, 116(a0)
    addi a0, a0, -120
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

# args -> a0: tempo do sistema, em milisegundos 
# return -> none
syscall_set_time:
  la t1, machine_time
  sw a0, 0(t1)

  j int_handler_restore_context

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar as coordenadas (x, y, z);
# return -> void (the return is in the a0)
syscall_read_gps:
  # starting the position calculation in the peripheral
  li t1, peripheral_gps_status # loading the macro
  li t2, 0
  sw t2, 0(t1)

  # loop until the peripheral_gps finish the calcucation of the current position 
  syscall_read_gps_status_loop:
    li t2, 1
    li t1, peripheral_gps_status
    lw t1, 0(t1)
    bne t1, t2, syscall_read_gps_status_loop

  # grabs the x position
  li t1, peripheral_gps_x
  lw t1, 0(t1) 
  sw t1, 0(a0)

  # grabs the y position
  li t1, peripheral_gps_y
  lw t1, 0(t1)
  sw t1, 4(a0)

  # grabs the z position
  li t1, peripheral_gps_z
  lw t1, 0(t1)
  sw t1, 8(a0)

  j int_handler_restore_context

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar os ângulos de Euler (x, y, z);
# return -> void
syscall_get_gyro_angles:
  # starting the rotation calculation in the peripheral
  li t1, peripheral_gps_status
  li t2, 0
  sw t2, 0(t1)

  # loop until the peripheral_gps finish the calcucation of the current position 
  syscall_get_gyro_angles_loop:
    li t2, 1
    li t1, peripheral_gps_status
    lw t1, 0(t1)
    bne t1, t2, syscall_get_gyro_angles_loop
  
  # grabs the x angle
  li t1, peripheral_gyro_xyz
  lw t1, 2(t1)
  mv t2, t1
  srli t0, t1, 20
  mv a1, t0
  sw a1, 2(a0)

  # grabs the y angle
  mv t1, t2
  slli t0, t1, 10
  srli t0, t0, 20
  mv a1, t0
  sw a1, 12(a0)

  # grabs the z angle
  mv t1, t2
  slli t0, t1, 10
  srli t0, t0, 20
  mv a1, t0
  sw a1, 22(a0)

  j int_handler_restore_context

# args -> a0: Valor do ID da engrenagem, a1: Valor do torque da engrenagem
# return -> -1 in case the torque value is invalid (out of range) / -2 in case the engine_id is invalid / 0 in case both values are valid (the return is in the a0)
syscall_set_engine_torque:
  mv t2, a1 # moving the torque value to t2
  addi t3, zero, 100 # Add 100 to a1 to compare with a0
  blt t3, t2, syscall_set_engine_torque_lessThanOneHundred # If a0's value is less than 100, branch to check if a1's value is lower too
  j syscall_set_engine_torque_compareWithMinusOneHundred

  syscall_set_engine_torque_compareWithMinusOneHundred:
    addi t3, zero, -101 # Check if a0's value is less than -100
    blt t3, t2, syscall_set_engine_torque_lessThanMinusOneHundred # If it's than return -1
    j syscall_set_engine_torque_lessThanOneHundred

  syscall_set_engine_torque_lessThanOneHundred:
    addi t3, zero, -1
    sw a0, t3
    j syscall_set_engine_torque_returnSetEngineTorque # Call return method for this function

  syscall_set_engine_torque_lessThanMinusOneHundred:
    addi t3, zero, 1 # Check if engine_id is 1
    bne a0, t3, syscall_set_engine_torque_notEqualToOne # If it's not equal to one, return -2
    j syscall_set_engine_torque_equalsZero

  syscall_set_engine_torque_equalsZero:
    mv t3, zero
    beq a0, t3, syscall_set_engine_torque_returnFromEqualsZero # If it's equal to zero, return 0
    j syscall_set_engine_torque_notEqualToOne

  syscall_set_engine_torque_notEqualToOne:
    addi t3, zero, -2 # Set -2 as function return parameter
    sw a0, t3
    j syscall_set_engine_torque_returnSetEngineTorque # Call return method for this function

  syscall_set_engine_torque_returnFromEqualsZero:
    mv t3, zero # Set 0 as function return parameter
    sw a0, t3
    j syscall_set_engine_torque_returnSetEngineTorque # Call return method for this function

  syscall_set_engine_torque_returnSetEngineTorque:
    j int_handler_restore_context

# args -> none
# return -> a0: distance of nearest object within the detection range, in centimeters.
syscall_get_us_distance:
  # starting the rotation calculation in the peripheral
  li t1, peripheral_ultrasonic_status
  li t2, 0
  sw t2, 0(t1)

  # loop until the peripheral_ultrasonic finishes reading the value returned by the ultrasound sensor in centimeters
  syscall_get_us_distance:
    li t2, 1
    li t1, peripheral_gps_status
    lw t1, 0(t1)
    bne t1, t2, syscall_get_us_distance_loop
  
  # grabs the value returned by the ultrasound sensor in centimeters
  li t1, peripheral_ultrasonic_value
  lw t1, 0(t1) # the reason that I `lw` two times is because 'peripheral_ultrasonic_value' stores the address of the peripheral, not the peripheral itself
  sw t1, 0(a0)

  j int_handler_restore_context

# args -> a0: Valor do Servo ID , a1: Valor do ângulo do Servo 
# return -> -1 in case the servo id is invalid / -2 in case the servo angle is invalid / 0 in case the servo id and the angle is valid (the return is in the a0)
syscall_set_head_servo:
  mv t3, zero
  beq a0, t3, syscall_set_head_servo_validServoId0 # Check if servo_id is 0
  j syscall_set_head_servo_checkIfServoIs1

  syscall_set_head_servo_checkIfServoIs1:
    addi t3, zero, 1
    beq a0, t3, syscall_set_head_servo_validServoId0 # If it's then check angle's limit
    j syscall_set_head_servo_checkIfServoIs2

  syscall_set_head_servo_checkIfServoIs2:
    addi t3, zero, 2 # Check if servo_id is 2
    bne a0, t3, syscall_set_head_servo_notValidServoId # If it's not 0, 1 or 2 then return -1
    j syscall_set_head_servo_validServoId0

  syscall_set_head_servo_validServoId0:
    mv t3, zero
    bne a0, t3, syscall_set_head_servo_checkIfItIsServoId1 # Check if servo_id is 1
    j syscall_set_head_servo_checkGreaterLimitForBase

  syscall_set_head_servo_checkGreaterLimitForBase:
    addi t3, zero, 116 # Check greater limit for Base
    blt t3, a1, syscall_set_head_servo_notValidAngleForBase # If it's not validAngle, return -2
    j syscall_set_head_servo_checkLowerLimitForBase

  syscall_set_head_servo_checkLowerLimitForBas
    addi t3, zero, 15 # Check lower limit for Base
    blt t3, a1, syscall_set_head_servo_validAngleForBase # If it's a validAngle, return 0
    j syscall_set_head_servo_notValidAngleForBase

  syscall_set_head_servo_notValidAngleForBase:
    addi t3, zero, -2 # Set -2 as function return parameter
    sw a0, t3
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_validAngleForBase:
    j syscall_set_head_servo_setZeroForReturn # Call method to set 0 as function return parameter

  syscall_set_head_servo_checkIfItIsServoId1:
    addi t3, zero, 1
    bne a0, t3, syscall_set_head_servo_checkIfItIsServoId2
    j syscall_set_head_servo_checkGreaterLimitForMid

  syscall_set_head_servo_checkGreaterLimitForMid:
    addi t3, zero, 90 # Check greater limit for Mid
    blt t3, a1, syscall_set_head_servo_notValidAngleForMid
    j syscall_set_head_servo_checkLowerLimitForMid

  syscall_set_head_servo_checkLowerLimitForMid:
    addi t3, zero, 51 # Check lower limit for Mid
    blt t3, a1, syscall_set_head_servo_validAngleForTop # If it's a validAngle, return 0
    j syscall_set_head_servo_notValidAngleForMid

  syscall_set_head_servo_notValidAngleForMid:
    addi t3, zero, -2  # Set -2 as function return parameter
    sw a0, t3
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_validAngleForMid:
    j syscall_set_head_servo_setZeroForReturn # Call method to set 0 as function return parameter

  syscall_set_head_servo_checkIfItIsServoId2:
    addi t3, zero, 2
    bne a0, t3, syscall_set_head_servo_notValidAngleForTop # If it's not validAngle, return -2
    j syscall_set_head_servo_checkGreaterLimitForMid

  syscall_set_head_servo_checkGreaterLimitForMid:
    addi t3, zero, 156 # Check greater limit for Top
    blt t3, a1, syscall_set_head_servo_notValidAngleForTop # If it's not validAngle, return -2
    j syscall_set_head_servo_checkLowerLimitForTop

  syscall_set_head_servo_checkLowerLimitForTop:
    addi t3, zero, -1 # Check lower limit for Top
    blt t3, a1, syscall_set_head_servo_validAngleForTop # If it's a validAngle, return 0
    j syscall_set_head_servo_notValidAngleForTop

  syscall_set_head_servo_notValidAngleForTop:
    addi t3, zero, -2 # Set -2 as function return parameter
    sw a0, t3
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_validAngleForTop:
    j syscall_set_head_servo_setZeroForReturn # Call method to set 0 as function return parameter

  syscall_set_head_servo_setZeroForReturn:
    mv t3, zero
    sw a0, t3)
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_notValidServoId:
    addi t3, zero, -1
    sw a0, t3
    j syscall_set_head_servo_returnSetHeadServo # Call return method for this function

  syscall_set_head_servo_returnSetHeadServo:
    j int_handler_restore_context

.data
.equ peripheral_gps_status, 0xFFFF0004
.equ peripheral_gps_x, 0xFFFF0008
.equ peripheral_gps_y, 0xFFFF000C
.equ peripheral_gps_z, 0xFFFF0010
.equ peripheral_gyro_xyz, 0xFFFF0014
.equ peripheral_gpt_1, 0xFFFF0100 # GPT register responsible for interrupting every "x" milisseconds, size: word
.equ peripheral_gpt_2, 0xFFFF0100 # GPT register that flags if the interruption is already resolved, size: byte
.equ peripheral_torque_motor_1, 0xFFFF001A # writing in this register sets the Uoli motor 1 torque to Nm (Newton meters), size: half
.equ peripheral_torque_motor2, 0xFFFF0018 # writing in this register sets the Uoli motor 2 torque to N m (Newton meters), size: half
.equ peripheral_servo_base, 0xFFFF001C # writing in this register sets the servo motor angle 1 (base) in degrees value, size: byte
.equ peripheral_servo_mid, 0xFFFF001D # writing in this register sets the servo motor angle 2 (mid) in degrees value, size: byte
.equ peripheral_servo_top, 0xFFFF0104 # writing in this register sets the servo motor angle 3 (top) in degrees value, size: byte
.equ peripheral_ultrasonic_status, 0xFFFF0020
.equ peripheral_ultrasonic_value, 0xFFFF0024
machine_time: .skip 4
<<<<<<< HEAD
machine_stack: .comm 1000
=======
machine_stack:
>>>>>>> refactoring syscalls
