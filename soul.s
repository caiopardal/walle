.globl _start

.equ peripheral_gps_status, 0xFFFF0004
.equ peripheral_gps_x, 0xFFFF0008
.equ peripheral_gps_y, 0xFFFF000C
.equ peripheral_gps_z, 0xFFFF0010
.equ peripheral_gyro_xyz, 0xFFFF0014
.equ peripheral_gpt_1, 0xFFFF0100 # GPT register responsible for interrupting every "x" milisseconds, size: word
.equ peripheral_gpt_2, 0xFFFF0104 # GPT register that flags if the interruption is already resolved, size: byte
.equ peripheral_torque_motor_1, 0xFFFF001A # writing in this register sets the Uoli motor 1 torque to Nm (Newton meters), size: half
.equ peripheral_torque_motor_2, 0xFFFF0018 # writing in this register sets the Uoli motor 2 torque to N m (Newton meters), size: half
.equ peripheral_servo_base, 0xFFFF001E # writing in this register sets the servo motor angle 1 (base) in degrees value, size: byte
.equ peripheral_servo_mid, 0xFFFF001D # writing in this register sets the servo motor angle 2 (mid) in degrees value, size: byte
.equ peripheral_servo_top, 0xFFFF001C # writing in this register sets the servo motor angle 3 (top) in degrees value, size: byte
.equ peripheral_ultrasonic_status, 0xFFFF0020
.equ peripheral_ultrasonic_value, 0xFFFF0024
.equ peripheral_transmission_from_uart, 0xFFFF0108 # When assigned a value of 1, UART begins transmitting the value stored at 0xFFFF0109
.equ peripheral_transmission_value_from_uart, 0xFFFF0109 # Value to be transmitted by UART
.equ peripheral_reception_value_from_uart, 0xFFFF010A # When assigned a value of 1, UART starts receiving a byte on input and stores it at 0xFFFF010B
.equ peripheral_reception_value_from_uart, 0xFFFF010B	# Value received by UART.

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

  # initializing user stack
  li sp, 0x7fffffc

	la t0, boot # Grava o endereço do rótulo user
	csrw mepc, t0 # no registrador mepc
	mret # PC <= MEPC; MIE <= MPIE; Muda modo para MPP
	
# description: execute user code, "main" in LoCo
boot:
  call main
  boot_exit:
    j boot_exit

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
  csrr t1, mcause # lê a causa da exceção
  bgez t1, int_handler_exception # desvia se não for uma interrupção
  
  andi t1, t1, 0x3f # isola a causa de interrupção
  li t2, 11 # t2 = interrupção do timer
  bne t1, t2, int_handler_restore_context # desvia se não for interrupção do temporizador da máquina
  
  int_handler_clock:  
    # flagging that the GPT interruption has already been handled
    li t1, peripheral_gpt_2
    lw t3, 0(t1)
    li t4, 0
    beq t3, t4, int_handler_restore_context # check if is a delay input problem 
    
    li t2, 0 # interruption flag bit, set "false"
    sb t2, 0(t1) 

    # handling the GPT interruption, incrementing the clock
    la t1, machine_time
    lw t2, 0(t1)
    addi t2, t2, 100
    sw t2, 0(t1)
    
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

    li t1, 64
    beq t1, a7, syscall_puts

    # not a syscall, return anyway
    j int_handler_restore_context

  # when it's a syscall called with ecall
  int_handler_increment_return_adress:
    # Ajustando MEPC para retornar de uma chamada de sistema
    csrr a1, mepc # carrega endereço de retorno
    # (endereço da instrução que invocou a syscall)
    addi a1, a1, 4 # soma 4 no endereço de retorno
    # (para retornar após a ecall)
    csrw mepc, a1 # armazena endereço de retorno de volta no mepc
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

  j int_handler_increment_return_adress

# args -> a0: tempo do sistema, em milisegundos 
# return -> none
syscall_set_time:
  la t1, machine_time
  sw a0, 0(t1)

  j int_handler_increment_return_adress

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

  j int_handler_increment_return_adress

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
  lw t1, 0(t1)
  mv t2, t1
  mv t3, t1
  srli t1, t1, 20
  mv t4, a0
  sw t1, 0(t4)

  # grabs the y angle
  slli t2, t2, 12 
	srli t2, t2, 22
  sw t2, 4(t4)

  # grabs the z angle
  slli t3, t3, 22
	srli t3, t3, 22
  sw t3, 8(t4)

  j int_handler_increment_return_adress

