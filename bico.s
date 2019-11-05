/**************************************************************** 
 * Description: Uoli Control Application Programming Interface.
 *
 * Authors: Edson Borin (edson@ic.unicamp.br)
 *          Antônio Guimarães ()
 *
 * Date: 2019
 ***************************************************************/


/**************************************************************/
/* List of Friends locations and dangerous locations          */
/**************************************************************/

friends_locations:
  .word   715                     # 0x2cb
  .word   105                     # 0x69
  .word   4294967256              # 0xffffffd8
  .word   613                     # 0x265
  .word   105                     # 0x69
  .word   4294967272              # 0xffffffe8
  .word   447                     # 0x1bf
  .word   106                     # 0x6a
  .word   158                     # 0x9e
  .word   507                     # 0x1fb
  .word   105                     # 0x69
  .word   264                     # 0x108
  .word   596                     # 0x254
  .word   105                     # 0x69
  .word   402                     # 0x192

dangerous_locations:
  .word   475                     # 0x1db
  .word   104                     # 0x68
  .word   193                     # 0xc1
  .word   526                     # 0x20e
  .word   105                     # 0x69
  .word   225                     # 0xe1
  .word   487                     # 0x1e7
  .word   105                     # 0x69
  .word   4294967286              # 0xfffffff6
  .word   685                     # 0x2ad
  .word   105                     # 0x69
  .word   4294967275              # 0xffffffeb
  .word   421                     # 0x1a5
  .word   105                     # 0x69
  .word   116                     # 0x74

# functions descriptions are in api_robot.h

/**************************************************************/
/* Engines                                                    */
/**************************************************************/

# args -> a0: Valor do torque para a engrenagem 1, a1: Valor do torque para a engrenagem 2
# return -> -1 in case one or more values are out of range / 0 in case both values are in range (the return is in the a0)
.globl set_torque
set_torque:
  addi sp, sp, -12 # create stack
  sw ra, 8(sp)
  sw a0, 4(sp) # store a0 value
  sw a1, 0(sp) # store a1 value
  li a0, 0
  lw a1, 4(sp)
  jal set_engine_torque # call set_engine_torque with a0 value
  li a0, 1
  lw a1, 0(sp)
  jal set_engine_torque # call set_engine_torque with a1 value inside a0
  lw a1, 0(sp) # pop a1 from stack
  lw a0, 4(sp) # pop a0 from stack
  lw ra, 8(sp)
  addi sp, sp, 12
  ret

# args -> a0: Valor do ID da engrenagem, a1: Valor do torque da engrenagem
# return -> -1 in case the torque value is invalid (out of range) / -2 in case the engine_id is invalid / 0 in case both values are valid (the return is in the a0)
.globl set_engine_torque
set_engine_torque:
  li a7, 18
  ecall
  
  ret

# args -> a0: Valor do Servo ID , a1: Valor do ângulo do Servo 
# return -> -1 in case the servo id is invalid / -2 in case the servo angle is invalid / 0 in case the servo id and the angle is valid (the return is in the a0)
.globl set_head_servo
set_head_servo:
  li a7, 17
  ecall

  ret

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar as coordenadas (x, y, z);
# return -> void (the return is in the a0)
.globl get_current_GPS_position
get_current_GPS_position:
  li a7, 19
  ecall

  ret

# args -> a0: Endereço do registro (com três valores inteiros) para armazenar os ângulos de Euler (x, y, z);
# return -> void (the return is in the a0)	
.globl get_gyro_angles
get_gyro_angles:
  li a7, 20
  ecall

  ret

# args -> none
# return -> a0: tempo do sistema em milisegundos;
.globl get_time
get_time:
  li a7, 21
  ecall

  ret

# args -> a0: tempo do sistema, em milisegundos;
# return -> void;
.globl set_time
set_time:
  li a7, 22
  ecall

  ret

# args -> a0: Descritor do arquivo, a1: Endereço de memória do buffer a ser escrito, a2: Número de bytes a serem escritos;
# return -> a0: Número de bytes efetivamente escritos;
.globl puts
puts:
  li a7, 64
  ecall

  ret