# args -> a0: Valor do ID da engrenagem, a1: Valor do torque da engrenagem
# return -> -1 in case the torque value is invalid (out of range) / -2 in case the engine_id is invalid / 0 in case both values are valid (the return is in the a0)
syscall_set_engine_torque:
  li t0, -100 
  blt a1, t0, syscall_set_engine_torque_invalid_value # if torque's value is less than -100
  li t0, 100
  bgt a1, t0, syscall_set_engine_torque_invalid_value # if torque's value is greater than 100

  syscall_set_engine_torque_valid_torque_value:
    beq a0, zero, syscall_set_engine_torque_motor_1 # if a0's != 0, then the id is invalid
    li t1, 1
    beq a0, t1, syscall_set_engine_torque_motor_2 # if a0's != 1, then the id is invalid
    j syscall_set_engine_torque_invalid_engineId

  syscall_set_engine_torque_motor_1:
    li t1, peripheral_torque_motor_1
    sw a1, 0(t1)
    li a0, 0
    j syscall_set_engine_torque_return

  syscall_set_engine_torque_motor_2:
    li t1, peripheral_torque_motor_2
    sw a1, 0(t1)
    li a0, 0
    j syscall_set_engine_torque_return

  syscall_set_engine_torque_invalid_value:
    li a0, -1
    j syscall_set_engine_torque_return
  syscall_set_engine_torque_invalid_engineId:
    li a0, -2
    j syscall_set_engine_torque_return

  syscall_set_engine_torque_return:
	  j int_handler_increment_return_adress

# args -> none
# return -> a0: distance of nearest object within the detection range, in centimeters.
syscall_get_us_distance:
  # starting the rotation calculation in the peripheral
  li t1, peripheral_ultrasonic_status
  li t2, 0
  sw t2, 0(t1)

  # loop until the peripheral_ultrasonic finishes reading the value returned by the ultrasound sensor in centimeters
  syscall_get_us_distance_loop:
    li t2, 1
    li t1, peripheral_ultrasonic_status
    lw t1, 0(t1)
    bne t1, t2, syscall_get_us_distance_loop
  
  # grabs the value returned by the ultrasound sensor in centimeters
  li t1, peripheral_ultrasonic_value
  lw t1, 0(t1) # the reason that I `lw` two times is because 'peripheral_ultrasonic_value' stores the address of the peripheral, not the peripheral itself
  sw t1, 0(a0)

  j int_handler_increment_return_adress

# args -> a0: Valor do Servo ID , a1: Valor do ângulo do Servo 
# return -> -1 in case the servo id is invalid / -2 in case the servo angle is invalid / 0 in case the servo id and the angle is valid (the return is in the a0)
syscall_set_head_servo:
  li t1, 0 # test for servo_id = 1
  beq a0, t1, syscall_set_head_servo_id_0
  li t1, 1 # test for servo_id = 2
  beq a0, t1, syscall_set_head_servo_id_1
  li t1, 2 # test for servo_id = 3
  beq a0, t1, syscall_set_head_servo_id_2
  li a0, -2 # invalid servo_id
  j syscall_set_head_servo_return

  syscall_set_head_servo_id_0:
    li t1, 16 # test for lower limit for angle when servo_id = 1
    blt a1, t1, syscall_set_head_servo_error
    li t1, 116 # test for greater limit for angle when servo_id = 1
    bgt a1, t1, syscall_set_head_servo_error
    li t2, peripheral_servo_base
    sb a1, 0(t2)
    li a0, 0 # valid values
    j syscall_set_head_servo_return

  syscall_set_head_servo_id_1:
    li t1, 52 # test for lower limit for angle when servo_id = 2
    blt a1, t1, syscall_set_head_servo_error
    li t1, 90 # test for greater limit for angle when servo_id = 2
    bgt a1, t1, syscall_set_head_servo_error
    li t2, peripheral_servo_mid
    sb a1, 0(t2)
    li a0, 0 # valid values
    j syscall_set_head_servo_return
    
  syscall_set_head_servo_id_2:
    li t1, 0 # test for lower limit for angle when servo_id = 3
    blt a1, t1, syscall_set_head_servo_error
    li t1, 156 # test for greater limit for angle when servo_id = 3
    bgt a1, t1, syscall_set_head_servo_error
    li t2, peripheral_servo_top
    sb a1, 0(t2)
    li a0, 0 # valid values
    j syscall_set_head_servo_return

  syscall_set_head_servo_error:
    li a0, -1 # invalid value for angle

  syscall_set_head_servo_return:
    j int_handler_increment_return_adress

# args -> a0: Descritor do arquivo, a1: Endereço de memória do buffer a ser escrito, a2: Número de bytes a serem escritos;
# return -> void (a0: Número de bytes efetivamente escritos ao final da função)
syscall_puts:
  syscall_puts_loop_for_printing:
    li t3, peripheral_transmission_value_from_uart ## read value to be transmitted
    lb t5, 0(a1) # read the byte to be printed
    sb t5, 0(t3)

    # starting the transmission of the string in the peripheral
    li t1, peripheral_transmission_from_uart # loading the macro
    li t2, 1
    sb t2, 0(t1)

    # loop until the peripheral_transmission_from_uart finish transmitting the next byte
    syscall_puts_loop_for_transmission:
      li t2, 1
      li t1, peripheral_transmission_from_uart
      lb t1, 0(t1)
      beq t1, t2, syscall_puts_loop_for_transmission

    addi a1, a1, 1 # advance to the next byte to be printed out
    lb t6, 0(a1)
    li t4, 0
    bne t4, t6, syscall_puts_loop_for_printing

  mv a0, a2 # move the number of actual bytes written to a0
  j int_handler_increment_return_adress

.data
machine_time: .skip 4
.comm machine_stack, 1000, 4
